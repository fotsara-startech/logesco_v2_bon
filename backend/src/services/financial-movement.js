/**
 * Service pour la gestion des mouvements financiers
 * Gère les sorties d'argent de la boutique avec traçabilité complète
 */

class FinancialMovementService {
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Génère un numéro de référence unique pour un mouvement
   * Format: MF-YYYYMMDD-XXXX
   */
  generateReference() {
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
    const randomSuffix = Math.floor(Math.random() * 9999).toString().padStart(4, '0');
    return `MF-${dateStr}-${randomSuffix}`;
  }

  /**
   * Crée un nouveau mouvement financier
   * @param {Object} data - Données du mouvement
   * @returns {Promise<Object>} Mouvement créé
   */
  async createMovement(data) {
    try {
      // Validation des données requises
      if (!data.montant || data.montant <= 0) {
        throw new Error('Le montant doit être supérieur à 0');
      }

      if (!data.categorieId) {
        throw new Error('La catégorie est obligatoire');
      }

      if (!data.description || data.description.trim().length === 0) {
        throw new Error('La description est obligatoire');
      }

      if (!data.utilisateurId) {
        throw new Error('L\'utilisateur est obligatoire');
      }

      // Vérifier que la catégorie existe et est active
      const category = await this.prisma.movementCategory.findFirst({
        where: {
          id: data.categorieId,
          isActive: true
        }
      });

      if (!category) {
        throw new Error('Catégorie non trouvée ou inactive');
      }

      // Vérifier que l'utilisateur existe
      const user = await this.prisma.utilisateur.findUnique({
        where: { id: data.utilisateurId }
      });

      if (!user) {
        throw new Error('Utilisateur non trouvé');
      }

      // Générer une référence unique
      let reference;
      let attempts = 0;
      do {
        reference = this.generateReference();
        const existing = await this.prisma.financialMovement.findUnique({
          where: { reference }
        });
        if (!existing) break;
        attempts++;
      } while (attempts < 10);

      if (attempts >= 10) {
        throw new Error('Impossible de générer une référence unique');
      }

      // Créer le mouvement
      const movement = await this.prisma.financialMovement.create({
        data: {
          reference,
          montant: parseFloat(data.montant),
          categorieId: data.categorieId,
          description: data.description.trim(),
          date: data.date ? new Date(data.date) : new Date(),
          utilisateurId: data.utilisateurId,
          notes: data.notes?.trim() || null
        },
        include: {
          categorie: true,
          utilisateur: {
            select: {
              id: true,
              nomUtilisateur: true,
              email: true
            }
          },
          attachments: true
        }
      });

      console.log(`✅ Mouvement financier créé: ${movement.reference} - ${movement.montant}€`);
      
      // Impacter la caisse active de l'utilisateur
      const cashUpdate = await this.updateActiveCashRegister(movement.montant, movement.utilisateurId);
      
      // Ajouter le nouveau solde au résultat
      return {
        ...movement,
        nouveauSoldeCaisse: cashUpdate?.nouveauSolde
      };

    } catch (error) {
      console.error('❌ Erreur lors de la création du mouvement:', error.message);
      throw error;
    }
  }

  /**
   * Met à jour le solde de la caisse active lors d'une dépense
   * @param {number} montant - Montant de la dépense
   * @param {number} utilisateurId - ID de l'utilisateur
   */
  async updateActiveCashRegister(montant, utilisateurId) {
    try {
      // Trouver la session active de l'utilisateur
      const activeSession = await this.prisma.cashSession.findFirst({
        where: {
          utilisateurId: utilisateurId,
          dateFermeture: null,
          isActive: true
        },
        include: {
          caisse: true
        }
      });
      
      if (!activeSession) {
        throw new Error('Aucune session active trouvée - veuillez ouvrir une session de caisse');
      }
      
      // Calculer le nouveau solde attendu
      const currentSoldeAttendu = activeSession.soldeAttendu ? parseFloat(activeSession.soldeAttendu) : parseFloat(activeSession.soldeOuverture);
      const newSoldeAttendu = currentSoldeAttendu - parseFloat(montant);
      
      // AVERTISSEMENT: Si le solde devient négatif, on continue mais on avertit
      let warning = null;
      if (newSoldeAttendu < 0) {
        warning = `⚠️ ATTENTION: Solde insuffisant en caisse. Disponible: ${currentSoldeAttendu} FCFA, Dépense: ${montant} FCFA. Le solde sera négatif: ${newSoldeAttendu} FCFA`;
        console.log(warning);
      }
      
      // Mettre à jour le soldeAttendu de la session (même si négatif)
      await this.prisma.cashSession.update({
        where: { id: activeSession.id },
        data: {
          soldeAttendu: newSoldeAttendu
        }
      });
      
      console.log(`💰 Session de caisse mise à jour:`);
      console.log(`   Solde attendu avant: ${currentSoldeAttendu} FCFA`);
      console.log(`   Dépense: -${montant} FCFA`);
      console.log(`   Solde attendu après: ${newSoldeAttendu} FCFA`);
      
      // Créer un mouvement de caisse pour tracer la dépense
      await this.prisma.cashMovement.create({
        data: {
          caisseId: activeSession.caisseId,
          type: 'depense',
          montant: -parseFloat(montant), // Négatif car c'est une sortie
          description: 'Dépense enregistrée',
          utilisateurId: utilisateurId,
          dateCreation: new Date()
        }
      });
      
      // Mettre à jour le solde de la caisse (réduire, même si négatif)
      await this.prisma.cashRegister.update({
        where: { id: activeSession.caisseId },
        data: {
          soldeActuel: {
            decrement: parseFloat(montant)
          }
        }
      });
      
      console.log(`✅ Caisse ${activeSession.caisse.nom} mise à jour: -${montant} FCFA (solde réduit)`);
      
      return {
        success: true,
        nouveauSolde: newSoldeAttendu,
        warning: warning,
        isNegative: newSoldeAttendu < 0
      };
    } catch (error) {
      console.error('❌ Erreur mise à jour caisse active:', error.message);
      throw error; // Propager l'erreur pour que la création du mouvement échoue
    }
  }

  /**
   * Récupère les mouvements avec filtrage et pagination
   * @param {Object} options - Options de filtrage
   * @returns {Promise<Object>} Liste paginée des mouvements
   */
  async getMovements(options = {}) {
    try {
      const {
        page = 1,
        limit = 20,
        search,
        categorieId,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        utilisateurId
      } = options;

      // Construction des filtres
      const where = {};

      // Recherche textuelle
      if (search) {
        where.OR = [
          { reference: { contains: search } },
          { description: { contains: search } },
          { notes: { contains: search } }
        ];
      }

      // Filtre par catégorie
      if (categorieId) {
        where.categorieId = parseInt(categorieId);
      }

      // Filtre par utilisateur
      if (utilisateurId) {
        where.utilisateurId = parseInt(utilisateurId);
      }

      // Filtre par date
      if (startDate || endDate) {
        where.date = {};
        if (startDate) {
          where.date.gte = new Date(startDate);
        }
        if (endDate) {
          where.date.lte = new Date(endDate);
        }
      }

      // Filtre par montant
      if (minAmount || maxAmount) {
        where.montant = {};
        if (minAmount) {
          where.montant.gte = parseFloat(minAmount);
        }
        if (maxAmount) {
          where.montant.lte = parseFloat(maxAmount);
        }
      }

      // Calcul de la pagination
      const skip = (page - 1) * limit;

      // Exécution des requêtes en parallèle
      const [movements, total] = await Promise.all([
        this.prisma.financialMovement.findMany({
          where,
          include: {
            categorie: true,
            utilisateur: {
              select: {
                id: true,
                nomUtilisateur: true,
                email: true
              }
            },
            attachments: true
          },
          orderBy: { date: 'desc' },
          skip,
          take: limit
        }),
        this.prisma.financialMovement.count({ where })
      ]);

      return {
        movements,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
          hasNext: page < Math.ceil(total / limit),
          hasPrev: page > 1
        }
      };

    } catch (error) {
      console.error('❌ Erreur lors de la récupération des mouvements:', error.message);
      throw error;
    }
  }

  /**
   * Récupère un mouvement par son ID
   * @param {number} id - ID du mouvement
   * @returns {Promise<Object>} Mouvement trouvé
   */
  async getMovementById(id) {
    try {
      const movement = await this.prisma.financialMovement.findUnique({
        where: { id: parseInt(id) },
        include: {
          categorie: true,
          utilisateur: {
            select: {
              id: true,
              nomUtilisateur: true,
              email: true
            }
          },
          attachments: true
        }
      });

      if (!movement) {
        throw new Error('Mouvement non trouvé');
      }

      return movement;

    } catch (error) {
      console.error('❌ Erreur lors de la récupération du mouvement:', error.message);
      throw error;
    }
  }

  /**
   * Met à jour un mouvement financier
   * @param {number} id - ID du mouvement
   * @param {Object} data - Nouvelles données
   * @returns {Promise<Object>} Mouvement mis à jour
   */
  async updateMovement(id, data) {
    try {
      // Vérifier que le mouvement existe
      const existing = await this.getMovementById(id);

      // Validation des données si fournies
      if (data.montant !== undefined && data.montant <= 0) {
        throw new Error('Le montant doit être supérieur à 0');
      }

      if (data.categorieId) {
        const category = await this.prisma.movementCategory.findFirst({
          where: {
            id: data.categorieId,
            isActive: true
          }
        });

        if (!category) {
          throw new Error('Catégorie non trouvée ou inactive');
        }
      }

      // Préparer les données de mise à jour
      const updateData = {};
      
      if (data.montant !== undefined) {
        updateData.montant = parseFloat(data.montant);
      }
      
      if (data.categorieId) {
        updateData.categorieId = data.categorieId;
      }
      
      if (data.description !== undefined) {
        if (!data.description || data.description.trim().length === 0) {
          throw new Error('La description est obligatoire');
        }
        updateData.description = data.description.trim();
      }
      
      if (data.date !== undefined) {
        updateData.date = new Date(data.date);
      }
      
      if (data.notes !== undefined) {
        updateData.notes = data.notes?.trim() || null;
      }

      // Mettre à jour le mouvement
      const updated = await this.prisma.financialMovement.update({
        where: { id: parseInt(id) },
        data: updateData,
        include: {
          categorie: true,
          utilisateur: {
            select: {
              id: true,
              nomUtilisateur: true,
              email: true
            }
          },
          attachments: true
        }
      });

      console.log(`✅ Mouvement financier mis à jour: ${updated.reference}`);
      return updated;

    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour du mouvement:', error.message);
      throw error;
    }
  }

  /**
   * Supprime un mouvement financier
   * @param {number} id - ID du mouvement
   * @returns {Promise<boolean>} Succès de la suppression
   */
  async deleteMovement(id) {
    try {
      // Vérifier que le mouvement existe
      const existing = await this.getMovementById(id);

      // Supprimer le mouvement (les attachments seront supprimés en cascade)
      await this.prisma.financialMovement.delete({
        where: { id: parseInt(id) }
      });

      console.log(`✅ Mouvement financier supprimé: ${existing.reference}`);
      return true;

    } catch (error) {
      console.error('❌ Erreur lors de la suppression du mouvement:', error.message);
      throw error;
    }
  }

  /**
   * Calcule les statistiques des mouvements
   * @param {Object} options - Options de filtrage
   * @returns {Promise<Object>} Statistiques
   */
  async getStatistics(options = {}) {
    try {
      const { startDate, endDate, categorieId } = options;

      // Construction des filtres
      const where = {};

      if (categorieId) {
        where.categorieId = parseInt(categorieId);
      }

      if (startDate || endDate) {
        where.date = {};
        if (startDate) {
          where.date.gte = new Date(startDate);
        }
        if (endDate) {
          where.date.lte = new Date(endDate);
        }
      }

      // Statistiques générales
      const [totalMovements, totalAmount, avgAmount] = await Promise.all([
        this.prisma.financialMovement.count({ where }),
        this.prisma.financialMovement.aggregate({
          where,
          _sum: { montant: true }
        }),
        this.prisma.financialMovement.aggregate({
          where,
          _avg: { montant: true }
        })
      ]);

      // Statistiques par catégorie
      const categoryStats = await this.prisma.financialMovement.groupBy({
        by: ['categorieId'],
        where,
        _sum: { montant: true },
        _count: true
      });

      // Enrichir avec les noms des catégories
      const enrichedCategoryStats = await Promise.all(
        categoryStats.map(async (stat) => {
          const category = await this.prisma.movementCategory.findUnique({
            where: { id: stat.categorieId }
          });
          return {
            ...stat,
            categorie: category
          };
        })
      );

      // Helper pour gérer les valeurs nulles/NaN de manière sûre
      const safeNumber = (value, defaultValue = 0) => {
        if (value == null || value === undefined) return defaultValue;
        const num = Number(value);
        return isNaN(num) || !isFinite(num) ? defaultValue : num;
      };

      return {
        totalMovements: safeNumber(totalMovements),
        totalAmount: safeNumber(totalAmount._sum?.montant),
        averageAmount: safeNumber(avgAmount._avg?.montant),
        categoryBreakdown: enrichedCategoryStats.map(stat => ({
          ...stat,
          _sum: {
            ...stat._sum,
            montant: safeNumber(stat._sum?.montant)
          }
        }))
      };

    } catch (error) {
      console.error('❌ Erreur lors du calcul des statistiques:', error.message);
      throw error;
    }
  }
}

module.exports = FinancialMovementService;
/**
 * Service pour la gestion des mouvements financiers
 * Gère les sorties d'argent de la boutique avec traçabilité complète
 */

class FinancialMovementService {
  constructor(prisma, syncService = null) {
    this.prisma = prisma;
    this.syncService = syncService;
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

      // Récupérer la session active pour la boutique (pas nécessairement l'utilisateur)
      // Priorité 1: Session de l'utilisateur dans la boutique
      let sessionLookupWhere = {
        utilisateurId: data.utilisateurId,
        isActive: true,
        dateFermeture: null
      };
      if (data.boutiqueId) sessionLookupWhere.boutiqueId = parseInt(data.boutiqueId);

      let activeSession = await this.prisma.cashSession.findFirst({
        where: sessionLookupWhere
      });

      // Priorité 2: Si pas de session pour cet utilisateur, chercher n'importe quelle session active dans la boutique
      if (!activeSession && data.boutiqueId) {
        console.log('⚠️ Aucune session pour cet utilisateur, recherche d\'une session active dans la boutique...');
        activeSession = await this.prisma.cashSession.findFirst({
          where: {
            boutiqueId: parseInt(data.boutiqueId),
            isActive: true,
            dateFermeture: null
          },
          orderBy: { dateOuverture: 'desc' }
        });
      }

      // IMPORTANT: Définir sessionId APRÈS avoir trouvé la session
      const sessionId = activeSession ? activeSession.id : null;
      
      if (!activeSession) {
        console.log('⚠️ Aucune session active trouvée - le mouvement sera créé sans session');
        console.log(`   Critères: utilisateurId=${data.utilisateurId}, boutiqueId=${data.boutiqueId}, isActive=true`);
      } else {
        console.log(`✅ Session active trouvée: ID ${activeSession.id}`);
        console.log(`   sessionId qui sera utilisé: ${sessionId} (type: ${typeof sessionId})`);
      }

      // Créer le mouvement
      console.log(`🔍 Création du mouvement avec sessionId=${sessionId}`);
      const movement = await this.prisma.financialMovement.create({
        data: {
          reference,
          sessionId: sessionId,
          boutiqueId: data.boutiqueId || null,
          montant: parseFloat(data.montant),
          categorieId: data.categorieId,
          description: data.description.trim(),
          date: data.date ? new Date(data.date).toISOString() : new Date().toISOString(),
          utilisateurId: data.utilisateurId,
          notes: data.notes?.trim() || null
        },
        include: {
          categorie: true,
          boutique: true,
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

      console.log(`✅ Mouvement financier créé: ${movement.reference} - ${movement.montant}€ - boutiqueId: ${movement.boutiqueId}`);
      console.log(`🔍 VERIFICATION: sessionId dans l'objet retourné = ${movement.sessionId} (devrait être ${sessionId})`);
      
      // VERIFICATION IMMEDIATE: Relire depuis la BD pour confirmer
      const verif = await this.prisma.financialMovement.findUnique({
        where: { id: movement.id },
        select: { id: true, reference: true, sessionId: true }
      });
      console.log(`🔍 VERIFICATION BD: sessionId dans la BD = ${verif.sessionId} (devrait être ${sessionId})`);
      
      if (verif.sessionId !== sessionId) {
        console.error(`❌ ERREUR: sessionId n'a pas été enregistré! Attendu: ${sessionId}, Obtenu: ${verif.sessionId}`);
      }
      
      // Impacter la caisse active de l'utilisateur
      const cashUpdate = await this.updateActiveCashRegister(movement.montant, movement.utilisateurId, movement.boutiqueId);
      
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
   * @param {number|null} boutiqueId - ID de la boutique active
   */
  async updateActiveCashRegister(montant, utilisateurId, boutiqueId = null) {
    try {
      // Trouver la session active de l'utilisateur (filtrée par boutique si fournie)
      const sessionWhere = {
        utilisateurId: utilisateurId,
        dateFermeture: null,
        isActive: true
      };
      if (boutiqueId) sessionWhere.boutiqueId = parseInt(boutiqueId);

      const activeSession = await this.prisma.cashSession.findFirst({
        where: sessionWhere,
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
      
      // Enqueue la mise à jour de la session pour sync
      if (this.syncService) {
        const updatedSession = await this.prisma.cashSession.findUnique({
          where: { id: activeSession.id }
        });
        await this.syncService.enqueue('cash_sessions', 'UPDATE', updatedSession);
      }
      
      console.log(`💰 Session de caisse mise à jour:`);
      console.log(`   Solde attendu avant: ${currentSoldeAttendu} FCFA`);
      console.log(`   Dépense: -${montant} FCFA`);
      console.log(`   Solde attendu après: ${newSoldeAttendu} FCFA`);
      
      // Créer un mouvement de caisse pour tracer la dépense
      const cashMovement = await this.prisma.cashMovement.create({
        data: {
          caisseId: activeSession.caisseId,
          sessionId: activeSession.id,
          boutiqueId: boutiqueId ? parseInt(boutiqueId) : (activeSession.boutiqueId || null),
          type: 'depense',
          montant: -parseFloat(montant), // Négatif car c'est une sortie
          description: 'Dépense enregistrée',
          utilisateurId: utilisateurId,
          dateCreation: new Date()
        }
      });
      
      // Enqueue le mouvement de caisse pour sync
      if (this.syncService) {
        await this.syncService.enqueue('cash_movements', 'INSERT', cashMovement);
      }
      
      // Mettre à jour le solde de la caisse (réduire, même si négatif)
      await this.prisma.cashRegister.update({
        where: { id: activeSession.caisseId },
        data: {
          soldeActuel: {
            decrement: parseFloat(montant)
          }
        }
      });
      
      // Enqueue la mise à jour de la caisse pour sync
      if (this.syncService) {
        const updatedCashRegister = await this.prisma.cashRegister.findUnique({
          where: { id: activeSession.caisseId }
        });
        await this.syncService.enqueue('cash_registers', 'UPDATE', updatedCashRegister);
      }
      
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
        boutiqueId,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        utilisateurId,
        includeAnnules = false
      } = options;

      // Construction des filtres
      const where = {};

      // Un mouvement annulé est conservé pour la piste d'audit mais ne doit
      // plus apparaître dans les listes/rapports par défaut.
      if (!includeAnnules) {
        where.statut = { not: 'annule' };
      }

      // Filtre par boutique
      if (boutiqueId) {
        where.boutiqueId = parseInt(boutiqueId);
      }

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
            boutique: true,
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
          boutique: true,
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
  /**
   * Annule un mouvement financier par contre-passation.
   *
   * On ne supprime jamais un mouvement qui a touché la caisse : sa disparition
   * laisserait le solde attendu amputé sans aucune trace explicative, et
   * l'écart constaté à la clôture deviendrait injustifiable.
   *
   * La correction est imputée à la session OUVERTE au moment de l'annulation,
   * jamais à celle d'origine : une session clôturée a déjà été rapprochée et
   * validée, la modifier après coup reviendrait à falsifier un état arrêté.
   *
   * @param {number} id - ID du mouvement à annuler
   * @param {number} utilisateurId - Auteur de l'annulation
   */
  async cancelMovement(id, utilisateurId = null) {
    const mouvementId = parseInt(id);
    const existing = await this.getMovementById(mouvementId);

    if (existing.statut === 'annule') {
      const err = new Error('Ce mouvement est déjà annulé');
      err.code = 'DEJA_ANNULE';
      throw err;
    }

    const montant = parseFloat(existing.montant);
    const auteur = utilisateurId || existing.utilisateurId;
    const impacteLaCaisse = !!existing.sessionId && montant !== 0;

    // Session ouverte de la boutique concernée : c'est elle qui portera la correction
    let sessionCorrection = null;
    if (impacteLaCaisse) {
      const where = { isActive: true, dateFermeture: null };
      if (existing.boutiqueId) where.boutiqueId = existing.boutiqueId;
      sessionCorrection = await this.prisma.cashSession.findFirst({
        where, include: { caisse: true }, orderBy: { id: 'desc' }
      });

      if (!sessionCorrection) {
        const err = new Error(
          'Aucune caisse ouverte : ouvrez une session pour enregistrer la correction de ce mouvement'
        );
        err.code = 'AUCUNE_SESSION_OUVERTE';
        throw err;
      }
    }

    const resultat = await this.prisma.$transaction(async (tx) => {
      const mouvementAnnule = await tx.financialMovement.update({
        where: { id: mouvementId },
        data: {
          statut: 'annule',
          notes: [existing.notes, `Annulé le ${new Date().toLocaleString('fr-FR')}`]
            .filter(Boolean).join(' | '),
        }
      });

      if (!impacteLaCaisse) return { mouvementAnnule, contrePassation: null, session: null };

      // Contre-passation : montant inverse de la dépense d'origine
      const contrePassation = await tx.cashMovement.create({
        data: {
          caisseId: sessionCorrection.caisseId,
          sessionId: sessionCorrection.id,
          boutiqueId: sessionCorrection.boutiqueId || existing.boutiqueId || null,
          type: 'annulation_depense',
          montant: montant, // positif : l'argent revient en caisse
          description: `Annulation dépense ${existing.reference}`,
          utilisateurId: auteur,
          dateCreation: new Date(),
        }
      });

      const soldeCourant = sessionCorrection.soldeAttendu != null
        ? parseFloat(sessionCorrection.soldeAttendu)
        : parseFloat(sessionCorrection.soldeOuverture);

      const sessionMaj = await tx.cashSession.update({
        where: { id: sessionCorrection.id },
        data: { soldeAttendu: soldeCourant + montant }
      });

      const caisseMaj = await tx.cashRegister.update({
        where: { id: sessionCorrection.caisseId },
        data: { soldeActuel: { increment: montant } }
      });

      return { mouvementAnnule, contrePassation, session: sessionMaj, caisse: caisseMaj };
    });

    // Propagation vers le cloud (hors transaction : elle est déjà validée)
    if (this.syncService) {
      try {
        await this.syncService.enqueue('financial_movements', 'UPDATE', resultat.mouvementAnnule);
        if (resultat.contrePassation) {
          await this.syncService.enqueue('cash_movements', 'INSERT', resultat.contrePassation);
          await this.syncService.enqueue('cash_sessions', 'UPDATE', resultat.session);
          await this.syncService.enqueue('cash_registers', 'UPDATE', resultat.caisse);
        }
      } catch (e) {
        console.warn('⚠️  Sync annulation mouvement:', e.message);
      }
    }

    const memeSession = sessionCorrection && sessionCorrection.id === existing.sessionId;
    console.log(`✅ Mouvement ${existing.reference} annulé — ${montant} FCFA restitués` +
      (impacteLaCaisse ? ` à la session ${sessionCorrection.id}${memeSession ? '' : ' (session d\'origine clôturée)'}` : ' (aucun impact caisse)'));

    return {
      mouvement: resultat.mouvementAnnule,
      montantRestitue: impacteLaCaisse ? montant : 0,
      sessionCorrigee: sessionCorrection ? sessionCorrection.id : null,
      sessionOrigine: existing.sessionId || null,
      imputeSurSessionCourante: impacteLaCaisse && !memeSession,
    };
  }

  /**
   * @deprecated Conservé pour compatibilité : redirige vers cancelMovement().
   * La suppression pure laissait la caisse amputée sans trace.
   */
  async deleteMovement(id, utilisateurId = null) {
    return this.cancelMovement(id, utilisateurId);
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
      // Un mouvement annulé ne doit jamais gonfler ni fausser les totaux affichés
      const where = { statut: { not: 'annule' } };

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
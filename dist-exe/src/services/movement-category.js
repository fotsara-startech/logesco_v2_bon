/**
 * Service pour la gestion des catégories de mouvements financiers
 */

class MovementCategoryService {
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Récupère toutes les catégories actives
   * @returns {Promise<Array>} Liste des catégories
   */
  async getCategories() {
    try {
      const categories = await this.prisma.movementCategory.findMany({
        where: { isActive: true },
        orderBy: [
          { isDefault: 'desc' }, // Catégories par défaut en premier
          { displayName: 'asc' }
        ]
      });

      return categories;

    } catch (error) {
      console.error('❌ Erreur lors de la récupération des catégories:', error.message);
      throw error;
    }
  }

  /**
   * Récupère une catégorie par son ID
   * @param {number} id - ID de la catégorie
   * @returns {Promise<Object>} Catégorie trouvée
   */
  async getCategoryById(id) {
    try {
      const category = await this.prisma.movementCategory.findUnique({
        where: { id: parseInt(id) }
      });

      if (!category) {
        throw new Error('Catégorie non trouvée');
      }

      return category;

    } catch (error) {
      console.error('❌ Erreur lors de la récupération de la catégorie:', error.message);
      throw error;
    }
  }

  /**
   * Crée une nouvelle catégorie personnalisée
   * @param {Object} data - Données de la catégorie
   * @returns {Promise<Object>} Catégorie créée
   */
  async createCategory(data) {
    try {
      // Validation des données
      if (!data.nom || data.nom.trim().length === 0) {
        throw new Error('Le nom de la catégorie est obligatoire');
      }

      if (!data.displayName || data.displayName.trim().length === 0) {
        throw new Error('Le nom d\'affichage est obligatoire');
      }

      // Vérifier l'unicité du nom
      const existing = await this.prisma.movementCategory.findUnique({
        where: { nom: data.nom.toLowerCase().trim() }
      });

      if (existing) {
        throw new Error('Une catégorie avec ce nom existe déjà');
      }

      // Créer la catégorie
      const category = await this.prisma.movementCategory.create({
        data: {
          nom: data.nom.toLowerCase().trim(),
          displayName: data.displayName.trim(),
          color: data.color || '#6B7280',
          icon: data.icon || 'category',
          isDefault: false, // Les catégories créées par l'utilisateur ne sont jamais par défaut
          isActive: true
        }
      });

      console.log(`✅ Catégorie créée: ${category.displayName} (${category.nom})`);
      return category;

    } catch (error) {
      console.error('❌ Erreur lors de la création de la catégorie:', error.message);
      throw error;
    }
  }

  /**
   * Met à jour une catégorie
   * @param {number} id - ID de la catégorie
   * @param {Object} data - Nouvelles données
   * @returns {Promise<Object>} Catégorie mise à jour
   */
  async updateCategory(id, data) {
    try {
      // Vérifier que la catégorie existe
      const existing = await this.getCategoryById(id);

      // Les catégories par défaut ne peuvent pas être modifiées (sauf couleur et icône)
      if (existing.isDefault && (data.nom || data.displayName)) {
        throw new Error('Les catégories par défaut ne peuvent pas être renommées');
      }

      // Préparer les données de mise à jour
      const updateData = {};

      if (data.nom && !existing.isDefault) {
        // Vérifier l'unicité du nouveau nom
        const nameExists = await this.prisma.movementCategory.findFirst({
          where: {
            nom: data.nom.toLowerCase().trim(),
            id: { not: parseInt(id) }
          }
        });

        if (nameExists) {
          throw new Error('Une catégorie avec ce nom existe déjà');
        }

        updateData.nom = data.nom.toLowerCase().trim();
      }

      if (data.displayName && !existing.isDefault) {
        updateData.displayName = data.displayName.trim();
      }

      if (data.color) {
        updateData.color = data.color;
      }

      if (data.icon) {
        updateData.icon = data.icon;
      }

      // Mettre à jour la catégorie
      const updated = await this.prisma.movementCategory.update({
        where: { id: parseInt(id) },
        data: updateData
      });

      console.log(`✅ Catégorie mise à jour: ${updated.displayName}`);
      return updated;

    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour de la catégorie:', error.message);
      throw error;
    }
  }

  /**
   * Désactive une catégorie (soft delete)
   * @param {number} id - ID de la catégorie
   * @returns {Promise<boolean>} Succès de la désactivation
   */
  async deactivateCategory(id) {
    try {
      // Vérifier que la catégorie existe
      const existing = await this.getCategoryById(id);

      // Les catégories par défaut ne peuvent pas être supprimées
      if (existing.isDefault) {
        throw new Error('Les catégories par défaut ne peuvent pas être supprimées');
      }

      // Vérifier s'il y a des mouvements associés
      const movementCount = await this.prisma.financialMovement.count({
        where: { categorieId: parseInt(id) }
      });

      if (movementCount > 0) {
        // Désactiver seulement (soft delete)
        await this.prisma.movementCategory.update({
          where: { id: parseInt(id) },
          data: { isActive: false }
        });

        console.log(`⚠️ Catégorie désactivée (${movementCount} mouvements associés): ${existing.displayName}`);
        return true;
      } else {
        // Supprimer complètement si aucun mouvement associé
        await this.prisma.movementCategory.delete({
          where: { id: parseInt(id) }
        });

        console.log(`✅ Catégorie supprimée: ${existing.displayName}`);
        return true;
      }

    } catch (error) {
      console.error('❌ Erreur lors de la suppression de la catégorie:', error.message);
      throw error;
    }
  }

  /**
   * Récupère les statistiques d'utilisation des catégories
   * @param {Object} options - Options de filtrage
   * @returns {Promise<Array>} Statistiques par catégorie
   */
  async getCategoryStatistics(options = {}) {
    try {
      const { startDate, endDate } = options;

      // Construction des filtres pour les mouvements
      const where = {};

      if (startDate || endDate) {
        where.date = {};
        if (startDate) {
          where.date.gte = new Date(startDate);
        }
        if (endDate) {
          where.date.lte = new Date(endDate);
        }
      }

      // Récupérer toutes les catégories actives
      const categories = await this.getCategories();

      // Calculer les statistiques pour chaque catégorie
      const statistics = await Promise.all(
        categories.map(async (category) => {
          const [movementCount, totalAmount, avgAmount] = await Promise.all([
            this.prisma.financialMovement.count({
              where: { ...where, categorieId: category.id }
            }),
            this.prisma.financialMovement.aggregate({
              where: { ...where, categorieId: category.id },
              _sum: { montant: true }
            }),
            this.prisma.financialMovement.aggregate({
              where: { ...where, categorieId: category.id },
              _avg: { montant: true }
            })
          ]);

          return {
            category,
            movementCount,
            totalAmount: totalAmount._sum.montant || 0,
            averageAmount: avgAmount._avg.montant || 0
          };
        })
      );

      // Trier par montant total décroissant
      return statistics.sort((a, b) => b.totalAmount - a.totalAmount);

    } catch (error) {
      console.error('❌ Erreur lors du calcul des statistiques des catégories:', error.message);
      throw error;
    }
  }

  /**
   * Réactive une catégorie désactivée
   * @param {number} id - ID de la catégorie
   * @returns {Promise<Object>} Catégorie réactivée
   */
  async reactivateCategory(id) {
    try {
      const category = await this.prisma.movementCategory.update({
        where: { id: parseInt(id) },
        data: { isActive: true }
      });

      console.log(`✅ Catégorie réactivée: ${category.displayName}`);
      return category;

    } catch (error) {
      console.error('❌ Erreur lors de la réactivation de la catégorie:', error.message);
      throw error;
    }
  }
}

module.exports = MovementCategoryService;
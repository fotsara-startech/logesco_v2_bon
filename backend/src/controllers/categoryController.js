const { PrismaClient } = require('../config/prisma-client.js');
const prisma = new PrismaClient();

/**
 * Contrôleur pour la gestion des catégories de produits
 */
class CategoryController {
  /**
   * Récupère toutes les catégories
   */
  async getAll(req, res) {
    try {
      const categories = await prisma.category.findMany({
        orderBy: {
          nom: 'asc'
        },
        include: {
          _count: {
            select: {
              produits: true
            }
          }
        }
      });

      res.json({
        success: true,
        data: categories,
        message: 'Catégories récupérées avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des catégories:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des catégories',
        error: error.message
      });
    }
  }

  /**
   * Récupère une catégorie par ID
   */
  async getById(req, res) {
    try {
      const { id } = req.params;
      
      const category = await prisma.category.findUnique({
        where: { id: parseInt(id) },
        include: {
          produits: {
            select: {
              id: true,
              nom: true,
              reference: true
            }
          },
          _count: {
            select: {
              produits: true
            }
          }
        }
      });

      if (!category) {
        return res.status(404).json({
          success: false,
          message: 'Catégorie non trouvée'
        });
      }

      res.json({
        success: true,
        data: category,
        message: 'Catégorie récupérée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la récupération de la catégorie:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération de la catégorie',
        error: error.message
      });
    }
  }

  /**
   * Crée une nouvelle catégorie
   */
  async create(req, res) {
    try {
      const { nom, description } = req.body;

      // Validation
      if (!nom || nom.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Le nom de la catégorie est obligatoire'
        });
      }

      // Vérifier l'unicité du nom
      const existingCategory = await prisma.category.findUnique({
        where: { nom: nom.trim() }
      });

      if (existingCategory) {
        return res.status(409).json({
          success: false,
          message: 'Une catégorie avec ce nom existe déjà'
        });
      }

      const category = await prisma.category.create({
        data: {
          nom: nom.trim(),
          description: description?.trim() || null
        }
      });

      res.status(201).json({
        success: true,
        data: category,
        message: 'Catégorie créée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la création de la catégorie:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la création de la catégorie',
        error: error.message
      });
    }
  }

  /**
   * Met à jour une catégorie
   */
  async update(req, res) {
    try {
      const { id } = req.params;
      const { nom, description } = req.body;

      // Validation
      if (!nom || nom.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Le nom de la catégorie est obligatoire'
        });
      }

      // Vérifier que la catégorie existe
      const existingCategory = await prisma.category.findUnique({
        where: { id: parseInt(id) }
      });

      if (!existingCategory) {
        return res.status(404).json({
          success: false,
          message: 'Catégorie non trouvée'
        });
      }

      // Vérifier l'unicité du nom (sauf pour la catégorie actuelle)
      const duplicateCategory = await prisma.category.findFirst({
        where: {
          nom: nom.trim(),
          id: { not: parseInt(id) }
        }
      });

      if (duplicateCategory) {
        return res.status(409).json({
          success: false,
          message: 'Une catégorie avec ce nom existe déjà'
        });
      }

      const category = await prisma.category.update({
        where: { id: parseInt(id) },
        data: {
          nom: nom.trim(),
          description: description?.trim() || null
        }
      });

      res.json({
        success: true,
        data: category,
        message: 'Catégorie mise à jour avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la mise à jour de la catégorie:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la mise à jour de la catégorie',
        error: error.message
      });
    }
  }

  /**
   * Supprime une catégorie
   */
  async delete(req, res) {
    try {
      const { id } = req.params;

      // Vérifier que la catégorie existe
      const existingCategory = await prisma.category.findUnique({
        where: { id: parseInt(id) },
        include: {
          _count: {
            select: {
              produits: true
            }
          }
        }
      });

      if (!existingCategory) {
        return res.status(404).json({
          success: false,
          message: 'Catégorie non trouvée'
        });
      }

      // Vérifier qu'aucun produit n'utilise cette catégorie
      if (existingCategory._count.produits > 0) {
        return res.status(400).json({
          success: false,
          message: `Impossible de supprimer cette catégorie car elle est utilisée par ${existingCategory._count.produits} produit(s)`
        });
      }

      await prisma.category.delete({
        where: { id: parseInt(id) }
      });

      res.json({
        success: true,
        message: 'Catégorie supprimée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la suppression de la catégorie:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la suppression de la catégorie',
        error: error.message
      });
    }
  }
}

module.exports = new CategoryController();
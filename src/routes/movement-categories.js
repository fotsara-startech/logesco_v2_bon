/**
 * Routes pour les catégories de mouvements financiers
 */

const express = require('express');
const Joi = require('joi');
const { validate } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, MovementCategoryDTO } = require('../dto');

// Schémas de validation
const createCategorySchema = Joi.object({
  nom: Joi.string().min(2).max(50).required(),
  displayName: Joi.string().min(2).max(100).required(),
  color: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).optional(),
  icon: Joi.string().min(2).max(50).optional()
});

const updateCategorySchema = Joi.object({
  nom: Joi.string().min(2).max(50).optional(),
  displayName: Joi.string().min(2).max(100).optional(),
  color: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).optional(),
  icon: Joi.string().min(2).max(50).optional()
});

/**
 * Crée le routeur pour les catégories de mouvements
 */
function createMovementCategoryRouter(services) {
  const router = express.Router();
  const { movementCategoryService } = services;

  /**
   * GET /movement-categories
   * Récupère toutes les catégories actives
   */
  router.get('/',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const categories = await movementCategoryService.getCategories();
        
        res.json(BaseResponseDTO.success(
          MovementCategoryDTO.fromEntities(categories),
          'Catégories récupérées avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération catégories:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des catégories'));
      }
    }
  );

  /**
   * GET /movement-categories/:id
   * Récupère une catégorie par son ID
   */
  router.get('/:id',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const category = await movementCategoryService.getCategoryById(req.params.id);
        
        res.json(BaseResponseDTO.success(
          MovementCategoryDTO.fromEntity(category),
          'Catégorie récupérée avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération catégorie:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération de la catégorie'));
        }
      }
    }
  );

  /**
   * POST /movement-categories
   * Crée une nouvelle catégorie personnalisée
   */
  router.post('/',
    authenticateToken(services.authService),
    validate(createCategorySchema),
    async (req, res) => {
      try {
        const category = await movementCategoryService.createCategory(req.body);
        
        res.status(201).json(BaseResponseDTO.success(
          MovementCategoryDTO.fromEntity(category),
          'Catégorie créée avec succès'
        ));

      } catch (error) {
        console.error('Erreur création catégorie:', error.message);
        
        if (error.message.includes('obligatoire') || 
            error.message.includes('existe déjà')) {
          res.status(400).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la création de la catégorie'));
        }
      }
    }
  );

  /**
   * PUT /movement-categories/:id
   * Met à jour une catégorie
   */
  router.put('/:id',
    authenticateToken(services.authService),
    validate(updateCategorySchema),
    async (req, res) => {
      try {
        const category = await movementCategoryService.updateCategory(
          req.params.id,
          req.body
        );
        
        res.json(BaseResponseDTO.success(
          MovementCategoryDTO.fromEntity(category),
          'Catégorie mise à jour avec succès'
        ));

      } catch (error) {
        console.error('Erreur mise à jour catégorie:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else if (error.message.includes('par défaut') || 
                   error.message.includes('existe déjà')) {
          res.status(400).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la mise à jour de la catégorie'));
        }
      }
    }
  );

  /**
   * DELETE /movement-categories/:id
   * Supprime ou désactive une catégorie
   */
  router.delete('/:id',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        await movementCategoryService.deactivateCategory(req.params.id);
        
        res.json(BaseResponseDTO.success(
          null,
          'Catégorie supprimée avec succès'
        ));

      } catch (error) {
        console.error('Erreur suppression catégorie:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else if (error.message.includes('par défaut')) {
          res.status(400).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la suppression de la catégorie'));
        }
      }
    }
  );

  /**
   * POST /movement-categories/:id/reactivate
   * Réactive une catégorie désactivée
   */
  router.post('/:id/reactivate',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const category = await movementCategoryService.reactivateCategory(req.params.id);
        
        res.json(BaseResponseDTO.success(
          MovementCategoryDTO.fromEntity(category),
          'Catégorie réactivée avec succès'
        ));

      } catch (error) {
        console.error('Erreur réactivation catégorie:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la réactivation de la catégorie'));
        }
      }
    }
  );

  /**
   * GET /movement-categories/statistics
   * Récupère les statistiques d'utilisation des catégories
   */
  router.get('/statistics',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const { startDate, endDate } = req.query;
        
        const stats = await movementCategoryService.getCategoryStatistics({
          startDate,
          endDate
        });
        
        res.json(BaseResponseDTO.success(
          stats,
          'Statistiques des catégories récupérées avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération statistiques catégories:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des statistiques'));
      }
    }
  );

  return router;
}

module.exports = { createMovementCategoryRouter };
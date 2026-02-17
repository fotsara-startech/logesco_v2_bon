const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');

/**
 * Routes pour la gestion des catégories de produits
 */

// GET /api/v1/categories - Récupérer toutes les catégories
router.get('/', categoryController.getAll);

// GET /api/v1/categories/:id - Récupérer une catégorie par ID
router.get('/:id', categoryController.getById);

// POST /api/v1/categories - Créer une nouvelle catégorie
router.post('/', categoryController.create);

// PUT /api/v1/categories/:id - Mettre à jour une catégorie
router.put('/:id', categoryController.update);

// DELETE /api/v1/categories/:id - Supprimer une catégorie
router.delete('/:id', categoryController.delete);

module.exports = router;
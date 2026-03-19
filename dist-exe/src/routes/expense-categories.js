/**
 * Routes pour les catégories de dépenses
 * Gestion des catégories pour organiser les dépenses
 */

const express = require('express');
const { validate } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const Joi = require('joi');

// Schémas de validation
const expenseCategorySchemas = {
    create: Joi.object({
        nom: Joi.string().trim().min(2).max(100).required(),
        description: Joi.string().trim().max(500).allow(null, ''),
        couleur: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).allow(null)
    }),

    update: Joi.object({
        nom: Joi.string().trim().min(2).max(100).required(),
        description: Joi.string().trim().max(500).allow(null, ''),
        couleur: Joi.string().pattern(/^#[0-9A-Fa-f]{6}$/).allow(null),
        estActif: Joi.boolean().required()
    })
};

function createExpenseCategoriesRouter({ prisma, authService }) {
    const router = express.Router();

    // Middleware d'authentification
    router.use(authenticateToken(authService));

    /**
     * GET /expense-categories
     * Récupère toutes les catégories de dépenses
     */
    router.get('/', async (req, res) => {
        try {
            const categories = await prisma.movementCategory.findMany({
                orderBy: [
                    { isActive: 'desc' },
                    { nom: 'asc' }
                ]
            });

            res.json({
                success: true,
                data: categories,
                message: 'Catégories de dépenses récupérées avec succès'
            });

        } catch (error) {
            console.error('Erreur récupération catégories dépenses:', error);
            res.status(500).json({
                success: false,
                message: 'Erreur lors de la récupération des catégories'
            });
        }
    });

    /**
     * GET /expense-categories/:id
     * Récupère une catégorie de dépense spécifique
     */
    router.get('/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const categoryId = parseInt(id);

            if (isNaN(categoryId)) {
                return res.status(400).json({
                    success: false,
                    message: 'ID de catégorie invalide'
                });
            }

            const category = await prisma.movementCategory.findUnique({
                where: { id: categoryId }
            });

            if (!category) {
                return res.status(404).json({
                    success: false,
                    message: 'Catégorie de dépense non trouvée'
                });
            }

            res.json({
                success: true,
                data: category,
                message: 'Catégorie de dépense récupérée avec succès'
            });

        } catch (error) {
            console.error('Erreur récupération catégorie dépense:', error);
            res.status(500).json({
                success: false,
                message: 'Erreur lors de la récupération de la catégorie'
            });
        }
    });

    /**
     * POST /expense-categories
     * Crée une nouvelle catégorie de dépense
     */
    router.post('/',
        validate(expenseCategorySchemas.create, 'body'),
        async (req, res) => {
            try {
                const { nom, description, couleur } = req.body;

                // Vérifier l'unicité du nom (SQLite compatible)
                const existingCategory = await prisma.movementCategory.findFirst({
                    where: {
                        nom: nom.trim()
                    }
                });

                if (existingCategory) {
                    return res.status(400).json({
                        success: false,
                        message: 'Une catégorie avec ce nom existe déjà'
                    });
                }

                // Créer la catégorie
                const category = await prisma.movementCategory.create({
                    data: {
                        nom: nom.trim(),
                        displayName: nom.trim(),
                        color: couleur || '#2196F3', // Bleu par défaut
                        icon: 'receipt',
                        isActive: true
                    }
                });

                res.status(201).json({
                    success: true,
                    data: category,
                    message: 'Catégorie de dépense créée avec succès'
                });

            } catch (error) {
                console.error('Erreur création catégorie dépense:', error);
                res.status(500).json({
                    success: false,
                    message: 'Erreur lors de la création de la catégorie'
                });
            }
        }
    );

    /**
     * PUT /expense-categories/:id
     * Met à jour une catégorie de dépense
     */
    router.put('/:id',
        validate(expenseCategorySchemas.update, 'body'),
        async (req, res) => {
            try {
                const { id } = req.params;
                const categoryId = parseInt(id);
                const { nom, description, couleur, estActif } = req.body;

                if (isNaN(categoryId)) {
                    return res.status(400).json({
                        success: false,
                        message: 'ID de catégorie invalide'
                    });
                }

                // Vérifier que la catégorie existe
                const existingCategory = await prisma.movementCategory.findUnique({
                    where: { id: categoryId }
                });

                if (!existingCategory) {
                    return res.status(404).json({
                        success: false,
                        message: 'Catégorie de dépense non trouvée'
                    });
                }

                // Vérifier l'unicité du nom (sauf pour la catégorie actuelle)
                const duplicateCategory = await prisma.movementCategory.findFirst({
                    where: {
                        nom: nom.trim(),
                        id: {
                            not: categoryId
                        }
                    }
                });

                if (duplicateCategory) {
                    return res.status(400).json({
                        success: false,
                        message: 'Une autre catégorie avec ce nom existe déjà'
                    });
                }

                // Mettre à jour la catégorie
                const updatedCategory = await prisma.movementCategory.update({
                    where: { id: categoryId },
                    data: {
                        nom: nom.trim(),
                        displayName: nom.trim(),
                        color: couleur || existingCategory.color,
                        isActive: estActif,
                        dateModification: new Date()
                    }
                });

                res.json({
                    success: true,
                    data: updatedCategory,
                    message: 'Catégorie de dépense mise à jour avec succès'
                });

            } catch (error) {
                console.error('Erreur mise à jour catégorie dépense:', error);
                res.status(500).json({
                    success: false,
                    message: 'Erreur lors de la mise à jour de la catégorie'
                });
            }
        }
    );

    /**
     * DELETE /expense-categories/:id
     * Supprime une catégorie de dépense
     */
    router.delete('/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const categoryId = parseInt(id);

            if (isNaN(categoryId)) {
                return res.status(400).json({
                    success: false,
                    message: 'ID de catégorie invalide'
                });
            }

            // Vérifier que la catégorie existe
            const existingCategory = await prisma.movementCategory.findUnique({
                where: { id: categoryId }
            });

            if (!existingCategory) {
                return res.status(404).json({
                    success: false,
                    message: 'Catégorie de dépense non trouvée'
                });
            }

            // Vérifier s'il y a des mouvements financiers liés à cette catégorie
            const relatedMovements = await prisma.financialMovement.count({
                where: { categorieId: categoryId }
            });

            if (relatedMovements > 0) {
                return res.status(400).json({
                    success: false,
                    message: `Impossible de supprimer cette catégorie car elle est utilisée par ${relatedMovements} mouvement(s). Vous pouvez la désactiver à la place.`
                });
            }

            // Supprimer la catégorie
            await prisma.movementCategory.delete({
                where: { id: categoryId }
            });

            res.json({
                success: true,
                message: 'Catégorie de dépense supprimée avec succès'
            });

        } catch (error) {
            console.error('Erreur suppression catégorie dépense:', error);
            res.status(500).json({
                success: false,
                message: 'Erreur lors de la suppression de la catégorie'
            });
        }
    });

    return router;
}

module.exports = { createExpenseCategoriesRouter };
/**
 * Routes pour la gestion des fournisseurs - LOGESCO v2
 * Endpoints CRUD complets avec recherche, filtrage et pagination
 */

const express = require('express');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO, FournisseurDTO } = require('../dto');
const { fournisseurSchemas } = require('../validation/schemas');
const { 
  buildPrismaQuery,
  sanitizeInput 
} = require('../utils/transformers');

/**
 * Crée le routeur pour les fournisseurs
 * @param {Object} models - Factory de modèles
 * @returns {Object} Routeur Express
 */
function createSupplierRouter(models) {
  const router = express.Router();

  /**
   * GET /suppliers
   * Liste tous les fournisseurs avec recherche, filtrage et pagination
   */
  router.get('/',
    validatePagination,
    validate(fournisseurSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, ...searchParams } = req.query;

        // Options de pagination
        const options = buildPrismaQuery({ page, limit });
        options.orderBy = { dateModification: 'desc' };

        // Exécuter la recherche
        const result = await models.fournisseur.search(searchParams, options);
        
        // Transformer en DTOs
        const fournisseursDTO = FournisseurDTO.fromEntities(result.fournisseurs);

        // Réponse paginée
        const response = new PaginatedResponseDTO(
          fournisseursDTO,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total: result.total
          },
          'Fournisseurs récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste fournisseurs:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des fournisseurs')
        );
      }
    }
  );

  /**
   * GET /suppliers/:id
   * Récupère un fournisseur par son ID
   */
  router.get('/:id',
    validateId,
    async (req, res) => {
      try {
        const fournisseur = await models.fournisseur.findById(req.params.id, {
          include: { 
            compte: true,
            commandes: {
              take: 10,
              orderBy: { dateCommande: 'desc' },
              include: {
                details: {
                  include: { produit: true }
                }
              }
            }
          }
        });

        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        const fournisseurDTO = FournisseurDTO.fromEntity(fournisseur);
        res.json(BaseResponseDTO.success(fournisseurDTO, 'Fournisseur récupéré avec succès'));

      } catch (error) {
        console.error('Erreur récupération fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du fournisseur')
        );
      }
    }
  );

  /**
   * POST /suppliers
   * Crée un nouveau fournisseur
   */
  router.post('/',
    authenticateToken(models.authService),
    validate(fournisseurSchemas.create),
    async (req, res) => {
      try {
        // Nettoyer les données d'entrée
        const fournisseurData = sanitizeInput(req.body);

        // Vérifier l'unicité de l'email si fourni
        if (fournisseurData.email) {
          const existingSupplier = await models.prisma.fournisseur.findMany({
            where: { email: fournisseurData.email }
          });

          if (existingSupplier.length > 0) {
            return res.status(409).json(
              BaseResponseDTO.error('Cette adresse email est déjà utilisée par un autre fournisseur', [
                {
                  field: 'email',
                  message: 'L\'email doit être unique',
                  value: fournisseurData.email
                }
              ])
            );
          }
        }

        // Créer le fournisseur avec son compte
        const fournisseur = await models.fournisseur.createWithAccount(fournisseurData);
        
        const fournisseurDTO = FournisseurDTO.fromEntity(fournisseur);
        res.status(201).json(
          BaseResponseDTO.success(fournisseurDTO, 'Fournisseur créé avec succès')
        );

      } catch (error) {
        console.error('Erreur création fournisseur:', error);
        
        if (error.code === 'P2002') {
          return res.status(409).json(
            BaseResponseDTO.error('Email déjà utilisé par un autre fournisseur')
          );
        }

        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création du fournisseur')
        );
      }
    }
  );

  /**
   * PUT /suppliers/:id
   * Met à jour un fournisseur existant
   */
  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(fournisseurSchemas.update),
    async (req, res) => {
      try {
        const fournisseurId = req.params.id;
        const updateData = sanitizeInput(req.body);

        // Vérifier que le fournisseur existe
        const existingSupplier = await models.fournisseur.findById(fournisseurId);
        if (!existingSupplier) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Vérifier l'unicité de l'email si modifié
        if (updateData.email && updateData.email !== existingSupplier.email) {
          const duplicateEmail = await models.prisma.fournisseur.findMany({
            where: { 
              email: updateData.email,
              id: { not: parseInt(fournisseurId) }
            }
          });

          if (duplicateEmail.length > 0) {
            return res.status(409).json(
              BaseResponseDTO.error('Cette adresse email est déjà utilisée par un autre fournisseur')
            );
          }
        }

        // Mettre à jour le fournisseur
        const fournisseurUpdated = await models.fournisseur.update(fournisseurId, updateData, {
          include: { compte: true }
        });

        const fournisseurDTO = FournisseurDTO.fromEntity(fournisseurUpdated);
        res.json(BaseResponseDTO.success(fournisseurDTO, 'Fournisseur mis à jour avec succès'));

      } catch (error) {
        console.error('Erreur mise à jour fournisseur:', error);
        
        if (error.code === 'P2002') {
          return res.status(409).json(
            BaseResponseDTO.error('Email déjà utilisé par un autre fournisseur')
          );
        }

        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la mise à jour du fournisseur')
        );
      }
    }
  );

  /**
   * DELETE /suppliers/:id
   * Supprime un fournisseur (si aucune transaction liée)
   */
  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const fournisseurId = req.params.id;

        // Vérifier que le fournisseur existe
        const existingSupplier = await models.fournisseur.findById(fournisseurId);
        if (!existingSupplier) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Vérifier s'il y a des commandes liées
        const canDelete = await models.fournisseur.canDelete(parseInt(fournisseurId));

        if (!canDelete) {
          return res.status(409).json(
            BaseResponseDTO.error(
              'Impossible de supprimer ce fournisseur car il a des commandes d\'approvisionnement associées',
              [{
                field: 'commandes',
                message: 'Des commandes existent pour ce fournisseur',
                suggestion: 'Vous pouvez modifier les informations du fournisseur mais pas le supprimer'
              }]
            )
          );
        }

        // Supprimer le fournisseur et son compte
        await models.prisma.$transaction(async (tx) => {
          // Supprimer le compte s'il existe
          await tx.compteFournisseur.deleteMany({
            where: { fournisseurId: parseInt(fournisseurId) }
          });

          // Supprimer le fournisseur
          await tx.fournisseur.delete({
            where: { id: parseInt(fournisseurId) }
          });
        });
        
        res.json(BaseResponseDTO.success(null, 'Fournisseur supprimé avec succès'));

      } catch (error) {
        console.error('Erreur suppression fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la suppression du fournisseur')
        );
      }
    }
  );

  /**
   * GET /suppliers/search/suggestions
   * Suggestions de recherche pour l'autocomplétion
   */
  router.get('/search/suggestions',
    validate(fournisseurSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { q } = req.query;

        if (!q || q.length < 2) {
          return res.json(BaseResponseDTO.success([], 'Requête trop courte'));
        }

        const suggestions = await models.prisma.fournisseur.findMany({
          where: {
            OR: [
              { nom: { contains: q } },
              { personneContact: { contains: q } },
              { telephone: { contains: q } },
              { email: { contains: q } }
            ]
          },
          select: {
            id: true,
            nom: true,
            personneContact: true,
            telephone: true,
            email: true
          },
          take: 10,
          orderBy: { nom: 'asc' }
        });

        res.json(BaseResponseDTO.success(suggestions, 'Suggestions récupérées'));

      } catch (error) {
        console.error('Erreur suggestions fournisseurs:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des suggestions')
        );
      }
    }
  );

  /**
   * GET /suppliers/:id/orders
   * Historique des commandes d'un fournisseur
   */
  router.get('/:id/orders',
    validateId,
    validatePagination,
    async (req, res) => {
      try {
        const { page, limit } = req.query;
        const fournisseurId = parseInt(req.params.id);

        // Vérifier que le fournisseur existe
        const fournisseur = await models.fournisseur.findById(fournisseurId);
        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        const options = buildPrismaQuery({ page, limit });
        options.where = { fournisseurId };
        options.include = {
          details: {
            include: { produit: true }
          }
        };
        options.orderBy = { dateCommande: 'desc' };

        const [commandes, total] = await Promise.all([
          models.commandeApprovisionnement.findMany(options),
          models.commandeApprovisionnement.count({ where: { fournisseurId } })
        ]);

        const response = new PaginatedResponseDTO(
          commandes,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Historique des commandes récupéré'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur historique commandes fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération de l\'historique')
        );
      }
    }
  );

  return router;
}

module.exports = { createSupplierRouter };
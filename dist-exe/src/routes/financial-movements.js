/**
 * Routes pour les mouvements financiers
 * Gestion des sorties d'argent avec traçabilité complète
 */

const express = require('express');
const multer = require('multer');
const Joi = require('joi');
const { validate } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { 
  BaseResponseDTO, 
  PaginatedResponseDTO,
  FinancialMovementDTO,
  MovementStatisticsDTO 
} = require('../dto');

// Configuration multer pour l'upload de fichiers
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 5 // Maximum 5 fichiers par upload
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'image/jpeg',
      'image/png', 
      'image/gif',
      'image/webp',
      'application/pdf'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé'), false);
    }
  }
});

// Schémas de validation
const createMovementSchema = Joi.object({
  montant: Joi.number().positive().required(),
  categorieId: Joi.number().integer().positive().required(),
  description: Joi.string().min(3).max(500).required(),
  date: Joi.date().iso().optional(),
  notes: Joi.string().max(1000).optional().allow('')
});

const updateMovementSchema = Joi.object({
  montant: Joi.number().positive().optional(),
  categorieId: Joi.number().integer().positive().optional(),
  description: Joi.string().min(3).max(500).optional(),
  date: Joi.date().iso().optional(),
  notes: Joi.string().max(1000).optional().allow('')
});

const querySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().max(100).optional(),
  categorieId: Joi.number().integer().positive().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  minAmount: Joi.number().positive().optional(),
  maxAmount: Joi.number().positive().optional(),
  utilisateurId: Joi.number().integer().positive().optional()
});

const exportReportSchema = Joi.object({
  startDate: Joi.date().iso().required(),
  endDate: Joi.date().iso().required(),
  title: Joi.string().min(1).max(200).required(),
  categoryIds: Joi.array().items(Joi.number().integer().positive()).optional(),
  includeDetails: Joi.boolean().default(true),
  format: Joi.string().valid('pdf', 'excel').required()
});

/**
 * Crée le routeur pour les mouvements financiers
 */
function createFinancialMovementRouter(services) {
  const router = express.Router();
  const { financialMovementService, fileUploadService, movementReportService } = services;

  /**
   * GET /financial-movements/summary
   * Récupère le résumé des mouvements pour une période
   */
  router.get('/summary',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const { startDate, endDate } = req.query;
        
        if (!startDate || !endDate) {
          return res.status(400).json(
            BaseResponseDTO.error('Les dates de début et de fin sont obligatoires')
          );
        }

        const summary = await movementReportService.getSummary(startDate, endDate);
        
        res.json(BaseResponseDTO.success(
          summary,
          'Résumé récupéré avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération résumé:', error.message);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du résumé')
        );
      }
    }
  );

  /**
   * GET /financial-movements/category-summary
   * Récupère le résumé par catégorie pour une période
   */
  router.get('/category-summary',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const { startDate, endDate } = req.query;
        
        if (!startDate || !endDate) {
          return res.status(400).json(
            BaseResponseDTO.error('Les dates de début et de fin sont obligatoires')
          );
        }

        const summary = await movementReportService.getCategorySummary(startDate, endDate);
        
        res.json(BaseResponseDTO.success(
          summary,
          'Résumé par catégorie récupéré avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération résumé catégorie:', error.message);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du résumé par catégorie')
        );
      }
    }
  );

  /**
   * GET /financial-movements/daily-summary
   * Récupère le résumé quotidien pour une période
   */
  router.get('/daily-summary',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const { startDate, endDate } = req.query;
        
        if (!startDate || !endDate) {
          return res.status(400).json(
            BaseResponseDTO.error('Les dates de début et de fin sont obligatoires')
          );
        }

        const summary = await movementReportService.getDailySummary(startDate, endDate);
        
        res.json(BaseResponseDTO.success(
          summary,
          'Résumé quotidien récupéré avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération résumé quotidien:', error.message);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du résumé quotidien')
        );
      }
    }
  );

  /**
   * POST /financial-movements/export/pdf
   * Exporte un rapport au format PDF
   */
  router.post('/export/pdf',
    authenticateToken(services.authService),
    validate(exportReportSchema),
    async (req, res) => {
      try {
        const result = await movementReportService.exportToPdf(req.body);
        
        res.json(BaseResponseDTO.success(
          result,
          'Rapport PDF généré avec succès'
        ));

      } catch (error) {
        console.error('Erreur export PDF:', error.message);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'export PDF')
        );
      }
    }
  );

  /**
   * POST /financial-movements/export/excel
   * Exporte un rapport au format Excel
   */
  router.post('/export/excel',
    authenticateToken(services.authService),
    validate(exportReportSchema),
    async (req, res) => {
      try {
        const result = await movementReportService.exportToExcel(req.body);
        
        res.json(BaseResponseDTO.success(
          result,
          'Rapport Excel généré avec succès'
        ));

      } catch (error) {
        console.error('Erreur export Excel:', error.message);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'export Excel')
        );
      }
    }
  );

  /**
   * GET /financial-movements
   * Récupère la liste des mouvements avec filtrage et pagination
   */
  router.get('/',
    authenticateToken(services.authService),
    validate(querySchema, 'query'),
    async (req, res) => {
      try {
        const result = await financialMovementService.getMovements(req.query);
        
        const response = new PaginatedResponseDTO(
          FinancialMovementDTO.fromEntities(result.movements),
          result.pagination,
          'Mouvements financiers récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur récupération mouvements:', error.message);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des mouvements')
        );
      }
    }
  );

  /**
   * GET /financial-movements/statistics
   * Récupère les statistiques des mouvements
   */
  router.get('/statistics',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const { startDate, endDate, categorieId } = req.query;
        
        const stats = await financialMovementService.getStatistics({
          startDate,
          endDate,
          categorieId
        });
        
        res.json(BaseResponseDTO.success(
          MovementStatisticsDTO.fromEntity(stats),
          'Statistiques récupérées avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération statistiques:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des statistiques'));
      }
    }
  );

  /**
   * GET /financial-movements/:id
   * Récupère un mouvement par son ID
   */
  router.get('/:id',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const movement = await financialMovementService.getMovementById(req.params.id);
        
        res.json(BaseResponseDTO.success(
          FinancialMovementDTO.fromEntity(movement),
          'Mouvement financier récupéré avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération mouvement:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération du mouvement'));
        }
      }
    }
  );

  /**
   * POST /financial-movements
   * Crée un nouveau mouvement financier
   */
  router.post('/',
    authenticateToken(services.authService),
    validate(createMovementSchema),
    async (req, res) => {
      try {
        const movementData = {
          ...req.body,
          utilisateurId: req.user.id
        };

        const movement = await financialMovementService.createMovement(movementData);
        
        res.status(201).json(BaseResponseDTO.success(
          FinancialMovementDTO.fromEntity(movement),
          'Mouvement financier créé avec succès'
        ));

      } catch (error) {
        console.error('Erreur création mouvement:', error.message);
        
        if (error.message.includes('obligatoire') || 
            error.message.includes('supérieur') ||
            error.message.includes('non trouvé')) {
          res.status(400).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la création du mouvement'));
        }
      }
    }
  );

  /**
   * PUT /financial-movements/:id
   * Met à jour un mouvement financier
   */
  router.put('/:id',
    authenticateToken(services.authService),
    validate(updateMovementSchema),
    async (req, res) => {
      try {
        const movement = await financialMovementService.updateMovement(
          req.params.id, 
          req.body
        );
        
        res.json(BaseResponseDTO.success(
          FinancialMovementDTO.fromEntity(movement),
          'Mouvement financier mis à jour avec succès'
        ));

      } catch (error) {
        console.error('Erreur mise à jour mouvement:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else if (error.message.includes('obligatoire') || 
                   error.message.includes('supérieur')) {
          res.status(400).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la mise à jour du mouvement'));
        }
      }
    }
  );

  /**
   * DELETE /financial-movements/:id
   * Supprime un mouvement financier
   */
  router.delete('/:id',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        await financialMovementService.deleteMovement(req.params.id);
        
        res.json(BaseResponseDTO.success(
          null,
          'Mouvement financier supprimé avec succès'
        ));

      } catch (error) {
        console.error('Erreur suppression mouvement:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la suppression du mouvement'));
        }
      }
    }
  );

  /**
   * GET /financial-movements/statistics
   * Récupère les statistiques des mouvements
   */
  router.get('/statistics',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const { startDate, endDate, categorieId } = req.query;
        
        const stats = await financialMovementService.getStatistics({
          startDate,
          endDate,
          categorieId
        });
        
        res.json(BaseResponseDTO.success(
          MovementStatisticsDTO.fromEntity(stats),
          'Statistiques récupérées avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération statistiques:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des statistiques'));
      }
    }
  );

  /**
   * POST /financial-movements/:id/attachments
   * Upload un fichier justificatif
   */
  router.post('/:id/attachments',
    authenticateToken(services.authService),
    upload.single('file'),
    async (req, res) => {
      try {
        if (!req.file) {
          return res.status(400).json(BaseResponseDTO.error('Aucun fichier fourni'));
        }

        const attachment = await fileUploadService.uploadAttachment(
          req.params.id,
          req.file
        );
        
        res.status(201).json(BaseResponseDTO.success(
          attachment,
          'Fichier justificatif uploadé avec succès'
        ));

      } catch (error) {
        console.error('Erreur upload fichier:', error.message);
        
        if (error.message.includes('non trouvé') || 
            error.message.includes('non autorisé') ||
            error.message.includes('volumineux')) {
          res.status(400).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de l\'upload du fichier'));
        }
      }
    }
  );

  /**
   * GET /financial-movements/:id/attachments
   * Récupère les fichiers justificatifs d'un mouvement
   */
  router.get('/:id/attachments',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const attachments = await fileUploadService.getMovementAttachments(req.params.id);
        
        res.json(BaseResponseDTO.success(
          attachments,
          'Fichiers justificatifs récupérés avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération attachments:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des fichiers'));
      }
    }
  );

  /**
   * GET /attachments/:id/download
   * Télécharge un fichier justificatif
   */
  router.get('/attachments/:id/download',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        const attachment = await fileUploadService.getAttachment(req.params.id);
        
        res.setHeader('Content-Type', attachment.mimeType);
        res.setHeader('Content-Disposition', `attachment; filename="${attachment.originalName}"`);
        res.sendFile(attachment.fullPath);

      } catch (error) {
        console.error('Erreur téléchargement fichier:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors du téléchargement du fichier'));
        }
      }
    }
  );

  /**
   * DELETE /attachments/:id
   * Supprime un fichier justificatif
   */
  router.delete('/attachments/:id',
    authenticateToken(services.authService),
    async (req, res) => {
      try {
        await fileUploadService.deleteAttachment(req.params.id);
        
        res.json(BaseResponseDTO.success(
          null,
          'Fichier justificatif supprimé avec succès'
        ));

      } catch (error) {
        console.error('Erreur suppression fichier:', error.message);
        
        if (error.message.includes('non trouvé')) {
          res.status(404).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la suppression du fichier'));
        }
      }
    }
  );

  return router;
}

module.exports = { createFinancialMovementRouter };
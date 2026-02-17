/**
 * Routes API pour les paramètres d'entreprise
 * Gestion CRUD des informations de base de l'entreprise
 */

const express = require('express');
const { BaseResponseDTO } = require('../dto');
const { parametresEntrepriseSchemas } = require('../validation/schemas');
const { validate } = require('../middleware/validation');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const CompanySettingsModel = require('../models/company-settings');
const AuthService = require('../services/auth');

const router = express.Router();
const authService = new AuthService();

// Endpoint public pour récupérer les informations de base (lecture seule)
router.get('/public', async (req, res) => {
  const companyModel = new CompanySettingsModel();
  
  try {
    const settings = await companyModel.getSettings();
    
    if (!settings) {
      return res.status(404).json(
        BaseResponseDTO.error('Aucun paramètre d\'entreprise configuré')
      );
    }

    // Retourner seulement les informations de base (pas d'infos sensibles)
    const publicInfo = {
      nomEntreprise: settings.nomEntreprise,
      adresse: settings.adresse,
      localisation: settings.localisation,
      telephone: settings.telephone,
      email: settings.email,
      nuiRccm: settings.nuiRccm
    };

    return res.json(
      BaseResponseDTO.success(publicInfo, 'Informations entreprise récupérées')
    );

  } catch (error) {
    console.error('Erreur lors de la récupération des paramètres:', error);
    return res.status(500).json(
      BaseResponseDTO.error('Erreur lors de la récupération des paramètres d\'entreprise')
    );
  } finally {
    await companyModel.disconnect();
  }
});

// Middleware d'authentification pour les autres routes
router.use(authenticateToken(authService));

/**
 * GET /api/company-settings
 * Récupérer les paramètres d'entreprise actuels
 */
router.get('/', async (req, res) => {
  const companyModel = new CompanySettingsModel();
  
  try {
    const settings = await companyModel.getSettings();
    
    if (!settings) {
      return res.status(404).json(
        BaseResponseDTO.error('Aucun paramètre d\'entreprise configuré')
      );
    }

    return res.json(
      BaseResponseDTO.success(settings, 'Paramètres d\'entreprise récupérés avec succès')
    );

  } catch (error) {
    console.error('Erreur lors de la récupération des paramètres:', error);
    return res.status(500).json(
      BaseResponseDTO.error('Erreur lors de la récupération des paramètres d\'entreprise')
    );
  } finally {
    await companyModel.disconnect();
  }
});

/**
 * PUT /api/company-settings
 * Créer ou mettre à jour les paramètres d'entreprise (admin seulement)
 */
router.put('/', 
  requireAdmin,
  validate(parametresEntrepriseSchemas.update),
  async (req, res) => {
    const companyModel = new CompanySettingsModel();
    
    try {
      // Validation supplémentaire côté modèle
      const validation = companyModel.validateSettings(req.body);
      if (!validation.isValid) {
        return res.status(400).json(
          BaseResponseDTO.error('Données invalides', validation.errors)
        );
      }

      const updatedSettings = await companyModel.upsertSettings(req.body);
      
      return res.json(
        BaseResponseDTO.success(updatedSettings, 'Paramètres d\'entreprise mis à jour avec succès')
      );

    } catch (error) {
      console.error('Erreur lors de la mise à jour des paramètres:', error);
      return res.status(500).json(
        BaseResponseDTO.error('Erreur lors de la mise à jour des paramètres d\'entreprise')
      );
    } finally {
      await companyModel.disconnect();
    }
  }
);

/**
 * POST /api/company-settings/validate
 * Valider les données des paramètres d'entreprise sans les sauvegarder
 */
router.post('/validate',
  requireAdmin,
  validate(parametresEntrepriseSchemas.create),
  async (req, res) => {
    const companyModel = new CompanySettingsModel();
    
    try {
      const validation = companyModel.validateSettings(req.body);
      
      if (validation.isValid) {
        return res.json(
          BaseResponseDTO.success('Données valides', { valid: true })
        );
      } else {
        return res.status(400).json(
          BaseResponseDTO.error('Données invalides', validation.errors)
        );
      }

    } catch (error) {
      console.error('Erreur lors de la validation:', error);
      return res.status(500).json(
        BaseResponseDTO.error('Erreur lors de la validation des données')
      );
    } finally {
      await companyModel.disconnect();
    }
  }
);

/**
 * GET /api/company-settings/status
 * Vérifier si les paramètres d'entreprise sont configurés
 */
router.get('/status', async (req, res) => {
  const companyModel = new CompanySettingsModel();
  
  try {
    const isConfigured = await companyModel.isConfigured();
    
    return res.json(
      BaseResponseDTO.success('Statut de configuration récupéré', {
        configured: isConfigured
      })
    );

  } catch (error) {
    console.error('Erreur lors de la vérification du statut:', error);
    return res.status(500).json(
      BaseResponseDTO.error('Erreur lors de la vérification du statut de configuration')
    );
  } finally {
    await companyModel.disconnect();
  }
});

module.exports = router;
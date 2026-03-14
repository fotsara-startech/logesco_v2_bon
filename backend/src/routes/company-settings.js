/**
 * Routes API pour les paramètres d'entreprise
 * Gestion CRUD des informations de base de l'entreprise
 */

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
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
      nuiRccm: settings.nuiRccm,
      logo: settings.logo,
      slogan: settings.slogan,
      langueFacture: settings.langueFacture || 'fr'
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
 * POST /api/company-settings
 * Créer ou mettre à jour les paramètres d'entreprise avec upload de logo (multipart)
 */

// Configuration multer pour l'upload du logo
const logoUpload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadsDir = path.join(__dirname, '../../uploads');
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }
      cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
      // Générer un nom unique pour le fichier
      const timestamp = Date.now();
      const ext = path.extname(file.originalname);
      const name = path.basename(file.originalname, ext);
      cb(null, `${name}_${timestamp}${ext}`);
    }
  }),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  },
  fileFilter: (req, file, cb) => {
    // Accepter seulement les images
    // Vérifier le MIME type ET l'extension
    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/x-png', 'application/octet-stream'];
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    
    const ext = path.extname(file.originalname).toLowerCase();
    const isMimeValid = allowedMimes.includes(file.mimetype);
    const isExtValid = allowedExtensions.includes(ext);
    
    console.log(`📁 Vérification fichier: ${file.originalname}`);
    console.log(`   MIME type: ${file.mimetype} (valide: ${isMimeValid})`);
    console.log(`   Extension: ${ext} (valide: ${isExtValid})`);
    
    // Accepter si le MIME type est valide OU si l'extension est valide
    if (isMimeValid || isExtValid) {
      cb(null, true);
    } else {
      cb(new Error(`Seules les images sont acceptées (MIME: ${file.mimetype}, Ext: ${ext})`));
    }
  }
});

router.post('/',
  requireAdmin,
  logoUpload.single('logo'),
  (err, req, res, next) => {
    // Middleware d'erreur pour multer
    if (err instanceof multer.MulterError) {
      console.error('❌ Erreur Multer:', err.message);
      return res.status(400).json(
        BaseResponseDTO.error(`Erreur upload: ${err.message}`)
      );
    } else if (err) {
      console.error('❌ Erreur upload:', err.message);
      return res.status(400).json(
        BaseResponseDTO.error(`Erreur: ${err.message}`)
      );
    }
    next();
  },
  async (req, res) => {
    const companyModel = new CompanySettingsModel();
    
    try {
      // Préparer les données
      const data = {
        nomEntreprise: req.body.nomEntreprise,
        adresse: req.body.adresse,
        localisation: req.body.localisation || null,
        telephone: req.body.telephone || null,
        email: req.body.email || null,
        nuiRccm: req.body.nuiRccm || null,
        slogan: req.body.slogan || null,
        langueFacture: req.body.langueFacture || 'fr',
        logo: req.file ? req.file.filename : req.body.logo || null
      };

      console.log('📤 Upload logo reçu:');
      console.log(`   Fichier: ${req.file?.filename || 'Aucun'}`);
      console.log(`   MIME type: ${req.file?.mimetype || 'N/A'}`);
      console.log(`   Données: ${JSON.stringify(data, null, 2)}`);

      // Validation
      const validation = companyModel.validateSettings(data);
      if (!validation.isValid) {
        // Supprimer le fichier uploadé en cas d'erreur
        if (req.file) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(400).json(
          BaseResponseDTO.error('Données invalides', validation.errors)
        );
      }

      const updatedSettings = await companyModel.upsertSettings(data);
      
      return res.json(
        BaseResponseDTO.success(updatedSettings, 'Paramètres d\'entreprise et logo mis à jour avec succès')
      );

    } catch (error) {
      console.error('Erreur lors de la mise à jour des paramètres:', error);
      // Supprimer le fichier uploadé en cas d'erreur
      if (req.file) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (e) {
          console.error('Erreur suppression fichier:', e);
        }
      }
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
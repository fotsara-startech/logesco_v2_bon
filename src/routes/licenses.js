const express = require('express');
const router = express.Router();
const licenseController = require('../controllers/licenseController');

/**
 * Routes pour la gestion des licences
 */

// POST /api/v1/licenses - Générer une nouvelle licence
router.post('/', licenseController.generateLicense);

// POST /api/v1/licenses/:licenseKey/validate - Valider une licence
router.post('/:licenseKey/validate', licenseController.validateLicense);

// PUT /api/v1/licenses/:licenseKey/revoke - Révoquer une licence
router.put('/:licenseKey/revoke', licenseController.revokeLicense);

// GET /api/v1/licenses - Récupérer toutes les licences
router.get('/', licenseController.getAllLicenses);

// GET /api/v1/licenses/stats - Récupérer les statistiques
router.get('/stats', licenseController.getLicenseStats);

// GET /api/v1/licenses/:id - Récupérer une licence par ID
router.get('/:id', licenseController.getLicenseById);

module.exports = router;

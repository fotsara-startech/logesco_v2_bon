const LicenseService = require('../services/license');
const { PrismaClient } = require('../config/prisma-client.js');

const prisma = new PrismaClient();
const licenseService = new LicenseService(prisma);

/**
 * Contrôleur pour la gestion des licences
 */
class LicenseController {
  /**
   * Génère une nouvelle licence
   */
  async generateLicense(req, res) {
    try {
      const { userId, subscriptionType, deviceFingerprint, expiresAt, metadata } = req.body;

      if (!userId || !subscriptionType || !expiresAt) {
        return res.status(400).json({
          success: false,
          message: 'userId, subscriptionType et expiresAt sont obligatoires'
        });
      }

      const license = await licenseService.generateLicense({
        userId,
        subscriptionType,
        deviceFingerprint,
        expiresAt,
        metadata
      });

      res.status(201).json({
        success: true,
        data: license,
        message: 'Licence générée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la génération de licence:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la génération de licence',
        error: error.message
      });
    }
  }

  /**
   * Valide une licence
   */
  async validateLicense(req, res) {
    try {
      const { licenseKey } = req.params;
      const { deviceFingerprint } = req.body;

      const validation = await licenseService.validateLicense(licenseKey, deviceFingerprint);

      res.json({
        success: true,
        data: validation,
        message: validation.isValid ? 'Licence valide' : 'Licence invalide'
      });
    } catch (error) {
      console.error('Erreur lors de la validation de licence:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la validation de licence',
        error: error.message
      });
    }
  }

  /**
   * Révoque une licence
   */
  async revokeLicense(req, res) {
    try {
      const { licenseKey } = req.params;
      const { reason } = req.body;
      const performedBy = req.user?.nomUtilisateur || 'ADMIN';

      if (!reason) {
        return res.status(400).json({
          success: false,
          message: 'La raison de révocation est obligatoire'
        });
      }

      const license = await licenseService.revokeLicense(licenseKey, reason, performedBy);

      res.json({
        success: true,
        data: license,
        message: 'Licence révoquée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la révocation de licence:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la révocation de licence',
        error: error.message
      });
    }
  }

  /**
   * Récupère toutes les licences
   */
  async getAllLicenses(req, res) {
    try {
      const filters = {
        userId: req.query.userId,
        subscriptionType: req.query.subscriptionType,
        isActive: req.query.isActive === 'true' ? true : req.query.isActive === 'false' ? false : undefined,
        isRevoked: req.query.isRevoked === 'true' ? true : req.query.isRevoked === 'false' ? false : undefined,
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 50
      };

      const result = await licenseService.getLicenses(filters);

      res.json({
        success: true,
        data: result.licenses,
        pagination: result.pagination,
        message: 'Licences récupérées avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des licences:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des licences',
        error: error.message
      });
    }
  }

  /**
   * Récupère une licence par ID
   */
  async getLicenseById(req, res) {
    try {
      const { id } = req.params;
      const license = await licenseService.getLicenseById(parseInt(id));

      if (!license) {
        return res.status(404).json({
          success: false,
          message: 'Licence non trouvée'
        });
      }

      res.json({
        success: true,
        data: license,
        message: 'Licence récupérée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la récupération de licence:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération de licence',
        error: error.message
      });
    }
  }

  /**
   * Récupère les statistiques des licences
   */
  async getLicenseStats(req, res) {
    try {
      const stats = await licenseService.getLicenseStats();

      res.json({
        success: true,
        data: stats,
        message: 'Statistiques récupérées avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des statistiques',
        error: error.message
      });
    }
  }
}

module.exports = new LicenseController();

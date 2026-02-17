/**
 * Routes d'authentification pour LOGESCO
 * Endpoints pour login, register, refresh, logout
 */

const express = require('express');
const Joi = require('joi');
const { validate } = require('../middleware/validation');
const { 
  authenticateToken, 
  validateRefreshToken, 
  userRateLimit,
  securityHeaders 
} = require('../middleware/auth');
const { BaseResponseDTO } = require('../dto');
const { utilisateurSchemas } = require('../validation/schemas');

/**
 * Crée le routeur d'authentification
 * @param {Object} authService - Service d'authentification
 * @returns {Object} Routeur Express
 */
function createAuthRouter(authService) {
  const router = express.Router();

  // Appliquer les headers de sécurité à toutes les routes auth
  router.use(securityHeaders);

  /**
   * POST /auth/login
   * Authentifie un utilisateur
   */
  router.post('/login', 
    userRateLimit(5, 15 * 60 * 1000), // 5 tentatives par 15 minutes
    validate(utilisateurSchemas.login),
    async (req, res) => {
      try {
        const { nomUtilisateur, motDePasse } = req.body;

        const result = await authService.login(nomUtilisateur, motDePasse);

        res.json(BaseResponseDTO.success(result, 'Connexion réussie'));

      } catch (error) {
        console.error('Erreur login:', error.message);
        
        // Ne pas révéler d'informations sensibles
        const message = error.message.includes('incorrect') 
          ? 'Nom d\'utilisateur ou mot de passe incorrect'
          : 'Erreur lors de la connexion';

        res.status(401).json(BaseResponseDTO.error(message));
      }
    }
  );

  /**
   * POST /auth/register
   * Inscrit un nouvel utilisateur
   */
  router.post('/register',
    userRateLimit(3, 60 * 60 * 1000), // 3 inscriptions par heure
    validate(utilisateurSchemas.create),
    async (req, res) => {
      try {
        const result = await authService.register(req.body);

        res.status(201).json(BaseResponseDTO.success(result, 'Inscription réussie'));

      } catch (error) {
        console.error('Erreur register:', error.message);
        
        if (error.message.includes('déjà utilisé')) {
          res.status(409).json(BaseResponseDTO.error(error.message));
        } else {
          res.status(400).json(BaseResponseDTO.error('Erreur lors de l\'inscription'));
        }
      }
    }
  );

  /**
   * POST /auth/refresh
   * Rafraîchit un access token
   */
  router.post('/refresh',
    userRateLimit(10, 15 * 60 * 1000), // 10 refresh par 15 minutes
    validateRefreshToken,
    async (req, res) => {
      try {
        const { refreshToken } = req.body;

        const result = await authService.refreshToken(refreshToken);

        res.json(BaseResponseDTO.success(result, 'Token rafraîchi avec succès'));

      } catch (error) {
        console.error('Erreur refresh:', error.message);
        res.status(401).json(BaseResponseDTO.error('Refresh token invalide ou expiré'));
      }
    }
  );

  /**
   * POST /auth/logout
   * Déconnecte un utilisateur (invalide le refresh token)
   */
  router.post('/logout',
    validateRefreshToken,
    async (req, res) => {
      try {
        const { refreshToken } = req.body;

        const success = await authService.logout(refreshToken);

        if (success) {
          res.json(BaseResponseDTO.success(null, 'Déconnexion réussie'));
        } else {
          res.json(BaseResponseDTO.success(null, 'Déjà déconnecté'));
        }

      } catch (error) {
        console.error('Erreur logout:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la déconnexion'));
      }
    }
  );

  /**
   * POST /auth/logout-all
   * Déconnecte toutes les sessions d'un utilisateur
   */
  router.post('/logout-all',
    authenticateToken(authService),
    async (req, res) => {
      try {
        const success = await authService.logoutAllSessions(req.user.id);

        if (success) {
          res.json(BaseResponseDTO.success(null, 'Toutes les sessions ont été fermées'));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors de la fermeture des sessions'));
        }

      } catch (error) {
        console.error('Erreur logout-all:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la déconnexion globale'));
      }
    }
  );

  /**
   * POST /auth/change-password
   * Change le mot de passe d'un utilisateur authentifié
   */
  router.post('/change-password',
    authenticateToken(authService),
    validate(Joi.object({
      ancienMotDePasse: Joi.string().required(),
      nouveauMotDePasse: Joi.string().min(6).max(100).required()
    })),
    async (req, res) => {
      try {
        const { ancienMotDePasse, nouveauMotDePasse } = req.body;

        const success = await authService.changePassword(
          req.user.id, 
          ancienMotDePasse, 
          nouveauMotDePasse
        );

        if (success) {
          res.json(BaseResponseDTO.success(null, 'Mot de passe modifié avec succès'));
        } else {
          res.status(400).json(BaseResponseDTO.error('Erreur lors du changement de mot de passe'));
        }

      } catch (error) {
        console.error('Erreur change-password:', error.message);
        
        if (error.message.includes('incorrect')) {
          res.status(400).json(BaseResponseDTO.error('Ancien mot de passe incorrect'));
        } else {
          res.status(500).json(BaseResponseDTO.error('Erreur lors du changement de mot de passe'));
        }
      }
    }
  );

  /**
   * GET /auth/me
   * Récupère les informations de l'utilisateur authentifié
   */
  router.get('/me',
    authenticateToken(authService),
    async (req, res) => {
      try {
        // Récupérer les informations complètes de l'utilisateur depuis la base de données avec le rôle
        const utilisateur = await authService.userModel.findById(req.user.id, {
          include: { role: true }
        });
        
        if (!utilisateur) {
          return res.status(404).json(BaseResponseDTO.error('Utilisateur non trouvé'));
        }

        // Retourner les données utilisateur complètes avec le rôle
        const { UtilisateurDTO } = require('../dto');
        const userData = UtilisateurDTO.fromEntity(utilisateur);
        
        res.json(BaseResponseDTO.success(userData, 'Informations utilisateur récupérées'));

      } catch (error) {
        console.error('Erreur me:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des informations'));
      }
    }
  );

  /**
   * GET /auth/verify
   * Vérifie la validité d'un token (endpoint de test)
   */
  router.get('/verify',
    authenticateToken(authService),
    async (req, res) => {
      try {
        res.json(BaseResponseDTO.success({
          valid: true,
          user: req.user
        }, 'Token valide'));

      } catch (error) {
        console.error('Erreur verify:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la vérification'));
      }
    }
  );

  /**
   * GET /auth/stats
   * Statistiques d'authentification (pour debug/monitoring)
   */
  router.get('/stats',
    authenticateToken(authService),
    async (req, res) => {
      try {
        const stats = authService.getTokenStats();
        
        res.json(BaseResponseDTO.success(stats, 'Statistiques récupérées'));

      } catch (error) {
        console.error('Erreur stats:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des statistiques'));
      }
    }
  );

  return router;
}

module.exports = { createAuthRouter };
/**
 * Middleware d'authentification JWT pour LOGESCO
 * Protection des routes et gestion des permissions
 */

const { BaseResponseDTO } = require('../dto');
const logger = require('../utils/logger');
const { AuthenticationError, AuthorizationError } = require('../utils/business-errors');

/**
 * Middleware pour vérifier l'authentification JWT
 * @param {Object} authService - Service d'authentification
 * @returns {Function} Middleware Express
 */
function authenticateToken(authService) {
  return (req, res, next) => {
    try {
      const authHeader = req.headers['authorization'];
      const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

      if (!token) {
        const error = new AuthenticationError('Token d\'accès requis');
        logger.security('Missing authentication token', {
          url: req.url,
          method: req.method,
          ip: req.ip,
          userAgent: req.get('User-Agent')
        });
        throw error;
      }

      // Mode développement : accepter le token de test
      if (token === 'test-token' && process.env.NODE_ENV !== 'production') {
        req.user = {
          id: 1,
          nomUtilisateur: 'test-user',
          email: 'test@logesco.com'
        };
        return next();
      }

      // Vérifier le token
      const decoded = authService.verifyAccessToken(token);
      
      // Ajouter les informations utilisateur à la requête
      req.user = {
        id: decoded.userId,
        nomUtilisateur: decoded.nomUtilisateur,
        email: decoded.email
      };

      next();

    } catch (error) {
      if (error instanceof AuthenticationError) {
        return next(error);
      }
      
      logger.security('Authentication failed', {
        url: req.url,
        method: req.method,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        error: error.message
      });
      
      const authError = new AuthenticationError('Token invalide ou expiré');
      return next(authError);
    }
  };
}

/**
 * Middleware optionnel pour l'authentification (n'échoue pas si pas de token)
 * @param {Object} authService - Service d'authentification
 * @returns {Function} Middleware Express
 */
function optionalAuth(authService) {
  return (req, res, next) => {
    try {
      const authHeader = req.headers['authorization'];
      const token = authHeader && authHeader.split(' ')[1];

      if (token) {
        try {
          const decoded = authService.verifyAccessToken(token);
          req.user = {
            id: decoded.userId,
            nomUtilisateur: decoded.nomUtilisateur,
            email: decoded.email
          };
        } catch (error) {
          // Token invalide, mais on continue sans utilisateur
          req.user = null;
        }
      } else {
        req.user = null;
      }

      next();

    } catch (error) {
      req.user = null;
      next();
    }
  };
}

/**
 * Middleware pour vérifier que l'utilisateur est propriétaire de la ressource
 * @param {string} userIdField - Champ contenant l'ID utilisateur (params ou body)
 * @returns {Function} Middleware Express
 */
function requireOwnership(userIdField = 'userId') {
  return (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json(
          BaseResponseDTO.error('Authentification requise')
        );
      }

      const resourceUserId = req.params[userIdField] || req.body[userIdField];
      
      if (!resourceUserId) {
        return res.status(400).json(
          BaseResponseDTO.error('ID utilisateur manquant dans la requête')
        );
      }

      if (parseInt(resourceUserId) !== req.user.id) {
        return res.status(403).json(
          BaseResponseDTO.error('Accès refusé - Vous ne pouvez accéder qu\'à vos propres ressources')
        );
      }

      next();

    } catch (error) {
      console.error('Erreur de vérification de propriété:', error);
      return res.status(500).json(
        BaseResponseDTO.error('Erreur lors de la vérification des permissions')
      );
    }
  };
}

/**
 * Middleware pour extraire les informations utilisateur du token sans validation stricte
 * Utile pour les logs et analytics
 * @param {Object} authService - Service d'authentification
 * @returns {Function} Middleware Express
 */
function extractUserInfo(authService) {
  return (req, res, next) => {
    try {
      const authHeader = req.headers['authorization'];
      const token = authHeader && authHeader.split(' ')[1];

      if (token) {
        try {
          const decoded = authService.verifyAccessToken(token);
          req.userInfo = {
            id: decoded.userId,
            nomUtilisateur: decoded.nomUtilisateur,
            email: decoded.email,
            authenticated: true
          };
        } catch (error) {
          req.userInfo = {
            authenticated: false,
            error: error.message
          };
        }
      } else {
        req.userInfo = {
          authenticated: false
        };
      }

      next();

    } catch (error) {
      req.userInfo = {
        authenticated: false,
        error: error.message
      };
      next();
    }
  };
}

/**
 * Middleware de rate limiting par utilisateur authentifié
 * @param {number} maxRequests - Nombre maximum de requêtes
 * @param {number} windowMs - Fenêtre de temps en millisecondes
 * @returns {Function} Middleware Express
 */
function userRateLimit(maxRequests = 100, windowMs = 15 * 60 * 1000) {
  const userRequests = new Map();

  return (req, res, next) => {
    try {
      // Désactiver le rate limiting en mode test
      const isTestMode = process.env.NODE_ENV === 'test' || process.env.TEST_MODE === 'true';
      
      if (isTestMode) {
        console.log('🧪 Rate limiting désactivé pour les tests');
        return next();
      }

      const userId = req.user ? req.user.id : req.ip;
      const now = Date.now();
      const windowStart = now - windowMs;

      // Nettoyer les anciennes entrées
      if (userRequests.has(userId)) {
        const requests = userRequests.get(userId).filter(time => time > windowStart);
        userRequests.set(userId, requests);
      } else {
        userRequests.set(userId, []);
      }

      const currentRequests = userRequests.get(userId);

      if (currentRequests.length >= maxRequests) {
        return res.status(429).json(
          BaseResponseDTO.error('Trop de requêtes, veuillez réessayer plus tard', [
            {
              field: 'rate_limit',
              message: `Maximum ${maxRequests} requêtes par ${windowMs / 1000} secondes`
            }
          ])
        );
      }

      // Ajouter la requête actuelle
      currentRequests.push(now);
      userRequests.set(userId, currentRequests);

      next();

    } catch (error) {
      console.error('Erreur rate limiting:', error);
      next(); // Continuer en cas d'erreur
    }
  };
}

/**
 * Middleware pour valider le format du refresh token
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
function validateRefreshToken(req, res, next) {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json(
        BaseResponseDTO.error('Refresh token requis', [
          {
            field: 'refreshToken',
            message: 'Le refresh token est obligatoire'
          }
        ])
      );
    }

    if (typeof refreshToken !== 'string' || refreshToken.trim().length === 0) {
      return res.status(400).json(
        BaseResponseDTO.error('Format de refresh token invalide', [
          {
            field: 'refreshToken',
            message: 'Le refresh token doit être une chaîne non vide'
          }
        ])
      );
    }

    req.body.refreshToken = refreshToken.trim();
    next();

  } catch (error) {
    console.error('Erreur validation refresh token:', error);
    return res.status(500).json(
      BaseResponseDTO.error('Erreur lors de la validation du token')
    );
  }
}

/**
 * Middleware pour vérifier les permissions d'administrateur
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
function requireAdmin(req, res, next) {
  try {
    if (!req.user) {
      return res.status(401).json(
        BaseResponseDTO.error('Authentification requise')
      );
    }

    // Pour le moment, tous les utilisateurs authentifiés sont considérés comme admins
    // Dans une implémentation future, on pourrait ajouter un champ 'role' dans la table utilisateurs
    // et vérifier req.user.role === 'admin'
    
    // Mode développement : accepter tous les utilisateurs authentifiés comme admins
    if (process.env.NODE_ENV !== 'production') {
      return next();
    }

    // En production, on peut implémenter une logique plus stricte
    // Pour l'instant, on accepte tous les utilisateurs authentifiés
    next();

  } catch (error) {
    console.error('Erreur de vérification des permissions admin:', error);
    return res.status(500).json(
      BaseResponseDTO.error('Erreur lors de la vérification des permissions')
    );
  }
}

/**
 * Middleware pour ajouter les headers de sécurité liés à l'authentification
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
function securityHeaders(req, res, next) {
  // Empêcher la mise en cache des réponses authentifiées
  res.set({
    'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
    'Surrogate-Control': 'no-store'
  });

  next();
}

module.exports = {
  authenticateToken,
  optionalAuth,
  requireOwnership,
  extractUserInfo,
  userRateLimit,
  validateRefreshToken,
  requireAdmin,
  securityHeaders
};
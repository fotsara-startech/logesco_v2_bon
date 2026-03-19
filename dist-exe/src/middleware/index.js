const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const environment = require('../config/environment');
const logger = require('../utils/logger');
const { BusinessError, ErrorFactory } = require('../utils/business-errors');

/**
 * Configuration centralisée des middlewares
 * Adaptée selon l'environnement (local/cloud)
 */
class MiddlewareManager {
  /**
   * Configure tous les middlewares de base
   * @param {Express} app - Instance Express
   */
  static configureAll(app) {
    // Configuration adaptative selon l'environnement
    const config = environment.getMiddlewareConfig();

    // 1. Helmet pour la sécurité HTTP
    app.use(helmet(config.helmet));

    // 2. CORS pour les requêtes cross-origin
    app.use(cors(config.cors));

    // 3. Parsing JSON et URL-encoded
    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // 4. Rate limiting pour prévenir les abus
    const limiter = rateLimit(config.rateLimit);
    app.use('/api/', limiter);

    // 5. Logging des requêtes
    app.use(morgan(config.morgan.format));

    // 6. Middleware de santé de l'API
    app.use('/health', MiddlewareManager.healthCheck);

    console.log('🛡️  Middlewares configurés');
  }

  /**
   * Middleware de vérification de santé de l'API
   * @param {Request} req 
   * @param {Response} res 
   */
  static healthCheck(req, res) {
    const healthStatus = {
      status: 'OK',
      timestamp: new Date().toISOString(),
      environment: environment.isLocal ? 'local' : 'cloud',
      database: environment.databaseConfig.provider,
      version: process.env.npm_package_version || '1.0.0',
      uptime: process.uptime()
    };

    res.status(200).json(healthStatus);
  }

  /**
   * Middleware de gestion d'erreurs globale amélioré
   * @param {Error} err 
   * @param {Request} req 
   * @param {Response} res 
   * @param {Function} next 
   */
  static errorHandler(err, req, res, next) {
    // Convertir les erreurs Prisma en erreurs métier
    if (err.code && err.code.startsWith('P')) {
      err = ErrorFactory.fromPrismaError(err);
    }

    // Convertir les erreurs Joi en erreurs métier
    if (err.isJoi) {
      err = ErrorFactory.fromJoiError(err);
    }

    // Déterminer le niveau de log selon le type d'erreur
    const isClientError = err.status && err.status < 500;
    const logLevel = isClientError ? 'warn' : 'error';

    // Log détaillé de l'erreur
    const logData = {
      url: req.url,
      method: req.method,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.id,
      requestId: req.id,
      ...(err instanceof BusinessError && { businessError: true }),
      ...(err.details && { details: err.details })
    };

    if (logLevel === 'error') {
      logger.error(`API Error: ${err.message}`, err, logData);
    } else {
      logger.warn(`API Warning: ${err.message}`, logData);
    }

    // Réponse d'erreur standardisée
    let errorResponse;

    if (err instanceof BusinessError) {
      // Erreur métier - utiliser la méthode toJSON()
      errorResponse = err.toJSON();
    } else {
      // Erreur système générique
      errorResponse = {
        success: false,
        error: {
          message: isClientError ? err.message : 'Erreur interne du serveur',
          code: err.code || 'INTERNAL_ERROR',
          status: err.status || 500,
          timestamp: new Date().toISOString()
        }
      };
    }

    // Ajouter la stack trace en développement
    if (environment.nodeEnv === 'development' && !isClientError) {
      errorResponse.error.stack = err.stack;
    }

    // Log de sécurité pour les erreurs d'authentification/autorisation
    if (err.status === 401 || err.status === 403) {
      logger.security('Access attempt', {
        url: req.url,
        method: req.method,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        error: err.message
      });
    }

    res.status(err.status || 500).json(errorResponse);
  }

  /**
   * Middleware de validation des données
   * @param {Object} schema - Schéma Joi de validation
   * @param {string} source - Source des données ('body', 'query', 'params')
   */
  static validate(schema, source = 'body') {
    return (req, res, next) => {
      const { error, value } = schema.validate(req[source], {
        abortEarly: false,
        stripUnknown: true
      });

      if (error) {
        const validationError = new Error('Données invalides');
        validationError.status = 400;
        validationError.code = 'VALIDATION_ERROR';
        validationError.details = error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message
        }));

        return next(validationError);
      }

      // Remplacer les données par les données validées
      req[source] = value;
      next();
    };
  }

  /**
   * Middleware de logging des requêtes amélioré
   * @param {Request} req 
   * @param {Response} res 
   * @param {Function} next 
   */
  static requestLogger(req, res, next) {
    const start = Date.now();
    
    // Générer un ID unique pour la requête
    req.id = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    res.on('finish', () => {
      const duration = Date.now() - start;
      const logData = {
        requestId: req.id,
        method: req.method,
        url: req.url,
        status: res.statusCode,
        duration,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        userId: req.user?.id,
        contentLength: res.get('Content-Length'),
        referer: req.get('Referer')
      };

      // Log de performance pour les requêtes lentes
      if (duration > 1000) {
        logger.performance('Slow request', duration, logData);
      }

      // Log différent selon le statut
      if (res.statusCode >= 500) {
        logger.error('Request failed', null, logData);
      } else if (res.statusCode >= 400) {
        logger.warn('Request error', logData);
      } else {
        logger.info('Request completed', logData);
      }

      // Log d'audit pour les opérations sensibles
      if (req.method !== 'GET' && req.user?.id) {
        logger.audit(`${req.method} ${req.url}`, req.user.id, {
          requestId: req.id,
          status: res.statusCode,
          duration
        });
      }
    });

    next();
  }

  /**
   * Middleware de gestion des routes non trouvées
   * @param {Request} req 
   * @param {Response} res 
   */
  static notFound(req, res) {
    const error = {
      success: false,
      error: {
        message: `Route ${req.method} ${req.url} non trouvée`,
        code: 'ROUTE_NOT_FOUND',
        status: 404,
        timestamp: new Date().toISOString()
      }
    };

    res.status(404).json(error);
  }
}

module.exports = MiddlewareManager;
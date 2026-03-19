const winston = require('winston');
const path = require('path');
const environment = require('../config/environment');

/**
 * Configuration centralisée du système de logging
 * Support pour fichiers, console et audit trail
 */
class Logger {
  constructor() {
    this.logger = this.createLogger();
  }

  /**
   * Crée l'instance Winston avec configuration adaptative
   */
  createLogger() {
    const logFormat = winston.format.combine(
      winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss'
      }),
      winston.format.errors({ stack: true }),
      winston.format.json(),
      winston.format.printf(({ timestamp, level, message, ...meta }) => {
        return JSON.stringify({
          timestamp,
          level,
          message,
          ...meta
        });
      })
    );

    const transports = [
      // Console pour développement
      new winston.transports.Console({
        level: environment.nodeEnv === 'development' ? 'debug' : 'info',
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        )
      })
    ];

    // Fichiers de log pour production
    if (environment.nodeEnv === 'production' || environment.isLocal) {
      // Utiliser un chemin en dehors du snapshot pour pkg
      const fs = require('fs');
      const os = require('os');
      const isPkg = typeof process.pkg !== 'undefined';
      
      let logDir;
      if (isPkg) {
        // En mode pkg, utiliser AppData
        const appDataPath = process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local');
        logDir = path.join(appDataPath, 'LOGESCO', 'backend', 'logs');
      } else {
        logDir = path.join(__dirname, '../../logs');
      }
      
      // Créer le dossier s'il n'existe pas
      if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
      }
      
      // Log général
      transports.push(
        new winston.transports.File({
          filename: path.join(logDir, 'app.log'),
          level: 'info',
          format: logFormat,
          maxsize: 5242880, // 5MB
          maxFiles: 5
        })
      );

      // Log d'erreurs
      transports.push(
        new winston.transports.File({
          filename: path.join(logDir, 'error.log'),
          level: 'error',
          format: logFormat,
          maxsize: 5242880, // 5MB
          maxFiles: 5
        })
      );

      // Log d'audit pour les actions utilisateur
      transports.push(
        new winston.transports.File({
          filename: path.join(logDir, 'audit.log'),
          level: 'info',
          format: logFormat,
          maxsize: 10485760, // 10MB
          maxFiles: 10
        })
      );
    }

    return winston.createLogger({
      level: 'debug',
      format: logFormat,
      transports,
      exitOnError: false
    });
  }

  /**
   * Log d'information générale
   */
  info(message, meta = {}) {
    this.logger.info(message, meta);
  }

  /**
   * Log d'erreur
   */
  error(message, error = null, meta = {}) {
    const errorMeta = {
      ...meta,
      ...(error && {
        error: {
          message: error.message,
          stack: error.stack,
          code: error.code,
          status: error.status
        }
      })
    };

    this.logger.error(message, errorMeta);
  }

  /**
   * Log de débogage
   */
  debug(message, meta = {}) {
    this.logger.debug(message, meta);
  }

  /**
   * Log d'avertissement
   */
  warn(message, meta = {}) {
    this.logger.warn(message, meta);
  }

  /**
   * Log d'audit pour les actions utilisateur
   */
  audit(action, userId, details = {}) {
    this.logger.info('AUDIT', {
      action,
      userId,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  /**
   * Log de performance pour mesurer les temps d'exécution
   */
  performance(operation, duration, meta = {}) {
    this.logger.info('PERFORMANCE', {
      operation,
      duration: `${duration}ms`,
      timestamp: new Date().toISOString(),
      ...meta
    });
  }

  /**
   * Log de sécurité pour les tentatives d'accès
   */
  security(event, details = {}) {
    this.logger.warn('SECURITY', {
      event,
      timestamp: new Date().toISOString(),
      ...details
    });
  }
}

// Instance singleton
const logger = new Logger();

module.exports = logger;
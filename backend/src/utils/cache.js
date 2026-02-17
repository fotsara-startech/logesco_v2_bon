/**
 * Système de cache en mémoire pour améliorer les performances
 * Cache simple avec TTL et invalidation
 */

const logger = require('./logger');

/**
 * Cache en mémoire avec TTL (Time To Live)
 */
class MemoryCache {
  constructor(options = {}) {
    this.cache = new Map();
    this.timers = new Map();
    this.defaultTTL = options.defaultTTL || 300000; // 5 minutes par défaut
    this.maxSize = options.maxSize || 1000; // Limite de taille
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0,
      evictions: 0
    };
  }

  /**
   * Stocke une valeur dans le cache
   * @param {string} key - Clé du cache
   * @param {*} value - Valeur à stocker
   * @param {number} ttl - Durée de vie en millisecondes
   */
  set(key, value, ttl = this.defaultTTL) {
    try {
      // Vérifier la limite de taille
      if (this.cache.size >= this.maxSize && !this.cache.has(key)) {
        this._evictOldest();
      }

      // Nettoyer l'ancien timer si la clé existe
      if (this.timers.has(key)) {
        clearTimeout(this.timers.get(key));
      }

      // Stocker la valeur avec métadonnées
      this.cache.set(key, {
        value,
        createdAt: Date.now(),
        ttl,
        accessCount: 0
      });

      // Programmer l'expiration
      if (ttl > 0) {
        const timer = setTimeout(() => {
          this.delete(key);
        }, ttl);
        
        this.timers.set(key, timer);
      }

      this.stats.sets++;
      
      logger.debug('Cache SET', { key, ttl, cacheSize: this.cache.size });
    } catch (error) {
      logger.error('Cache SET error', error, { key });
    }
  }

  /**
   * Récupère une valeur du cache
   * @param {string} key - Clé du cache
   * @returns {*} Valeur ou undefined si non trouvée/expirée
   */
  get(key) {
    try {
      const item = this.cache.get(key);
      
      if (!item) {
        this.stats.misses++;
        logger.debug('Cache MISS', { key });
        return undefined;
      }

      // Vérifier l'expiration manuelle (sécurité)
      if (item.ttl > 0 && Date.now() - item.createdAt > item.ttl) {
        this.delete(key);
        this.stats.misses++;
        logger.debug('Cache EXPIRED', { key });
        return undefined;
      }

      // Mettre à jour les statistiques d'accès
      item.accessCount++;
      this.stats.hits++;
      
      logger.debug('Cache HIT', { key, accessCount: item.accessCount });
      return item.value;
    } catch (error) {
      logger.error('Cache GET error', error, { key });
      this.stats.misses++;
      return undefined;
    }
  }

  /**
   * Supprime une entrée du cache
   * @param {string} key - Clé à supprimer
   * @returns {boolean} True si supprimée, false si non trouvée
   */
  delete(key) {
    try {
      const deleted = this.cache.delete(key);
      
      if (this.timers.has(key)) {
        clearTimeout(this.timers.get(key));
        this.timers.delete(key);
      }

      if (deleted) {
        this.stats.deletes++;
        logger.debug('Cache DELETE', { key });
      }

      return deleted;
    } catch (error) {
      logger.error('Cache DELETE error', error, { key });
      return false;
    }
  }

  /**
   * Vérifie si une clé existe dans le cache
   * @param {string} key - Clé à vérifier
   * @returns {boolean}
   */
  has(key) {
    const item = this.cache.get(key);
    
    if (!item) {
      return false;
    }

    // Vérifier l'expiration
    if (item.ttl > 0 && Date.now() - item.createdAt > item.ttl) {
      this.delete(key);
      return false;
    }

    return true;
  }

  /**
   * Vide complètement le cache
   */
  clear() {
    try {
      // Nettoyer tous les timers
      for (const timer of this.timers.values()) {
        clearTimeout(timer);
      }

      const size = this.cache.size;
      this.cache.clear();
      this.timers.clear();
      
      logger.info('Cache cleared', { clearedItems: size });
    } catch (error) {
      logger.error('Cache CLEAR error', error);
    }
  }

  /**
   * Invalide les entrées correspondant à un pattern
   * @param {string|RegExp} pattern - Pattern à matcher
   */
  invalidatePattern(pattern) {
    try {
      const regex = typeof pattern === 'string' ? new RegExp(pattern) : pattern;
      const keysToDelete = [];

      for (const key of this.cache.keys()) {
        if (regex.test(key)) {
          keysToDelete.push(key);
        }
      }

      keysToDelete.forEach(key => this.delete(key));
      
      logger.info('Cache pattern invalidation', { 
        pattern: pattern.toString(), 
        invalidatedKeys: keysToDelete.length 
      });
    } catch (error) {
      logger.error('Cache pattern invalidation error', error, { pattern });
    }
  }

  /**
   * Supprime l'entrée la plus ancienne (LRU approximatif)
   */
  _evictOldest() {
    try {
      let oldestKey = null;
      let oldestTime = Date.now();

      for (const [key, item] of this.cache.entries()) {
        if (item.createdAt < oldestTime) {
          oldestTime = item.createdAt;
          oldestKey = key;
        }
      }

      if (oldestKey) {
        this.delete(oldestKey);
        this.stats.evictions++;
        logger.debug('Cache eviction', { evictedKey: oldestKey });
      }
    } catch (error) {
      logger.error('Cache eviction error', error);
    }
  }

  /**
   * Obtient les statistiques du cache
   * @returns {Object} Statistiques
   */
  getStats() {
    const hitRate = this.stats.hits + this.stats.misses > 0 
      ? (this.stats.hits / (this.stats.hits + this.stats.misses) * 100).toFixed(2)
      : 0;

    return {
      ...this.stats,
      hitRate: `${hitRate}%`,
      size: this.cache.size,
      maxSize: this.maxSize
    };
  }

  /**
   * Obtient des informations détaillées sur le cache
   * @returns {Object} Informations détaillées
   */
  getInfo() {
    const items = [];
    
    for (const [key, item] of this.cache.entries()) {
      const age = Date.now() - item.createdAt;
      const remaining = item.ttl > 0 ? Math.max(0, item.ttl - age) : -1;
      
      items.push({
        key,
        age,
        ttl: item.ttl,
        remaining,
        accessCount: item.accessCount,
        size: JSON.stringify(item.value).length
      });
    }

    return {
      stats: this.getStats(),
      items: items.sort((a, b) => b.accessCount - a.accessCount)
    };
  }
}

/**
 * Instance globale du cache
 */
const globalCache = new MemoryCache({
  defaultTTL: 300000, // 5 minutes
  maxSize: 1000
});

/**
 * Middleware de cache pour Express
 * @param {Object} options - Options du cache
 * @returns {Function} Middleware Express
 */
function cacheMiddleware(options = {}) {
  const {
    ttl = 300000, // 5 minutes
    keyGenerator = (req) => `${req.method}:${req.originalUrl}`,
    condition = () => true,
    skipCache = (req) => req.method !== 'GET'
  } = options;

  return (req, res, next) => {
    // Ignorer le cache pour certaines requêtes
    if (skipCache(req) || !condition(req)) {
      return next();
    }

    const cacheKey = keyGenerator(req);
    const cachedResponse = globalCache.get(cacheKey);

    if (cachedResponse) {
      logger.debug('Serving from cache', { cacheKey });
      return res.json(cachedResponse);
    }

    // Intercepter la réponse pour la mettre en cache
    const originalJson = res.json;
    res.json = function(data) {
      // Mettre en cache seulement les réponses de succès
      if (res.statusCode >= 200 && res.statusCode < 300) {
        globalCache.set(cacheKey, data, ttl);
        logger.debug('Response cached', { cacheKey, ttl });
      }
      
      return originalJson.call(this, data);
    };

    next();
  };
}

/**
 * Décorateur pour mettre en cache les résultats de fonction
 * @param {Object} options - Options du cache
 * @returns {Function} Décorateur
 */
function cached(options = {}) {
  const {
    ttl = 300000,
    keyPrefix = 'fn',
    keyGenerator = (...args) => `${keyPrefix}:${JSON.stringify(args)}`
  } = options;

  return function(target, propertyName, descriptor) {
    const method = descriptor.value;

    descriptor.value = async function(...args) {
      const cacheKey = keyGenerator(...args);
      const cached = globalCache.get(cacheKey);

      if (cached !== undefined) {
        logger.debug('Function result from cache', { cacheKey });
        return cached;
      }

      const result = await method.apply(this, args);
      globalCache.set(cacheKey, result, ttl);
      
      logger.debug('Function result cached', { cacheKey, ttl });
      return result;
    };

    return descriptor;
  };
}

module.exports = {
  MemoryCache,
  globalCache,
  cacheMiddleware,
  cached
};
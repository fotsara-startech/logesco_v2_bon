/**
 * Point d'entrée principal pour les modèles et utilitaires LOGESCO
 * Exporte tous les composants nécessaires pour l'API
 */

// Modèles de données
const { ModelFactory } = require('./models');

// Schémas de validation
const schemas = require('./validation/schemas');

// DTOs pour les réponses API
const dto = require('./dto');

// Middleware de validation
const validation = require('./middleware/validation');

// Middleware d'authentification
const authMiddleware = require('./middleware/auth');

// Utilitaires de transformation
const transformers = require('./utils/transformers');

// Configuration de base de données
const databaseManager = require('./config/database');

// Configuration d'environnement
const environment = require('./config/environment');

/**
 * Initialise et retourne tous les services LOGESCO
 * @returns {Promise<Object>} Services initialisés
 */
async function initializeServices() {
  try {
    // Initialiser la base de données
    const prisma = await databaseManager.initialize();
    
    // Créer la factory de modèles
    const models = new ModelFactory(prisma);
    
    // Créer le service d'authentification
    const AuthService = require('./services/auth');
    const authService = new AuthService(models.utilisateur);
    
    console.log('✅ Services LOGESCO initialisés avec succès');
    
    return {
      prisma,
      models,
      schemas,
      dto,
      validation: {
        ...validation,
        ...authMiddleware
      },
      transformers,
      environment,
      databaseManager,
      authService
    };
  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation des services:', error);
    throw error;
  }
}

/**
 * Ferme proprement tous les services
 * @param {Object} services - Services à fermer
 */
async function closeServices(services) {
  try {
    if (services.databaseManager) {
      await services.databaseManager.disconnect();
    }
    console.log('✅ Services LOGESCO fermés proprement');
  } catch (error) {
    console.error('❌ Erreur lors de la fermeture des services:', error);
  }
}

module.exports = {
  initializeServices,
  closeServices,
  // Exports directs pour utilisation individuelle
  ModelFactory,
  schemas,
  dto,
  validation: {
    ...validation,
    ...authMiddleware
  },
  transformers,
  databaseManager,
  environment
};
require('dotenv').config();

const express = require('express');
const environment = require('./config/environment');
const databaseManager = require('./config/database');
const MiddlewareManager = require('./middleware');
const { ModelFactory } = require('./models');
const AuthService = require('./services/auth');
const FinancialMovementService = require('./services/financial-movement');
const MovementCategoryService = require('./services/movement-category');
const FileUploadService = require('./services/file-upload');
const MovementReportService = require('./services/movement-report');
const { createAuthRouter } = require('./routes/auth');
const { createProductRouter } = require('./routes/products');
const categoriesRouter = require('./routes/categories');
const { createSupplierRouter } = require('./routes/suppliers');
const { createCustomerRouter } = require('./routes/customers');
const { createAccountRouter } = require('./routes/accounts');
const { createInventoryRouter } = require('./routes/inventory');
const { createStockInventoryRouter } = require('./routes/stock-inventory');
const { createProcurementRouter } = require('./routes/procurement');
const createSalesRouter = require('./routes/sales');
const { createDiscountReportsRouter } = require('./routes/discount-reports');
const { createExpenseCategoriesRouter } = require('./routes/expense-categories');
const companySettingsRouter = require('./routes/company-settings');
const createPrintingRouter = require('./routes/printing');
const { createFinancialMovementRouter } = require('./routes/financial-movements');
const { createMovementCategoryRouter } = require('./routes/movement-categories');
const { createUserRouter } = require('./routes/users');
const { createRoleRouter } = require('./routes/roles');
const { createDashboardRouter } = require('./routes/dashboard');
const { createCashRegistersRouter } = require('./routes/cash-registers');
const { createCashSessionsRouter } = require('./routes/cash-sessions');
const licensesRouter = require('./routes/licenses');
const { createExpirationDatesRouter } = require('./routes/expiration-dates');

/**
 * Serveur principal LOGESCO API
 * Support hybride local (SQLite) et cloud (PostgreSQL)
 */
class LogescoServer {
  constructor() {
    this.app = express();
    this.server = null;
    this.models = null;
    this.authService = null;
  }

  /**
   * Initialise et démarre le serveur
   */
  async start() {
    try {
      // Afficher la configuration détectée
      environment.logConfiguration();

      // Initialiser la base de données
      const prisma = await databaseManager.initialize();

      // Initialiser les modèles et services
      this.models = new ModelFactory(prisma);
      this.authService = new AuthService(this.models.utilisateur);
      
      // Services pour les mouvements financiers
      this.financialMovementService = new FinancialMovementService(prisma);
      this.movementCategoryService = new MovementCategoryService(prisma);
      this.fileUploadService = new FileUploadService(prisma);
      this.movementReportService = new MovementReportService(prisma, this.financialMovementService);

      // Configurer les middlewares
      this.configureMiddlewares();

      // Configurer les routes
      this.configureRoutes();

      // Démarrer le serveur
      await this.listen();

      console.log('🚀 Serveur LOGESCO API démarré avec succès');
      
      // Afficher les statistiques de la base de données
      const stats = await databaseManager.getStats();
      console.log('📊 Statistiques de la base de données:', stats);

    } catch (error) {
      console.error('❌ Erreur lors du démarrage du serveur:', error.message);
      process.exit(1);
    }
  }

  /**
   * Configure tous les middlewares
   */
  configureMiddlewares() {
    // Middlewares de base (CORS, Helmet, Rate limiting, etc.)
    MiddlewareManager.configureAll(this.app);

    // Middleware personnalisé de logging
    this.app.use(MiddlewareManager.requestLogger);
  }

  /**
   * Configure toutes les routes de l'API
   */
  configureRoutes() {
    const apiVersion = environment.apiVersion;

    // Route de base pour vérifier que l'API fonctionne
    this.app.get('/', (req, res) => {
      res.json({
        success: true,
        message: 'LOGESCO API v2 - Serveur opérationnel',
        version: apiVersion,
        environment: environment.isLocal ? 'local' : 'cloud',
        database: environment.databaseConfig.provider,
        timestamp: new Date().toISOString()
      });
    });

    // Route pour servir les fichiers uploadés
    this.app.use('/uploads', express.static(require('path').join(__dirname, '../uploads')));

    // Routes API principales
    this.app.use(`/api/${apiVersion}/auth`, createAuthRouter(this.authService));
    this.app.use(`/api/${apiVersion}/products`, createProductRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/categories`, categoriesRouter);
    this.app.use(`/api/${apiVersion}/suppliers`, createSupplierRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/customers`, createCustomerRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/accounts`, createAccountRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/procurement`, createProcurementRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/sales`, createSalesRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/discount-reports`, createDiscountReportsRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/expense-categories`, createExpenseCategoriesRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/inventory`, createInventoryRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/stock-inventory`, createStockInventoryRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/company-settings`, companySettingsRouter);
    this.app.use(`/api/${apiVersion}/printing`, createPrintingRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));

    // Routes pour les mouvements financiers
    this.app.use(`/api/${apiVersion}/financial-movements`, createFinancialMovementRouter({
      authService: this.authService,
      financialMovementService: this.financialMovementService,
      fileUploadService: this.fileUploadService,
      movementReportService: this.movementReportService
    }));
    
    this.app.use(`/api/${apiVersion}/movement-categories`, createMovementCategoryRouter({
      authService: this.authService,
      movementCategoryService: this.movementCategoryService
    }));

    // Routes pour les utilisateurs et rôles
    this.app.use(`/api/${apiVersion}/users`, createUserRouter({
      authService: this.authService
    }));
    
    this.app.use(`/api/${apiVersion}/roles`, createRoleRouter({
      authService: this.authService
    }));

    this.app.use(`/api/${apiVersion}/dashboard`, createDashboardRouter({
      authService: this.authService
    }));

    // Routes pour les caisses et sessions
    this.app.use(`/api/${apiVersion}/cash-registers`, createCashRegistersRouter({
      prisma: this.models.prisma,
      authService: this.authService
    }));
    
    this.app.use(`/api/${apiVersion}/cash-sessions`, createCashSessionsRouter({
      prisma: this.models.prisma,
      authService: this.authService
    }));

    // Routes pour les licences
    this.app.use(`/api/${apiVersion}/licenses`, licensesRouter);

    // Routes pour les dates de péremption
    this.app.use(`/api/${apiVersion}/expiration-dates`, createExpirationDatesRouter({
      prisma: this.models.prisma,
      authService: this.authService
    }));

    // Route pour les statistiques de la base de données
    this.app.get(`/api/${apiVersion}/stats`, async (req, res) => {
      try {
        const stats = await databaseManager.getStats();
        res.json({
          success: true,
          data: stats
        });
      } catch (error) {
        res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de la récupération des statistiques',
            code: 'STATS_ERROR'
          }
        });
      }
    });

    // Middleware pour les routes non trouvées
    this.app.use('*', MiddlewareManager.notFound);

    // Middleware de gestion d'erreurs (doit être en dernier)
    this.app.use(MiddlewareManager.errorHandler);
  }

  /**
   * Crée un routeur placeholder pour les modules non encore implémentés
   * @param {string} moduleName - Nom du module
   * @returns {Router}
   */
  createPlaceholderRouter(moduleName) {
    const router = express.Router();

    router.all('*', (req, res) => {
      res.json({
        success: true,
        message: `Module ${moduleName} - Endpoint disponible mais pas encore implémenté`,
        module: moduleName,
        method: req.method,
        path: req.path,
        timestamp: new Date().toISOString(),
        note: 'Ce module sera implémenté dans les prochaines tâches'
      });
    });

    return router;
  }

  /**
   * Démarre l'écoute du serveur
   */
  async listen() {
    return new Promise((resolve, reject) => {
      this.server = this.app.listen(environment.port, (err) => {
        if (err) {
          reject(err);
        } else {
          console.log(`🌐 Serveur en écoute sur le port ${environment.port}`);
          console.log(`📡 API disponible sur: http://localhost:${environment.port}/api/${environment.apiVersion}`);
          console.log(`🏥 Health check: http://localhost:${environment.port}/health`);
          resolve();
        }
      });
    });
  }

  /**
   * Arrête le serveur proprement
   */
  async stop() {
    try {
      if (this.server) {
        await new Promise((resolve) => {
          this.server.close(resolve);
        });
        console.log('🛑 Serveur arrêté');
      }

      await databaseManager.disconnect();
      console.log('👋 Arrêt complet du serveur LOGESCO API');
    } catch (error) {
      console.error('❌ Erreur lors de l\'arrêt du serveur:', error.message);
    }
  }
}

// Gestion des signaux d'arrêt
const server = new LogescoServer();

process.on('SIGTERM', async () => {
  console.log('📨 Signal SIGTERM reçu');
  await server.stop();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('📨 Signal SIGINT reçu');
  await server.stop();
  process.exit(0);
});

// Gestion des erreurs non capturées
process.on('uncaughtException', (error) => {
  console.error('💥 Exception non capturée:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Promesse rejetée non gérée:', reason);
  process.exit(1);
});

// Démarrer le serveur
if (require.main === module) {
  server.start();
}

module.exports = server;
require('dotenv').config();

// ── Logging vers fichier dès le démarrage ─────────────────────────────────
const fs   = require('fs');
const path = require('path');
const _logDir  = process.env.LOGESCO_DATA_DIR
  ? path.join(process.env.LOGESCO_DATA_DIR, 'logs')
  : path.join(__dirname, '../logs');
if (!fs.existsSync(_logDir)) { try { fs.mkdirSync(_logDir, { recursive: true }); } catch(_){} }
const _logFile = path.join(_logDir, 'backend-startup.log');
const _logStream = fs.createWriteStream(_logFile, { flags: 'a' });
const _origLog   = console.log.bind(console);
const _origWarn  = console.warn.bind(console);
const _origError = console.error.bind(console);
function _log(level, args) {
  const line = `[${new Date().toISOString()}] [${level}] ${args.map(a => typeof a === 'object' ? JSON.stringify(a) : String(a)).join(' ')}\n`;
  _logStream.write(line);
}
console.log   = (...a) => { _origLog(...a);   _log('INFO',  a); };
console.warn  = (...a) => { _origWarn(...a);  _log('WARN',  a); };
console.error = (...a) => { _origError(...a); _log('ERROR', a); };
console.log(`=== LOGESCO Backend démarrage ${new Date().toISOString()} ===`);
console.log(`LOGESCO_DATA_DIR: ${process.env.LOGESCO_DATA_DIR || '(non défini)'}`);
console.log(`DATABASE_URL: ${process.env.DATABASE_URL || '(non défini)'}`);
console.log(`NODE_ENV: ${process.env.NODE_ENV || '(non défini)'}`);
// ──────────────────────────────────────────────────────────────────────────

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
const { createProformaRouter } = require('./routes/proformas');
const { createBoutiquesRouter } = require('./routes/boutiques');

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
   * Seed automatique au premier démarrage.
   * Crée admin + caisse principale si la DB est vide.
   */
  async _runAutoSeed(prisma) {
    try {
      const userCount = await prisma.utilisateur.count();
      const bcrypt = require('bcryptjs');

      if (userCount === 0) {
        console.log('🌱 Première installation détectée - Initialisation des données...');

        // Rôle admin
        const adminRole = await prisma.userRole.create({
          data: {
            nom: 'ADMIN',
            displayName: 'Administrateur',
            isAdmin: true,
            privileges: JSON.stringify({
              dashboard: { view: true },
              sales: { view: true, create: true, edit: true, delete: true },
              products: { view: true, create: true, edit: true, delete: true },
              inventory: { view: true, create: true, edit: true, delete: true },
              customers: { view: true, create: true, edit: true, delete: true },
              suppliers: { view: true, create: true, edit: true, delete: true },
              procurement: { view: true, create: true, edit: true, delete: true },
              expenses: { view: true, create: true, edit: true, delete: true },
              reports: { view: true, create: true, edit: true, delete: true },
              users: { view: true, create: true, edit: true, delete: true },
              roles: { view: true, create: true, edit: true, delete: true },
              settings: { view: true, create: true, edit: true, delete: true },
              cashRegister: { view: true, create: true, edit: true, delete: true },
              financialMovements: { view: true, create: true, edit: true, delete: true }
            })
          }
        });

        // Utilisateur admin
        const hashedPassword = await bcrypt.hash('admin123', 10);
        await prisma.utilisateur.create({
          data: {
            nomUtilisateur: 'admin',
            motDePasseHash: hashedPassword,
            email: 'admin@logesco.local',
            roleId: adminRole.id,
            isActive: true
          }
        });

        // Paramètres entreprise
        await prisma.parametresEntreprise.create({
          data: {
            nomEntreprise: 'Mon Entreprise',
            adresse: '',
            telephone: '',
            email: 'contact@entreprise.com',
            nuiRccm: '',
            localisation: ''
          }
        });

        console.log('✅ Données initiales créées (admin / admin123)');
      } else {
        console.log('✅ Base de données déjà initialisée');
      }

      // ── Toujours vérifier/créer la boutique principale ──────────────────
      let boutiquePrincipale = await prisma.boutique.findFirst({ where: { estPrincipale: true } });
      if (!boutiquePrincipale) {
        console.log('🏪 Création de la boutique principale manquante...');
        boutiquePrincipale = await prisma.boutique.create({
          data: {
            nom: 'Boutique Principale',
            description: 'Boutique principale du système',
            estPrincipale: true,
            isActive: true
          }
        });
        console.log(`✅ Boutique principale créée (ID: ${boutiquePrincipale.id})`);
      } else {
        console.log(`✅ Boutique principale existante (ID: ${boutiquePrincipale.id})`);
      }

      // ── Toujours vérifier/créer la caisse principale ────────────────────
      let caissePrincipale = await prisma.cashRegister.findFirst({ where: { nom: 'Caisse Principale' } });
      if (!caissePrincipale) {
        console.log('💰 Création de la caisse principale manquante...');
        caissePrincipale = await prisma.cashRegister.create({
          data: {
            nom: 'Caisse Principale',
            description: 'Caisse principale du système',
            isActive: true,
            soldeActuel: 0,
            soldeInitial: 0,
            boutiqueId: boutiquePrincipale.id
          }
        });
        console.log(`✅ Caisse principale créée (ID: ${caissePrincipale.id})`);
      } else if (!caissePrincipale.boutiqueId) {
        // Lier la caisse existante à la boutique principale si pas encore fait
        await prisma.cashRegister.update({
          where: { id: caissePrincipale.id },
          data: { boutiqueId: boutiquePrincipale.id }
        });
        console.log(`✅ Caisse principale liée à la boutique principale`);
      }

      // ── Assigner l'admin à la boutique principale si pas encore fait ────
      const adminUser = await prisma.utilisateur.findFirst({ where: { nomUtilisateur: 'admin' } });
      if (adminUser) {
        const existingAssignment = await prisma.userBoutiqueAssignment.findFirst({
          where: { utilisateurId: adminUser.id, boutiqueId: boutiquePrincipale.id }
        });
        if (!existingAssignment) {
          const adminRole = await prisma.userRole.findFirst({ where: { isAdmin: true } });
          await prisma.userBoutiqueAssignment.create({
            data: {
              utilisateurId: adminUser.id,
              boutiqueId: boutiquePrincipale.id,
              roleId: adminRole?.id || null,
              isActive: true
            }
          });
          console.log('✅ Admin assigné à la boutique principale');
        }
      }

      // ── Migration des données existantes sans boutiqueId ────────────────
      await this._migrateExistingDataToBoutique(prisma, boutiquePrincipale.id);

    } catch (err) {
      console.warn('⚠️  Auto-seed échoué (non bloquant):', err.message);
    }
  }

  /**
   * Migre les données existantes sans boutiqueId vers la boutique principale.
   * S'exécute à chaque démarrage mais ne touche que les lignes sans boutiqueId.
   */
  async _migrateExistingDataToBoutique(prisma, boutiquePrincipaleId) {
    try {
      console.log(`🔄 Migration des données existantes vers boutique principale (ID: ${boutiquePrincipaleId})...`);

      const tables = [
        { name: 'vente',              model: prisma.vente },
        { name: 'cashRegister',       model: prisma.cashRegister },
        { name: 'cashSession',        model: prisma.cashSession },
        { name: 'cashMovement',       model: prisma.cashMovement },
        { name: 'mouvementStock',     model: prisma.mouvementStock },
        { name: 'financialMovement',  model: prisma.financialMovement },
        { name: 'commandeApprovisionnement', model: prisma.commandeApprovisionnement },
        { name: 'stockInventory',     model: prisma.stockInventory },
        { name: 'transactionCompte',  model: prisma.transactionCompte },
        { name: 'venteProforma',      model: prisma.venteProforma },
        { name: 'datePeremption',     model: prisma.datePeremption },
      ];

      for (const { name, model } of tables) {
        try {
          const result = await model.updateMany({
            where: { boutiqueId: null },
            data: { boutiqueId: boutiquePrincipaleId }
          });
          if (result.count > 0) {
            console.log(`  ✅ ${name}: ${result.count} ligne(s) migrée(s)`);
          }
        } catch (e) {
          // Certaines tables peuvent ne pas avoir boutiqueId, on ignore
        }
      }

      console.log('✅ Migration des données existantes terminée');
    } catch (err) {
      console.warn('⚠️  Migration données existantes échouée (non bloquant):', err.message);
    }
  }

  /**
   * Applique les migrations Prisma automatiquement au démarrage.
   * Utilise node.exe portable + prisma CLI avec DATABASE_URL explicite.
   */
  async _runAutoMigration() {
    const { execSync } = require('child_process');
    const path = require('path');
    const fs = require('fs');
    const environment = require('./config/environment');

    try {
      console.log('🔄 Vérification des migrations de base de données...');

      const backendDir = path.join(__dirname, '..');
      
      // Choisir le bon schema selon l'environnement
      const schemaFile = environment.isCloud ? 'schema.postgresql.prisma' : 'schema.prisma';
      let schemaPath = path.join(backendDir, 'prisma', schemaFile);
      
      if (!fs.existsSync(schemaPath)) {
        console.log(`⚠️  ${schemaFile} introuvable, migration ignorée`);
        return;
      }

      // En cloud, pas besoin de migration automatique (déjà fait au build)
      if (environment.isCloud) {
        console.log('☁️  Environnement cloud détecté, migrations déjà appliquées au build');
        return;
      }

      // Le reste du code pour l'environnement local uniquement
      const prismaCmdWin  = path.join(backendDir, 'node_modules/.bin/prisma.cmd');
      const prismaCmdUnix = path.join(backendDir, 'node_modules/.bin/prisma');

      const dbUrl = process.env.DATABASE_URL || (() => {
        const dataDir = process.env.LOGESCO_DATA_DIR || backendDir;
        const dbPath  = path.join(dataDir, 'database', 'logesco.db').replace(/\\/g, '/');
        return `file:${dbPath}`;
      })();

      const nodeExe = (() => {
        const portable = path.join(backendDir, 'node.exe');
        return fs.existsSync(portable) ? portable : 'node';
      })();

      let cmd;
      if (fs.existsSync(prismaCmdWin)) {
        const prismaJs = path.join(__dirname, '../node_modules/prisma/build/index.js');
        if (fs.existsSync(prismaJs)) {
          cmd = `"${nodeExe}" "${prismaJs}" db push --accept-data-loss --schema="${schemaPath}"`;
        } else {
          cmd = `"${prismaCmdWin}" db push --accept-data-loss --schema="${schemaPath}"`;
        }
      } else if (fs.existsSync(prismaCmdUnix)) {
        cmd = `"${prismaCmdUnix}" db push --accept-data-loss --schema="${schemaPath}"`;
      } else {
        cmd = `"${nodeExe}" -e "require('./node_modules/prisma/build/index.js')" db push --accept-data-loss --schema="${schemaPath}"`;
      }

      execSync(cmd, {
        stdio: 'pipe',
        timeout: 120000,
        cwd: backendDir,
        env: { ...process.env, DATABASE_URL: dbUrl },
      });
      console.log('✅ Migrations appliquées');
    } catch (err) {
      console.warn('⚠️  Migration automatique échouée (non bloquant):', err.message);
    }
  }

  /**
   * Initialise et démarre le serveur
   */
  async start() {
    try {
      // Afficher la configuration détectée
      environment.logConfiguration();

      // Appliquer les migrations Prisma automatiquement (MAJ client)
      await this._runAutoMigration();

      // Initialiser la base de données
      const prisma = await databaseManager.initialize();

      // Seed automatique si la base est vide (première installation)
      await this._runAutoSeed(prisma);

      // Initialiser le service de synchronisation cloud (si CLOUD_DB_URL défini)
      const syncService = require('./services/sync-service');
      await syncService.initialize(prisma);
      this.syncService = syncService;
      const syncStatus = syncService.getStatus();
      console.log(`🔄 Mode sync: ${syncStatus.mode}`);

      // Exposer prisma dans app.locals pour le sync middleware
      this.app.locals.prisma = prisma;

      // Initialiser les modèles et services
      this.models = new ModelFactory(prisma);
      this.authService = new AuthService(this.models.utilisateur);
      
      // Services pour les mouvements financiers
      this.financialMovementService = new FinancialMovementService(prisma, syncService);
      this.movementCategoryService = new MovementCategoryService(prisma);
      this.fileUploadService = new FileUploadService(prisma);
      this.movementReportService = new MovementReportService(prisma, this.financialMovementService);

      // Configurer les middlewares
      this.configureMiddlewares();

      // Middleware de synchronisation cloud (après auth, avant routes)
      const syncMiddleware = require('./middleware/sync-middleware');
      this.app.use('/api', syncMiddleware);

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

    // Route health check (utilisée par BackendService Flutter pour détecter le démarrage)
    this.app.get('/health', (req, res) => {
      const syncService = require('./services/sync-service');
      res.json({
        status: 'ok',
        uptime: process.uptime(),
        sync: syncService.getStatus()
      });
    });

    // Route debug — retourne l'état de la DB et les variables d'env clés
    this.app.get('/debug', async (req, res) => {
      try {
        const dbUrl = process.env.DATABASE_URL || '(non défini)';
        const dataDir = process.env.LOGESCO_DATA_DIR || '(non défini)';
        let userCount = -1;
        let dbError = null;
        try {
          userCount = await this.models?.prisma?.utilisateur?.count() ?? -1;
        } catch(e) { dbError = e.message; }
        // Lire les dernières lignes du log
        let lastLogs = '';
        try {
          const logPath = require('path').join(
            process.env.LOGESCO_DATA_DIR || require('path').join(__dirname, '..'),
            'logs', 'backend-startup.log'
          );
          if (require('fs').existsSync(logPath)) {
            const content = require('fs').readFileSync(logPath, 'utf8');
            lastLogs = content.split('\n').slice(-30).join('\n');
          }
        } catch(_) {}
        res.json({ DATABASE_URL: dbUrl, LOGESCO_DATA_DIR: dataDir, userCount, dbError, lastLogs });
      } catch(e) {
        res.status(500).json({ error: e.message });
      }
    });

    // Route pour servir les fichiers uploadés
    // En production (pkg), les uploads sont dans DATA_DIR
    const uploadsPath = process.env.LOGESCO_DATA_DIR
      ? require('path').join(process.env.LOGESCO_DATA_DIR, 'uploads')
      : require('path').join(__dirname, '../uploads');
    this.app.use('/uploads', express.static(uploadsPath));

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
    this.app.use(`/api/${apiVersion}/proformas`, createProformaRouter({ 
      prisma: this.models.prisma,
      authService: this.authService,
    }));
    this.app.use(`/api/${apiVersion}/discount-reports`, createDiscountReportsRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/expense-categories`, createExpenseCategoriesRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma,
      syncService: this.syncService
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

    // Routes multi-boutique
    this.app.use(`/api/${apiVersion}/boutiques`, createBoutiquesRouter({
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
    const host = process.env.HOST || '0.0.0.0';
    return new Promise((resolve, reject) => {
      this.server = this.app.listen(environment.port, host, (err) => {
        if (err) {
          reject(err);
        } else {
          console.log(`🌐 Serveur en écoute sur ${host}:${environment.port}`);
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
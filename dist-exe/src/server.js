require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

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
const { createSyncRouter } = require('./routes/sync');

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
      // Vérifications parallèles pour éviter les allers-retours séquentiels
      const [userCount, boutiquePrincipale] = await Promise.all([
        prisma.utilisateur.count(),
        prisma.boutique.findFirst({ where: { estPrincipale: true } })
      ]);

      const bcrypt = require('bcryptjs');

      if (userCount === 0) {
        console.log('🌱 Première installation — initialisation des données...');

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

        // Admin + paramètres entreprise en parallèle
        const hashedPassword = await bcrypt.hash('admin123', 10);
        await Promise.all([
          prisma.utilisateur.create({
            data: {
              nomUtilisateur: 'admin',
              motDePasseHash: hashedPassword,
              email: 'admin@logesco.local',
              roleId: adminRole.id,
              isActive: true
            }
          }),
          prisma.parametresEntreprise.create({
            data: {
              nomEntreprise: 'Mon Entreprise',
              adresse: '',
              telephone: '',
              email: 'contact@entreprise.com',
              nuiRccm: '',
              localisation: ''
            }
          })
        ]);

        console.log('✅ Données initiales créées (admin / admin123)');
      }

      // ── Boutique principale ────────────────────────────────────────────────
      let boutique = boutiquePrincipale;
      if (!boutique) {
        console.log('🏪 Création de la boutique principale...');
        boutique = await prisma.boutique.create({
          data: {
            nom: 'Boutique Principale',
            description: 'Boutique principale du système',
            estPrincipale: true,
            isActive: true
          }
        });
        console.log(`✅ Boutique principale créée (ID: ${boutique.id})`);
      }

      // ── Caisse principale + assignation admin en parallèle ─────────────────
      const [caissePrincipale, adminUser] = await Promise.all([
        prisma.cashRegister.findFirst({ where: { nom: 'Caisse Principale' } }),
        prisma.utilisateur.findFirst({ where: { nomUtilisateur: 'admin' } })
      ]);

      const tasks = [];

      if (!caissePrincipale) {
        tasks.push(
          prisma.cashRegister.create({
            data: {
              nom: 'Caisse Principale',
              description: 'Caisse principale du système',
              isActive: true,
              soldeActuel: 0,
              soldeInitial: 0,
              boutiqueId: boutique.id
            }
          }).then(c => console.log(`✅ Caisse principale créée (ID: ${c.id})`))
        );
      } else if (!caissePrincipale.boutiqueId) {
        tasks.push(
          prisma.cashRegister.update({
            where: { id: caissePrincipale.id },
            data: { boutiqueId: boutique.id }
          }).then(() => console.log('✅ Caisse principale liée à la boutique'))
        );
      }

      if (adminUser) {
        tasks.push(
          prisma.userBoutiqueAssignment.findFirst({
            where: { utilisateurId: adminUser.id, boutiqueId: boutique.id }
          }).then(async existing => {
            if (!existing) {
              const adminRole = await prisma.userRole.findFirst({ where: { isAdmin: true } });
              await prisma.userBoutiqueAssignment.create({
                data: {
                  utilisateurId: adminUser.id,
                  boutiqueId: boutique.id,
                  roleId: adminRole?.id || null,
                  isActive: true
                }
              });
              console.log('✅ Admin assigné à la boutique principale');
            }
          })
        );
      }

      await Promise.all(tasks);

      // ── Migrations de données (différées, non bloquantes) ─────────────────
      setImmediate(() => {
        this._migrateExistingDataToBoutique(prisma, boutique.id).catch(() => {});
        this._migrateStockToBoutique(prisma, boutique.id).catch(() => {});
        this._fixOperationLogSchema(prisma).catch(() => {});
      });

    } catch (err) {
      console.warn('⚠️  Auto-seed échoué (non bloquant):', err.message);
    }
  }

  /**
   * Recrée la table operation_log si son id n'est pas AUTOINCREMENT.
   * Problème fréquent sur les installations existantes créées avant la migration.
   */
  async _fixOperationLogSchema(prisma) {
    try {
      // Vérifier le schéma de la table
      const tableInfo = await prisma.$queryRawUnsafe(`PRAGMA table_info(operation_log)`);
      if (!tableInfo || tableInfo.length === 0) {
        // Table absente — elle sera créée par prisma db push, rien à faire
        return;
      }

      // Vérifier si la table existe dans sqlite_master avec AUTOINCREMENT
      const schema = await prisma.$queryRawUnsafe(
        `SELECT sql FROM sqlite_master WHERE type='table' AND name='operation_log'`
      );
      const tableSql = schema[0]?.sql || '';
      if (tableSql.toUpperCase().includes('AUTOINCREMENT')) {
        // Déjà correct
        return;
      }

      console.log('🔧 Correction du schéma operation_log (ajout AUTOINCREMENT)...');

      // Sauvegarder les données existantes
      const existing = await prisma.$queryRawUnsafe(`SELECT * FROM operation_log`);

      // Recréer la table avec le bon schéma
      await prisma.$executeRawUnsafe(`DROP TABLE IF EXISTS operation_log`);
      await prisma.$executeRawUnsafe(`
        CREATE TABLE "operation_log" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "operation_id" TEXT NOT NULL UNIQUE,
          "operation_type" TEXT NOT NULL,
          "table_name" TEXT NOT NULL,
          "record_id" INTEGER,
          "data" TEXT,
          "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          "synced_at" DATETIME,
          "status" TEXT NOT NULL DEFAULT 'pending',
          "error_message" TEXT,
          "device_id" TEXT,
          "user_id" INTEGER
        )
      `);
      await prisma.$executeRawUnsafe(`CREATE INDEX IF NOT EXISTS "operation_log_status_timestamp" ON "operation_log"("status", "timestamp")`);
      await prisma.$executeRawUnsafe(`CREATE INDEX IF NOT EXISTS "operation_log_table_timestamp" ON "operation_log"("table_name", "timestamp")`);
      await prisma.$executeRawUnsafe(`CREATE UNIQUE INDEX IF NOT EXISTS "operation_log_operation_id" ON "operation_log"("operation_id")`);

      // Réinsérer les données sauvegardées (statut 'synced' seulement pour ne pas re-syncer)
      let restored = 0;
      for (const row of existing) {
        try {
          await prisma.$executeRawUnsafe(
            `INSERT OR IGNORE INTO operation_log (operation_id, operation_type, table_name, record_id, data, timestamp, synced_at, status, error_message, device_id, user_id)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            row.operation_id, row.operation_type, row.table_name, row.record_id,
            row.data, row.timestamp, row.synced_at, row.status,
            row.error_message, row.device_id, row.user_id
          );
          restored++;
        } catch (_) {}
      }

      console.log(`✅ operation_log recréé avec AUTOINCREMENT (${restored}/${existing.length} entrées restaurées)`);
    } catch (err) {
      console.warn('⚠️  _fixOperationLogSchema échoué (non bloquant):', err.message);
    }
  }

  /**
   * Migre les données existantes sans boutiqueId vers la boutique principale.
   * S'exécute à chaque démarrage mais ne touche que les lignes sans boutiqueId.
   */
  async _migrateExistingDataToBoutique(prisma, boutiquePrincipaleId) {
    try {
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

      // Toutes les migrations en parallèle
      const results = await Promise.allSettled(
        tables.map(({ name, model }) =>
          model.updateMany({ where: { boutiqueId: null }, data: { boutiqueId: boutiquePrincipaleId } })
            .then(r => { if (r.count > 0) console.log(`  ✅ ${name}: ${r.count} ligne(s) migrée(s)`); })
        )
      );

      const errors = results.filter(r => r.status === 'rejected');
      if (errors.length === 0) {
        console.log('✅ Migration des données existantes terminée');
      }
    } catch (err) {
      console.warn('⚠️  Migration données existantes échouée (non bloquant):', err.message);
    }
  }

  /**
   * Migre les quantités de stock de l'ancienne table `stock` vers `stock_boutiques`.
   * S'exécute uniquement si stock_boutiques est vide ET que stock contient des données.
   * Cas typique : mise à jour depuis une version antérieure.
   */
  async _migrateStockToBoutique(prisma, boutiquePrincipaleId) {
    try {
      // Vérifier si stock_boutiques est déjà alimenté pour cette boutique
      const stockBoutiqueCount = await prisma.stockBoutique.count({
        where: { boutiqueId: boutiquePrincipaleId }
      });

      if (stockBoutiqueCount > 0) {
        console.log(`✅ stock_boutiques déjà alimenté (${stockBoutiqueCount} entrées) - migration ignorée`);
        return;
      }

      // Vérifier si l'ancienne table stock a des données
      const ancienStocks = await prisma.stock.findMany();
      if (ancienStocks.length === 0) {
        console.log('ℹ️  Aucune donnée dans l\'ancienne table stock - migration ignorée');
        return;
      }

      console.log(`🔄 Migration stock → stock_boutiques: ${ancienStocks.length} produit(s) à migrer...`);
      let migrated = 0, skipped = 0;

      for (const stock of ancienStocks) {
        if (stock.quantiteDisponible <= 0 && stock.quantiteReservee <= 0) {
          skipped++;
          continue;
        }
        try {
          await prisma.stockBoutique.upsert({
            where: { boutiqueId_produitId: { boutiqueId: boutiquePrincipaleId, produitId: stock.produitId } },
            update: {
              quantiteDisponible: stock.quantiteDisponible,
              quantiteReservee: stock.quantiteReservee,
              derniereMaj: new Date()
            },
            create: {
              boutiqueId: boutiquePrincipaleId,
              produitId: stock.produitId,
              quantiteDisponible: stock.quantiteDisponible,
              quantiteReservee: stock.quantiteReservee,
              derniereMaj: new Date()
            }
          });
          migrated++;
        } catch (e) {
          console.warn(`  ⚠️  Produit ID ${stock.produitId}: ${e.message}`);
        }
      }

      console.log(`✅ Migration stock terminée: ${migrated} migré(s), ${skipped} ignoré(s) (stock=0)`);
    } catch (err) {
      console.warn('⚠️  Migration stock→stock_boutiques échouée (non bloquant):', err.message);
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
      const backendDir = path.join(__dirname, '..');

      // En cloud, migrations déjà appliquées au build
      if (environment.isCloud) {
        console.log('☁️  Environnement cloud — migrations ignorées');
        return;
      }

      const dbUrl = process.env.DATABASE_URL || (() => {
        const dataDir = process.env.LOGESCO_DATA_DIR || backendDir;
        const dbPath  = path.join(dataDir, 'database', 'logesco.db').replace(/\\/g, '/');
        return `file:${dbPath}`;
      })();

      // ── FAST PATH : DB existante → skip prisma db push (économise 5-20s) ──
      if (dbUrl.startsWith('file:')) {
        const dbFilePath = dbUrl.replace(/^file:/, '').split('?')[0];
        if (fs.existsSync(dbFilePath) && fs.statSync(dbFilePath).size > 0) {
          try {
            // Vérification rapide via sqlite3 natif (si dispo) ou lecture binaire
            const header = Buffer.alloc(100);
            const fd = fs.openSync(dbFilePath, 'r');
            fs.readSync(fd, header, 0, 100, 0);
            fs.closeSync(fd);
            // Les 16 premiers octets d'une DB SQLite valide = "SQLite format 3\0"
            if (header.slice(0, 15).toString('ascii') === 'SQLite format 3') {
              console.log('✅ DB existante — migration prisma ignorée (démarrage rapide)');
              return;
            }
          } catch (_) { /* continue vers slow path */ }
        }
      }

      // ── SLOW PATH : première installation ou DB absente/corrompue ─────────
      const schemaFile = environment.isCloud ? 'schema.postgresql.prisma' : 'schema.prisma';
      const schemaPath = path.join(backendDir, 'prisma', schemaFile);

      if (!fs.existsSync(schemaPath)) {
        console.log(`⚠️  ${schemaFile} introuvable, migration ignorée`);
        return;
      }

      console.log('🔄 Première installation — application des migrations...');

      const prismaCmdWin  = path.join(backendDir, 'node_modules/.bin/prisma.cmd');
      const prismaCmdUnix = path.join(backendDir, 'node_modules/.bin/prisma');

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

      // Appliquer les migrations Prisma (skip si DB existe déjà → démarrage rapide)
      await this._runAutoMigration();

      // Initialiser la base de données
      const prisma = await databaseManager.initialize();

      // Seed automatique si la base est vide (première installation)
      await this._runAutoSeed(prisma);

      // Initialiser les modèles et services en premier → serveur prêt le plus vite possible
      this.models = new ModelFactory(prisma);
      this.authService = new AuthService(this.models.utilisateur);

      this.financialMovementService = new FinancialMovementService(prisma, null);
      this.movementCategoryService = new MovementCategoryService(prisma);
      this.fileUploadService = new FileUploadService(prisma);
      this.movementReportService = new MovementReportService(prisma, this.financialMovementService);

      // Exposer prisma dans app.locals pour le sync middleware
      this.app.locals.prisma = prisma;

      // Configurer les middlewares
      this.configureMiddlewares();

      // Middleware de synchronisation cloud (après auth, avant routes)
      const syncMiddleware = require('./middleware/sync-middleware');
      this.app.use('/api', syncMiddleware(prisma));

      // Configurer les routes
      this.configureRoutes();

      // Démarrer le serveur HTTP → /health répond dès ici
      await this.listen();
      console.log('🚀 Serveur LOGESCO API démarré avec succès');

      // ── Tâches différées (non bloquantes pour le démarrage) ───────────────
      setImmediate(async () => {
        try {
          // Sync service — pas nécessaire avant que le serveur soit prêt
          const databaseUrl = process.env.DATABASE_URL || '';
          const isCloudOnly = databaseUrl.startsWith('postgresql://') || databaseUrl.startsWith('postgres://');

          if (!isCloudOnly) {
            const syncService = require('./services/sync-service');
            await syncService.initialize(prisma);
            this.syncService = syncService;
            // Rendre syncService accessible dynamiquement aux routes via app.locals
            this.app.locals.syncService = syncService;
            // Mettre à jour les services qui en dépendent
            this.financialMovementService = new FinancialMovementService(prisma, syncService);
            this.movementReportService = new MovementReportService(prisma, this.financialMovementService);
            console.log(`🔄 Mode sync: ${syncService.getStatus().mode}`);
          } else {
            console.log('🔄 Mode sync: disabled (cloud-only)');
          }

          // Stats DB (non bloquant)
          const stats = await databaseManager.getStats();
          console.log('📊 Stats DB:', stats);
        } catch (e) {
          console.warn('⚠️  Initialisation différée échouée (non bloquant):', e.message);
        }
      });

    } catch (error) {
      if (error.code === 'EADDRINUSE') {
        console.error(`❌ Port ${environment.port} occupé. Nouvelle tentative dans 3 secondes...`);
        setTimeout(async () => {
          try {
            await this.listen();
            console.log('🚀 Serveur LOGESCO API démarré avec succès (après retry)');
          } catch (retryErr) {
            console.error('❌ Échec du retry. Arrêtez manuellement le process qui occupe le port:', environment.port);
            console.error('   Windows: netstat -aon | findstr :' + environment.port + '  puis: taskkill /f /pid <PID>');
            process.exit(1);
          }
        }, 3000);
      } else {
        console.error('❌ Erreur lors du démarrage du serveur:', error.message);
        process.exit(1);
      }
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
      prisma: this.models.prisma,
      syncService: this.syncService
    }));
    this.app.use(`/api/${apiVersion}/categories`, categoriesRouter);
    this.app.use(`/api/${apiVersion}/suppliers`, createSupplierRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma,
      syncService: this.syncService
    }));
    this.app.use(`/api/${apiVersion}/customers`, createCustomerRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma,
      syncService: this.syncService
    }));
    this.app.use(`/api/${apiVersion}/accounts`, createAccountRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma,
      syncService: this.syncService
    }));
    this.app.use(`/api/${apiVersion}/procurement`, createProcurementRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma 
    }));
    this.app.use(`/api/${apiVersion}/sales`, createSalesRouter({ 
      ...this.models, 
      authService: this.authService,
      prisma: this.models.prisma,
      syncService: this.syncService
    }));
    this.app.use(`/api/${apiVersion}/proformas`, createProformaRouter({ 
      prisma: this.models.prisma,
      authService: this.authService,
      syncService: this.syncService
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
      prisma: this.models.prisma,
      syncService: this.syncService
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
      authService: this.authService,
      syncService: this.syncService
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
      authService: this.authService,
      syncService: this.syncService
    }));
    
    this.app.use(`/api/${apiVersion}/cash-sessions`, createCashSessionsRouter({
      prisma: this.models.prisma,
      authService: this.authService,
      syncService: this.syncService
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
      authService: this.authService,
      syncService: this.syncService
    }));

    // Routes de synchronisation (Type 3 — hybride local + Neon)
    this.app.use(`/api/${apiVersion}/sync`, createSyncRouter({
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

      this.server.on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
          console.error(`❌ Port ${environment.port} déjà utilisé. Tentative de libération...`);
          // Tenter de tuer le process occupant le port via une commande système
          const { exec } = require('child_process');
          const isWin = process.platform === 'win32';
          const killCmd = isWin
            ? `for /f "tokens=5" %a in ('netstat -aon ^| findstr :${environment.port}') do taskkill /f /pid %a`
            : `fuser -k ${environment.port}/tcp`;

          exec(killCmd, (killErr) => {
            if (killErr) {
              console.error(`⚠️  Impossible de libérer le port automatiquement. Relancez le backend manuellement après avoir arrêté l'ancien process.`);
            } else {
              console.log(`✅ Port libéré, nouvelle tentative de démarrage dans 2s...`);
            }
            reject(err);
          });
        } else {
          reject(err);
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
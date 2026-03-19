/**
 * Serveur Express simplifié pour le mode standalone
 * Évite les dépendances complexes et se concentre sur les fonctionnalités essentielles
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 8080;

// Middlewares de base
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));

app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Route de santé
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'LOGESCO Backend API - Mode Standalone',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    mode: 'standalone'
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Routes d'authentification
const authRoutes = require('./routes/auth-standalone');
app.use('/api/v1/auth', authRoutes);

// Routes métier - Utilisation des modules standalone
try {
  // Routes catégories
  const categoriesRoutes = require('./routes/categories-standalone');
  app.use('/api/v1/categories', categoriesRoutes);

  // Routes produits basiques
  app.get('/api/v1/products', (req, res) => {
    const mockProducts = [
      {
        id: 1,
        reference: 'PROD001',
        nom: 'Smartphone Samsung',
        description: 'Smartphone Android dernière génération',
        prixUnitaire: 299.99,
        prixAchat: 200.00,
        categorieId: 1,
        seuilStockMinimum: 5,
        estActif: true,
        estService: false,
        dateCreation: new Date().toISOString(),
        dateModification: new Date().toISOString(),
        stock: { quantiteDisponible: 10, quantiteReservee: 0 }
      }
    ];
    
    res.json({
      success: true,
      data: mockProducts,
      message: 'Produits récupérés avec succès'
    });
  });

  // Routes utilisateurs basiques
  app.get('/api/v1/users', (req, res) => {
    const mockUsers = [
      {
        id: 1,
        nomUtilisateur: 'admin',
        email: 'admin@logesco.com',
        isActive: true,
        dateCreation: new Date().toISOString(),
        dateModification: new Date().toISOString(),
        role: {
          id: 1,
          nom: 'admin',
          displayName: 'Administrateur',
          isAdmin: true
        }
      }
    ];
    
    res.json({
      success: true,
      data: mockUsers,
      message: 'Utilisateurs récupérés avec succès'
    });
  });

  // Routes rôles basiques
  app.get('/api/v1/roles', (req, res) => {
    const mockRoles = [
      {
        id: 1,
        nom: 'admin',
        displayName: 'Administrateur',
        isAdmin: true,
        privileges: JSON.stringify({
          canManageUsers: true,
          canManageProducts: true,
          canManageSales: true,
          canManageInventory: true,
          canManageReports: true,
          canManageCompanySettings: true
        }),
        dateCreation: new Date().toISOString(),
        dateModification: new Date().toISOString()
      },
      {
        id: 2,
        nom: 'vendeur',
        displayName: 'Vendeur',
        isAdmin: false,
        privileges: JSON.stringify({
          canManageUsers: false,
          canManageProducts: false,
          canManageSales: true,
          canManageInventory: false,
          canManageReports: false,
          canManageCompanySettings: false
        }),
        dateCreation: new Date().toISOString(),
        dateModification: new Date().toISOString()
      }
    ];
    
    res.json({
      success: true,
      data: mockRoles,
      message: 'Rôles récupérés avec succès'
    });
  });

  // Route pour récupérer le compte d'un client (temporaire pour le serveur standalone)
  app.get('/api/v1/customers/:id/account', (req, res) => {
    const { id } = req.params;
    console.log(`📥 GET /api/v1/customers/${id}/account`);
    
    // Simuler des données de compte client
    const mockAccount = {
      clientId: parseInt(id),
      nom: 'Client Test',
      prenom: 'Prénom',
      soldeActuel: -5000.0, // Exemple avec une dette
      limiteCredit: 10000.0,
      aDette: true,
      montantDette: 5000.0,
      creditDisponible: 0.0
    };
    
    res.json({
      success: true,
      data: mockAccount,
      message: 'Compte client récupéré avec succès'
    });
  });

  console.log('✅ Routes catégories et autres routes essentielles ajoutées au serveur standalone');
} catch (error) {
  console.error('❌ Erreur lors de l\'ajout des routes:', error);
}

// Route pour les statistiques générales
app.get('/api/v1/stats', async (req, res) => {
  try {
    const { getAuthService } = require('./services/auth-service-standalone');
    const authService = getAuthService();
    const result = await authService.getStats();
    res.json(result);
  } catch (error) {
    console.error('❌ Erreur stats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// Middleware de gestion d'erreurs
app.use((err, req, res, next) => {
  console.error('❌ Erreur serveur:', err);
  res.status(500).json({
    success: false,
    message: 'Erreur interne du serveur',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Middleware pour les routes non trouvées
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route non trouvée',
    path: req.originalUrl
  });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`✅ Serveur LOGESCO démarré sur le port ${PORT}`);
  console.log(`🌐 URL: http://localhost:${PORT}`);
  console.log(`📊 Santé: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth: http://localhost:${PORT}/api/v1/auth`);
  console.log('📋 Routes API disponibles:');
  console.log('   - GET  /api/v1/categories');
  console.log('   - POST /api/v1/categories');
  console.log('   - GET  /api/v1/categories/:id');
  console.log('   - PUT  /api/v1/categories/:id');
  console.log('   - DELETE /api/v1/categories/:id');
  console.log('   - GET  /api/v1/products');
  console.log('   - GET  /api/v1/users');
  console.log('   - GET  /api/v1/roles');
  console.log('   - GET  /api/v1/stats');
});

// Gestion propre de l'arrêt
process.on('SIGINT', () => {
  console.log('\n🛑 Arrêt du serveur...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Arrêt du serveur...');
  process.exit(0);
});

module.exports = app;
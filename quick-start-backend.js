const express = require('express');
const cors = require('cors');
const path = require('path');

// Configuration simple pour tester rapidement
const app = express();
const PORT = 3002;

// Middlewares de base
app.use(cors());
app.use(express.json());

// Données de test pour les utilisateurs
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
      isAdmin: true,
      privileges: {
        canManageUsers: true,
        canManageProducts: true,
        canManageSales: true,
        canManageInventory: true,
        canManageReports: true,
        canManageCompanySettings: true,
        canManageCashRegisters: true,
        canViewReports: true,
        canMakeSales: true,
        canManageStock: true
      }
    }
  },
  {
    id: 2,
    nomUtilisateur: 'manager',
    email: 'manager@logesco.com',
    isActive: true,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString(),
    role: {
      id: 2,
      nom: 'manager',
      displayName: 'Gestionnaire',
      isAdmin: false,
      privileges: {
        canManageUsers: false,
        canManageProducts: true,
        canManageSales: true,
        canManageInventory: true,
        canManageReports: true,
        canManageCompanySettings: false,
        canManageCashRegisters: true,
        canViewReports: true,
        canMakeSales: true,
        canManageStock: true
      }
    }
  }
];

// Rôles mockés supprimés - utiliser le vrai serveur backend
const mockRoles = [];

const mockCashRegisters = [
  {
    id: 1,
    nom: 'Caisse Principale',
    description: 'Caisse principale du magasin',
    soldeInitial: 1000.0,
    soldeActuel: 1250.0,
    isActive: true,
    utilisateurId: 1,
    nomUtilisateur: 'admin',
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString(),
    dateOuverture: new Date().toISOString(),
    dateFermeture: null
  },
  {
    id: 2,
    nom: 'Caisse Secondaire',
    description: 'Caisse pour les périodes de pointe',
    soldeInitial: 500.0,
    soldeActuel: 500.0,
    isActive: true,
    utilisateurId: null,
    nomUtilisateur: null,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString(),
    dateOuverture: null,
    dateFermeture: null
  }
];

// Route de base
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'LOGESCO API v2 - Serveur opérationnel (Mode Test Rapide)',
    version: 'v1',
    environment: 'test',
    timestamp: new Date().toISOString()
  });
});

// Routes utilisateurs
app.get('/api/v1/users', (req, res) => {
  console.log('📥 GET /api/v1/users');
  res.json(mockUsers);
});

app.post('/api/v1/users', (req, res) => {
  console.log('📥 POST /api/v1/users', req.body);
  const newUser = {
    id: mockUsers.length + 1,
    ...req.body,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString()
  };
  mockUsers.push(newUser);
  res.status(201).json(newUser);
});

app.put('/api/v1/users/:id', (req, res) => {
  console.log('📥 PUT /api/v1/users/:id', req.params.id, req.body);
  const userId = parseInt(req.params.id);
  const userIndex = mockUsers.findIndex(u => u.id === userId);
  
  if (userIndex === -1) {
    return res.status(404).json({ message: 'Utilisateur non trouvé' });
  }
  
  mockUsers[userIndex] = {
    ...mockUsers[userIndex],
    ...req.body,
    id: userId,
    dateModification: new Date().toISOString()
  };
  
  res.json(mockUsers[userIndex]);
});

app.delete('/api/v1/users/:id', (req, res) => {
  console.log('📥 DELETE /api/v1/users/:id', req.params.id);
  const userId = parseInt(req.params.id);
  const userIndex = mockUsers.findIndex(u => u.id === userId);
  
  if (userIndex === -1) {
    return res.status(404).json({ message: 'Utilisateur non trouvé' });
  }
  
  mockUsers.splice(userIndex, 1);
  res.status(204).send();
});

// Routes rôles
app.get('/api/v1/roles', (req, res) => {
  console.log('📥 GET /api/v1/roles');
  res.json(mockRoles);
});

// Routes caisses
app.get('/api/v1/cash-registers', (req, res) => {
  console.log('📥 GET /api/v1/cash-registers');
  res.json(mockCashRegisters);
});

app.post('/api/v1/cash-registers', (req, res) => {
  console.log('📥 POST /api/v1/cash-registers', req.body);
  const newCashRegister = {
    id: mockCashRegisters.length + 1,
    ...req.body,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString()
  };
  mockCashRegisters.push(newCashRegister);
  res.status(201).json(newCashRegister);
});

// Routes inventaire (basique)
app.get('/api/v1/stock-inventory', (req, res) => {
  console.log('📥 GET /api/v1/stock-inventory');
  res.json([]);
});

// Middleware de gestion d'erreurs
app.use((err, req, res, next) => {
  console.error('❌ Erreur serveur:', err);
  res.status(500).json({
    success: false,
    error: {
      message: 'Erreur serveur interne',
      code: 'INTERNAL_SERVER_ERROR'
    }
  });
});

// Middleware pour les routes non trouvées
app.use('*', (req, res) => {
  console.log('❌ Route non trouvée:', req.method, req.originalUrl);
  res.status(404).json({
    success: false,
    error: {
      message: 'Route non trouvée',
      code: 'NOT_FOUND',
      path: req.originalUrl
    }
  });
});

// Démarrer le serveur
app.listen(PORT, () => {
  console.log('🚀 Serveur de test LOGESCO démarré');
  console.log(`🌐 API disponible sur: http://localhost:${PORT}/api/v1`);
  console.log('📋 Routes disponibles:');
  console.log('   - GET  /api/v1/users');
  console.log('   - POST /api/v1/users');
  console.log('   - PUT  /api/v1/users/:id');
  console.log('   - DELETE /api/v1/users/:id');
  console.log('   - GET  /api/v1/roles');
  console.log('   - GET  /api/v1/cash-registers');
  console.log('   - POST /api/v1/cash-registers');
  console.log('   - GET  /api/v1/stock-inventory');
  console.log('');
  console.log('💡 Testez avec: node test-backend.js');
});

module.exports = app;
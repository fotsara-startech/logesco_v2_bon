// Serveur de test simple pour l'API LOGESCO
// Lancez avec: node test_server.js

const express = require('express');
const cors = require('cors');
const app = express();
const port = 3002;

app.use(cors());
app.use(express.json());

// Données de test
const products = [
  {
    id: 1,
    reference: "REF001",
    nom: "iPhone 15 Pro",
    description: "Smartphone Apple dernière génération",
    prixUnitaire: 1299.99,
    prixAchat: 999.99,
    codeBarre: "1234567890123",
    categorie: "Smartphones",
    seuilStockMinimum: 10,
    estActif: true,
    estService: false,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  },
  {
    id: 2,
    reference: "REF002",
    nom: "Samsung Galaxy S24",
    description: "Smartphone Samsung haut de gamme",
    prixUnitaire: 1199.99,
    prixAchat: 899.99,
    codeBarre: "1234567890124",
    categorie: "Smartphones",
    seuilStockMinimum: 15,
    estActif: true,
    estService: false,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  },
  {
    id: 3,
    reference: "REF003",
    nom: "MacBook Air M3",
    description: "Ordinateur portable Apple",
    prixUnitaire: 1499.99,
    prixAchat: 1199.99,
    codeBarre: "1234567890125",
    categorie: "Ordinateurs",
    seuilStockMinimum: 5,
    estActif: true,
    estService: false,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  }
];

const stocks = [
  {
    id: 1,
    produitId: 1,
    quantiteDisponible: 50,
    quantiteReservee: 5,
    derniereMaj: "2024-01-01T12:00:00Z",
    stockFaible: false,
    produit: products[0]
  },
  {
    id: 2,
    produitId: 2,
    quantiteDisponible: 25,
    quantiteReservee: 0,
    derniereMaj: "2024-01-01T12:00:00Z",
    stockFaible: false,
    produit: products[1]
  }
];

// Données des catégories
const categories = [
  {
    id: 1,
    nom: "Smartphones",
    description: "Téléphones intelligents et accessoires",
    couleur: "#2196F3",
    icone: "phone_android",
    estActive: true,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  },
  {
    id: 2,
    nom: "Ordinateurs",
    description: "Ordinateurs portables et de bureau",
    couleur: "#4CAF50",
    icone: "computer",
    estActive: true,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  },
  {
    id: 3,
    nom: "Accessoires",
    description: "Accessoires informatiques et électroniques",
    couleur: "#FF9800",
    icone: "mouse",
    estActive: true,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  },
  {
    id: 4,
    nom: "Écrans",
    description: "Moniteurs et écrans",
    couleur: "#9C27B0",
    icone: "monitor",
    estActive: true,
    dateCreation: "2024-01-01T00:00:00Z",
    dateModification: "2024-01-01T00:00:00Z"
  }
];

// Données des utilisateurs (vide au démarrage)
const users = [];

// Données des rôles (vide au démarrage)
const roles = [];

// Routes API

// Authentification (mock)
app.post('/api/v1/auth/login', (req, res) => {
  res.json({
    success: true,
    data: {
      token: 'mock-jwt-token-12345',
      refreshToken: 'mock-refresh-token-67890',
      user: {
        id: 1,
        nom: 'Utilisateur Test',
        email: 'test@logesco.com'
      }
    }
  });
});

// Produits
app.get('/api/v1/products', (req, res) => {
  const page = parseInt(req.query.page) || 1;
  let limit = parseInt(req.query.limit) || 20;
  const search = req.query.search;
  const isActive = req.query.isActive;
  const categorie = req.query.categorie;

  if (limit < 1 || limit > 100) {
    return res.status(400).json({
      success: false,
      message: 'La limite doit être entre 1 et 100',
      code: 'limit'
    });
  }

  let filteredProducts = [...products];

  if (search) {
    filteredProducts = filteredProducts.filter(p => 
      p.nom.toLowerCase().includes(search.toLowerCase()) ||
      p.reference.toLowerCase().includes(search.toLowerCase())
    );
  }

  if (isActive !== undefined) {
    filteredProducts = filteredProducts.filter(p => p.estActif === (isActive === 'true'));
  }

  if (categorie) {
    filteredProducts = filteredProducts.filter(p => p.categorie === categorie);
  }

  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  const paginatedProducts = filteredProducts.slice(startIndex, endIndex);

  res.json({
    success: true,
    data: paginatedProducts,
    pagination: {
      page,
      limit,
      total: filteredProducts.length,
      pages: Math.ceil(filteredProducts.length / limit),
      hasNext: endIndex < filteredProducts.length,
      hasPrev: page > 1
    }
  });
});

app.get('/api/v1/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const product = products.find(p => p.id === id);
  
  if (product) {
    res.json({ success: true, data: product });
  } else {
    res.status(404).json({ success: false, message: 'Produit non trouvé' });
  }
});

// Gestion des catégories
app.get('/api/v1/categories', (req, res) => {
  res.json({
    success: true,
    data: categories
  });
});

app.get('/api/v1/categories/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const category = categories.find(c => c.id === id);
  
  if (category) {
    res.json({ success: true, data: category });
  } else {
    res.status(404).json({ success: false, message: 'Catégorie non trouvée' });
  }
});

app.post('/api/v1/categories', (req, res) => {
  const { nom, description, couleur, icone } = req.body;
  
  if (!nom) {
    return res.status(400).json({
      success: false,
      message: 'Le nom de la catégorie est requis'
    });
  }
  
  const existingCategory = categories.find(c => c.nom.toLowerCase() === nom.toLowerCase());
  if (existingCategory) {
    return res.status(409).json({
      success: false,
      message: 'Une catégorie avec ce nom existe déjà'
    });
  }
  
  const newCategory = {
    id: Math.max(...categories.map(c => c.id)) + 1,
    nom,
    description: description || '',
    couleur: couleur || '#2196F3',
    icone: icone || 'category',
    estActive: true,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString()
  };
  
  categories.push(newCategory);
  
  res.status(201).json({
    success: true,
    data: newCategory
  });
});

app.put('/api/v1/categories/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const categoryIndex = categories.findIndex(c => c.id === id);
  
  if (categoryIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Catégorie non trouvée'
    });
  }
  
  const { nom, description, couleur, icone, estActive } = req.body;
  
  if (nom) {
    const existingCategory = categories.find(c => c.nom.toLowerCase() === nom.toLowerCase() && c.id !== id);
    if (existingCategory) {
      return res.status(409).json({
        success: false,
        message: 'Une catégorie avec ce nom existe déjà'
      });
    }
  }
  
  categories[categoryIndex] = {
    ...categories[categoryIndex],
    nom: nom || categories[categoryIndex].nom,
    description: description !== undefined ? description : categories[categoryIndex].description,
    couleur: couleur || categories[categoryIndex].couleur,
    icone: icone || categories[categoryIndex].icone,
    estActive: estActive !== undefined ? estActive : categories[categoryIndex].estActive,
    dateModification: new Date().toISOString()
  };
  
  res.json({
    success: true,
    data: categories[categoryIndex]
  });
});

app.delete('/api/v1/categories/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const categoryIndex = categories.findIndex(c => c.id === id);
  
  if (categoryIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Catégorie non trouvée'
    });
  }
  
  const productsUsingCategory = products.filter(p => p.categorie === categories[categoryIndex].nom);
  if (productsUsingCategory.length > 0) {
    return res.status(409).json({
      success: false,
      message: `Impossible de supprimer la catégorie. Elle est utilisée par ${productsUsingCategory.length} produit(s).`
    });
  }
  
  categories.splice(categoryIndex, 1);
  
  res.json({
    success: true,
    message: 'Catégorie supprimée avec succès'
  });
});

// Gestion des utilisateurs
app.get('/api/v1/users', (req, res) => {
  res.json({
    success: true,
    data: users
  });
});

app.get('/api/v1/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const user = users.find(u => u.id === id);
  
  if (user) {
    res.json({ success: true, data: user });
  } else {
    res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
  }
});

app.post('/api/v1/users', (req, res) => {
  const { nomUtilisateur, email, motDePasse, role, isActive = true } = req.body;
  
  if (!nomUtilisateur || !email || !motDePasse || !role) {
    return res.status(400).json({
      success: false,
      message: 'Données manquantes (nomUtilisateur, email, motDePasse, role requis)'
    });
  }
  
  const existingUser = users.find(u => 
    u.nomUtilisateur.toLowerCase() === nomUtilisateur.toLowerCase() || 
    u.email.toLowerCase() === email.toLowerCase()
  );
  
  if (existingUser) {
    return res.status(409).json({
      success: false,
      message: 'Un utilisateur avec ce nom ou cet email existe déjà'
    });
  }
  
  const newUser = {
    id: users.length > 0 ? Math.max(...users.map(u => u.id)) + 1 : 1,
    nomUtilisateur,
    email,
    role: typeof role === 'object' ? role : roles.find(r => r.id === role),
    isActive,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString()
  };
  
  users.push(newUser);
  
  res.status(201).json({
    success: true,
    data: newUser
  });
});

app.put('/api/v1/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Utilisateur non trouvé'
    });
  }
  
  const { nomUtilisateur, email, role, isActive } = req.body;
  
  if (nomUtilisateur || email) {
    const existingUser = users.find(u => 
      u.id !== id && (
        (nomUtilisateur && u.nomUtilisateur.toLowerCase() === nomUtilisateur.toLowerCase()) ||
        (email && u.email.toLowerCase() === email.toLowerCase())
      )
    );
    
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Un autre utilisateur avec ce nom ou cet email existe déjà'
      });
    }
  }
  
  users[userIndex] = {
    ...users[userIndex],
    nomUtilisateur: nomUtilisateur || users[userIndex].nomUtilisateur,
    email: email || users[userIndex].email,
    role: role || users[userIndex].role,
    isActive: isActive !== undefined ? isActive : users[userIndex].isActive,
    dateModification: new Date().toISOString()
  };
  
  res.json({
    success: true,
    data: users[userIndex]
  });
});

app.delete('/api/v1/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Utilisateur non trouvé'
    });
  }
  
  // Protection désactivée pour les tests - permettre la suppression de tous les utilisateurs
  // if (users[userIndex].role.nom === 'ADMIN' && users[userIndex].id === 1) {
  //   return res.status(403).json({
  //     success: false,
  //     message: 'Impossible de supprimer l\'administrateur principal'
  //   });
  // }
  
  users.splice(userIndex, 1);
  
  res.json({
    success: true,
    message: 'Utilisateur supprimé avec succès'
  });
});

// Gestion des rôles
app.get('/api/v1/roles', (req, res) => {
  res.json({
    success: true,
    data: roles
  });
});

app.get('/api/v1/roles/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const role = roles.find(r => r.id === id);
  
  if (role) {
    res.json({ success: true, data: role });
  } else {
    res.status(404).json({ success: false, message: 'Rôle non trouvé' });
  }
});

app.post('/api/v1/roles', (req, res) => {
  const { nom, displayName, isAdmin = false, privileges = {} } = req.body;
  
  if (!nom || !displayName) {
    return res.status(400).json({
      success: false,
      message: 'Le nom et le nom d\'affichage sont requis'
    });
  }
  
  const existingRole = roles.find(r => r.nom.toLowerCase() === nom.toLowerCase());
  if (existingRole) {
    return res.status(409).json({
      success: false,
      message: 'Un rôle avec ce nom existe déjà'
    });
  }
  
  const newRole = {
    id: roles.length > 0 ? Math.max(...roles.map(r => r.id)) + 1 : 1,
    nom: nom.toUpperCase(),
    displayName,
    isAdmin,
    privileges: typeof privileges === 'string' ? privileges : JSON.stringify(privileges),
    description: `Rôle ${displayName}`,
    dateCreation: new Date().toISOString(),
    dateModification: new Date().toISOString()
  };
  
  roles.push(newRole);
  
  res.status(201).json({
    success: true,
    data: newRole
  });
});

app.put('/api/v1/roles/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const roleIndex = roles.findIndex(r => r.id === id);
  
  if (roleIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Rôle non trouvé'
    });
  }
  
  const { nom, displayName, isAdmin, privileges } = req.body;
  
  if (nom) {
    const existingRole = roles.find(r => r.nom.toLowerCase() === nom.toLowerCase() && r.id !== id);
    if (existingRole) {
      return res.status(409).json({
        success: false,
        message: 'Un rôle avec ce nom existe déjà'
      });
    }
  }
  
  roles[roleIndex] = {
    ...roles[roleIndex],
    nom: nom ? nom.toUpperCase() : roles[roleIndex].nom,
    displayName: displayName || roles[roleIndex].displayName,
    isAdmin: isAdmin !== undefined ? isAdmin : roles[roleIndex].isAdmin,
    privileges: privileges !== undefined 
      ? (typeof privileges === 'string' ? privileges : JSON.stringify(privileges))
      : roles[roleIndex].privileges,
    dateModification: new Date().toISOString()
  };
  
  res.json({
    success: true,
    data: roles[roleIndex]
  });
});

app.delete('/api/v1/roles/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const roleIndex = roles.findIndex(r => r.id === id);
  
  if (roleIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Rôle non trouvé'
    });
  }
  
  // Vérifier si le rôle est utilisé par des utilisateurs
  const usersWithRole = users.filter(u => u.role && u.role.id === id);
  if (usersWithRole.length > 0) {
    return res.status(409).json({
      success: false,
      message: `Impossible de supprimer le rôle. Il est utilisé par ${usersWithRole.length} utilisateur(s).`
    });
  }
  
  roles.splice(roleIndex, 1);
  
  res.json({
    success: true,
    message: 'Rôle supprimé avec succès'
  });
});

// Inventaire
app.get('/api/v1/inventory', (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  const paginatedStocks = stocks.slice(startIndex, endIndex);

  res.json({
    success: true,
    data: paginatedStocks,
    pagination: {
      page,
      limit,
      total: stocks.length,
      pages: Math.ceil(stocks.length / limit),
      hasNext: endIndex < stocks.length,
      hasPrev: page > 1
    }
  });
});

app.listen(port, () => {
  console.log(`🚀 Serveur de test LOGESCO démarré sur http://localhost:${port}`);
  console.log(`📋 Endpoints disponibles:`);
  console.log(`   GET    /api/v1/products`);
  console.log(`   GET    /api/v1/categories`);
  console.log(`   POST   /api/v1/categories`);
  console.log(`   PUT    /api/v1/categories/:id`);
  console.log(`   DELETE /api/v1/categories/:id`);
  console.log(`   GET    /api/v1/users`);
  console.log(`   GET    /api/v1/users/:id`);
  console.log(`   POST   /api/v1/users`);
  console.log(`   PUT    /api/v1/users/:id`);
  console.log(`   DELETE /api/v1/users/:id`);
  console.log(`   GET    /api/v1/roles`);
  console.log(`   GET    /api/v1/roles/:id`);
  console.log(`   POST   /api/v1/roles`);
  console.log(`   PUT    /api/v1/roles/:id`);
  console.log(`   DELETE /api/v1/roles/:id`);
  console.log(`   GET    /api/v1/inventory`);
  console.log(`   POST   /api/v1/auth/login`);
});
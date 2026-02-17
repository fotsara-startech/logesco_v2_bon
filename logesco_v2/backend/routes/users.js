const express = require('express');
const router = express.Router();

// Données de test pour les utilisateurs
const users = [
  {
    id: 1,
    nomUtilisateur: 'admin',
    email: 'admin@logesco.com',
    role: {
      id: 1,
      nom: 'ADMIN',
      displayName: 'Administrateur',
      isAdmin: true,
      permissions: ['ALL']
    },
    isActive: true,
    dateCreation: '2024-01-01T00:00:00Z',
    dateModification: '2024-01-01T00:00:00Z'
  },
  {
    id: 2,
    nomUtilisateur: 'manager',
    email: 'manager@logesco.com',
    role: {
      id: 2,
      nom: 'MANAGER',
      displayName: 'Gestionnaire',
      isAdmin: false,
      permissions: ['READ', 'WRITE', 'UPDATE']
    },
    isActive: true,
    dateCreation: '2024-01-01T00:00:00Z',
    dateModification: '2024-01-01T00:00:00Z'
  },
  {
    id: 3,
    nomUtilisateur: 'employee',
    email: 'employee@logesco.com',
    role: {
      id: 3,
      nom: 'EMPLOYEE',
      displayName: 'Employé',
      isAdmin: false,
      permissions: ['READ']
    },
    isActive: true,
    dateCreation: '2024-01-01T00:00:00Z',
    dateModification: '2024-01-01T00:00:00Z'
  },
  {
    id: 4,
    nomUtilisateur: 'cashier',
    email: 'cashier@logesco.com',
    role: {
      id: 4,
      nom: 'CASHIER',
      displayName: 'Caissier',
      isAdmin: false,
      permissions: ['READ', 'SALES']
    },
    isActive: false,
    dateCreation: '2024-01-01T00:00:00Z',
    dateModification: '2024-01-01T00:00:00Z'
  }
];

const roles = [
  {
    id: 1,
    nom: 'ADMIN',
    displayName: 'Administrateur',
    isAdmin: true,
    permissions: ['ALL']
  },
  {
    id: 2,
    nom: 'MANAGER',
    displayName: 'Gestionnaire',
    isAdmin: false,
    permissions: ['READ', 'WRITE', 'UPDATE']
  },
  {
    id: 3,
    nom: 'EMPLOYEE',
    displayName: 'Employé',
    isAdmin: false,
    permissions: ['READ']
  },
  {
    id: 4,
    nom: 'CASHIER',
    displayName: 'Caissier',
    isAdmin: false,
    permissions: ['READ', 'SALES']
  }
];

// GET /users - Récupérer tous les utilisateurs
router.get('/', (req, res) => {
  try {
    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la récupération des utilisateurs',
        code: 'USERS_FETCH_ERROR'
      }
    });
  }
});

// GET /users/:id - Récupérer un utilisateur par ID
router.get('/:id', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const user = users.find(u => u.id === id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: {
          message: 'Utilisateur non trouvé',
          code: 'USER_NOT_FOUND'
        }
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la récupération de l\'utilisateur',
        code: 'USER_FETCH_ERROR'
      }
    });
  }
});

// POST /users - Créer un nouvel utilisateur
router.post('/', (req, res) => {
  try {
    const { nomUtilisateur, email, motDePasse, role, isActive = true } = req.body;
    
    if (!nomUtilisateur || !email || !motDePasse || !role) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Données manquantes (nomUtilisateur, email, motDePasse, role requis)',
          code: 'MISSING_DATA'
        }
      });
    }
    
    // Vérifier si l'utilisateur existe déjà
    const existingUser = users.find(u => 
      u.nomUtilisateur.toLowerCase() === nomUtilisateur.toLowerCase() || 
      u.email.toLowerCase() === email.toLowerCase()
    );
    
    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: {
          message: 'Un utilisateur avec ce nom ou cet email existe déjà',
          code: 'USER_EXISTS'
        }
      });
    }
    
    const newUser = {
      id: Math.max(...users.map(u => u.id)) + 1,
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
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la création de l\'utilisateur',
        code: 'USER_CREATE_ERROR'
      }
    });
  }
});

// PUT /users/:id - Mettre à jour un utilisateur
router.put('/:id', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        error: {
          message: 'Utilisateur non trouvé',
          code: 'USER_NOT_FOUND'
        }
      });
    }
    
    const { nomUtilisateur, email, role, isActive } = req.body;
    
    // Vérifier les conflits de nom/email (sauf pour l'utilisateur actuel)
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
          error: {
            message: 'Un autre utilisateur avec ce nom ou cet email existe déjà',
            code: 'USER_EXISTS'
          }
        });
      }
    }
    
    // Mettre à jour l'utilisateur
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
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la mise à jour de l\'utilisateur',
        code: 'USER_UPDATE_ERROR'
      }
    });
  }
});

// DELETE /users/:id - Supprimer un utilisateur
router.delete('/:id', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        error: {
          message: 'Utilisateur non trouvé',
          code: 'USER_NOT_FOUND'
        }
      });
    }
    
    // Empêcher la suppression de l'admin principal
    if (users[userIndex].role.nom === 'ADMIN' && users[userIndex].id === 1) {
      return res.status(403).json({
        success: false,
        error: {
          message: 'Impossible de supprimer l\'administrateur principal',
          code: 'ADMIN_DELETE_FORBIDDEN'
        }
      });
    }
    
    users.splice(userIndex, 1);
    
    res.json({
      success: true,
      message: 'Utilisateur supprimé avec succès'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la suppression de l\'utilisateur',
        code: 'USER_DELETE_ERROR'
      }
    });
  }
});

// PUT /users/:id/status - Activer/Désactiver un utilisateur
router.put('/:id/status', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        error: {
          message: 'Utilisateur non trouvé',
          code: 'USER_NOT_FOUND'
        }
      });
    }
    
    const { isActive } = req.body;
    
    if (isActive === undefined) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Le statut isActive est requis',
          code: 'MISSING_STATUS'
        }
      });
    }
    
    users[userIndex].isActive = isActive;
    users[userIndex].dateModification = new Date().toISOString();
    
    res.json({
      success: true,
      data: users[userIndex]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la modification du statut',
        code: 'STATUS_UPDATE_ERROR'
      }
    });
  }
});

// PUT /users/:id/password - Changer le mot de passe
router.put('/:id/password', (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const user = users.find(u => u.id === id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: {
          message: 'Utilisateur non trouvé',
          code: 'USER_NOT_FOUND'
        }
      });
    }
    
    const { motDePasse } = req.body;
    
    if (!motDePasse) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Le nouveau mot de passe est requis',
          code: 'MISSING_PASSWORD'
        }
      });
    }
    
    // Simuler le changement de mot de passe (pas de stockage réel)
    user.dateModification = new Date().toISOString();
    
    res.json({
      success: true,
      message: 'Mot de passe modifié avec succès'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors du changement de mot de passe',
        code: 'PASSWORD_UPDATE_ERROR'
      }
    });
  }
});

// GET /roles - Récupérer tous les rôles
router.get('/roles', (req, res) => {
  try {
    res.json({
      success: true,
      data: roles
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur lors de la récupération des rôles',
        code: 'ROLES_FETCH_ERROR'
      }
    });
  }
});

module.exports = router;
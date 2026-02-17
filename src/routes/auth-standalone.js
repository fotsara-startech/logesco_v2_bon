/**
 * Routes d'authentification pour le mode standalone
 */

const express = require('express');
const { getAuthService } = require('../services/auth-service-standalone');

const router = express.Router();
const authService = getAuthService();

// POST /api/v1/auth/login
router.post('/login', async (req, res) => {
  try {
    const { nomUtilisateur, motDePasse } = req.body;

    if (!nomUtilisateur || !motDePasse) {
      return res.status(400).json({
        success: false,
        message: 'Nom d\'utilisateur et mot de passe requis'
      });
    }

    const result = await authService.login(nomUtilisateur, motDePasse);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(401).json(result);
    }
  } catch (error) {
    console.error('❌ Erreur route login:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// POST /api/v1/auth/register
router.post('/register', async (req, res) => {
  try {
    const { email, password, nom, prenom, role } = req.body;

    if (!email || !password || !nom || !prenom) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs sont requis'
      });
    }

    const result = await authService.register({
      email,
      password,
      nom,
      prenom,
      role: role || 'user'
    });
    
    if (result.success) {
      res.status(201).json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('❌ Erreur route register:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// GET /api/v1/auth/verify
router.get('/verify', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant'
      });
    }

    const result = await authService.verifyToken(token);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(401).json(result);
    }
  } catch (error) {
    console.error('❌ Erreur route verify:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// POST /api/v1/auth/logout
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token manquant'
      });
    }

    const result = await authService.logout(token);
    res.json(result);
  } catch (error) {
    console.error('❌ Erreur route logout:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// POST /api/v1/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token requis'
      });
    }

    const result = await authService.refreshToken(refreshToken);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(401).json(result);
    }
  } catch (error) {
    console.error('❌ Erreur route refresh:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

// GET /api/v1/auth/stats
router.get('/stats', async (req, res) => {
  try {
    const result = await authService.getStats();
    res.json(result);
  } catch (error) {
    console.error('❌ Erreur route stats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur interne du serveur'
    });
  }
});

module.exports = router;
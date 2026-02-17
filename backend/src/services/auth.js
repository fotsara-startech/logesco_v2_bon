/**
 * Service d'authentification JWT pour LOGESCO
 * Gestion des tokens, sessions et sécurité
 */

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const environment = require('../config/environment');
const { UtilisateurDTO } = require('../dto');

class AuthService {
  constructor(userModel) {
    this.userModel = userModel;
    this.jwtSecret = environment.jwtConfig.secret;
    this.jwtExpiresIn = environment.jwtConfig.expiresIn;
    this.refreshExpiresIn = environment.jwtConfig.refreshExpiresIn;
    
    // Stockage en mémoire des refresh tokens (en production, utiliser Redis)
    this.refreshTokens = new Set();
  }

  /**
   * Authentifie un utilisateur avec nom d'utilisateur et mot de passe
   * @param {string} nomUtilisateur - Nom d'utilisateur
   * @param {string} motDePasse - Mot de passe en clair
   * @returns {Promise<Object>} Résultat de l'authentification
   */
  async login(nomUtilisateur, motDePasse) {
    try {
      // Trouver l'utilisateur
      const utilisateur = await this.userModel.findByUsername(nomUtilisateur);
      
      if (!utilisateur) {
        throw new Error('Nom d\'utilisateur ou mot de passe incorrect');
      }

      // Vérifier le mot de passe
      const isValidPassword = await this.userModel.verifyPassword(motDePasse, utilisateur.motDePasseHash);
      
      if (!isValidPassword) {
        throw new Error('Nom d\'utilisateur ou mot de passe incorrect');
      }

      // Générer les tokens
      const tokens = this.generateTokens(utilisateur);
      
      // Stocker le refresh token
      this.refreshTokens.add(tokens.refreshToken);

      // Retourner les données utilisateur (sans mot de passe) et tokens
      return {
        utilisateur: UtilisateurDTO.fromEntity(utilisateur),
        ...tokens
      };

    } catch (error) {
      console.error('Erreur lors de l\'authentification:', error);
      throw error;
    }
  }

  /**
   * Rafraîchit un access token avec un refresh token valide
   * @param {string} refreshToken - Refresh token
   * @returns {Promise<Object>} Nouveaux tokens
   */
  async refreshToken(refreshToken) {
    try {
      // Vérifier que le refresh token existe
      if (!this.refreshTokens.has(refreshToken)) {
        throw new Error('Refresh token invalide');
      }

      // Vérifier et décoder le refresh token
      const decoded = jwt.verify(refreshToken, this.jwtSecret);
      
      // Trouver l'utilisateur
      const utilisateur = await this.userModel.findById(decoded.userId);
      
      if (!utilisateur) {
        throw new Error('Utilisateur non trouvé');
      }

      // Supprimer l'ancien refresh token
      this.refreshTokens.delete(refreshToken);

      // Générer de nouveaux tokens
      const tokens = this.generateTokens(utilisateur);
      
      // Stocker le nouveau refresh token
      this.refreshTokens.add(tokens.refreshToken);

      return {
        utilisateur: UtilisateurDTO.fromEntity(utilisateur),
        ...tokens
      };

    } catch (error) {
      console.error('Erreur lors du rafraîchissement du token:', error);
      throw new Error('Refresh token invalide ou expiré');
    }
  }

  /**
   * Déconnecte un utilisateur en invalidant son refresh token
   * @param {string} refreshToken - Refresh token à invalider
   * @returns {boolean} Succès de la déconnexion
   */
  async logout(refreshToken) {
    try {
      if (refreshToken && this.refreshTokens.has(refreshToken)) {
        this.refreshTokens.delete(refreshToken);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Erreur lors de la déconnexion:', error);
      return false;
    }
  }

  /**
   * Vérifie et décode un access token
   * @param {string} token - Access token à vérifier
   * @returns {Object} Données décodées du token
   */
  verifyAccessToken(token) {
    try {
      return jwt.verify(token, this.jwtSecret);
    } catch (error) {
      throw new Error('Token invalide ou expiré');
    }
  }

  /**
   * Génère les tokens JWT pour un utilisateur
   * @param {Object} utilisateur - Données utilisateur
   * @returns {Object} Access token et refresh token
   */
  generateTokens(utilisateur) {
    const payload = {
      userId: utilisateur.id,
      nomUtilisateur: utilisateur.nomUtilisateur,
      email: utilisateur.email
    };

    const accessToken = jwt.sign(
      payload,
      this.jwtSecret,
      { 
        expiresIn: this.jwtExpiresIn,
        issuer: 'logesco-api',
        audience: 'logesco-client'
      }
    );

    const refreshToken = jwt.sign(
      { userId: utilisateur.id },
      this.jwtSecret,
      { 
        expiresIn: this.refreshExpiresIn,
        issuer: 'logesco-api',
        audience: 'logesco-client'
      }
    );

    return {
      accessToken,
      refreshToken,
      expiresIn: this.jwtExpiresIn,
      tokenType: 'Bearer'
    };
  }

  /**
   * Crée un nouvel utilisateur avec mot de passe hashé
   * @param {Object} userData - Données utilisateur
   * @returns {Promise<Object>} Utilisateur créé
   */
  async register(userData) {
    try {
      // Vérifier si l'utilisateur existe déjà
      const existingByUsername = await this.userModel.findByUsername(userData.nomUtilisateur);
      if (existingByUsername) {
        throw new Error('Ce nom d\'utilisateur est déjà utilisé');
      }

      const existingByEmail = await this.userModel.findByEmail(userData.email);
      if (existingByEmail) {
        throw new Error('Cette adresse email est déjà utilisée');
      }

      // Créer l'utilisateur
      const utilisateur = await this.userModel.createUser(userData);
      
      // Générer les tokens
      const tokens = this.generateTokens(utilisateur);
      
      // Stocker le refresh token
      this.refreshTokens.add(tokens.refreshToken);

      return {
        utilisateur: UtilisateurDTO.fromEntity(utilisateur),
        ...tokens
      };

    } catch (error) {
      console.error('Erreur lors de l\'inscription:', error);
      throw error;
    }
  }

  /**
   * Change le mot de passe d'un utilisateur
   * @param {number} userId - ID de l'utilisateur
   * @param {string} ancienMotDePasse - Ancien mot de passe
   * @param {string} nouveauMotDePasse - Nouveau mot de passe
   * @returns {Promise<boolean>} Succès du changement
   */
  async changePassword(userId, ancienMotDePasse, nouveauMotDePasse) {
    try {
      // Trouver l'utilisateur
      const utilisateur = await this.userModel.findById(userId);
      
      if (!utilisateur) {
        throw new Error('Utilisateur non trouvé');
      }

      // Vérifier l'ancien mot de passe
      const isValidPassword = await this.userModel.verifyPassword(ancienMotDePasse, utilisateur.motDePasseHash);
      
      if (!isValidPassword) {
        throw new Error('Ancien mot de passe incorrect');
      }

      // Mettre à jour le mot de passe
      await this.userModel.updatePassword(userId, nouveauMotDePasse);
      
      return true;

    } catch (error) {
      console.error('Erreur lors du changement de mot de passe:', error);
      throw error;
    }
  }

  /**
   * Invalide tous les refresh tokens d'un utilisateur (déconnexion globale)
   * @param {number} userId - ID de l'utilisateur
   * @returns {boolean} Succès de l'invalidation
   */
  async logoutAllSessions(userId) {
    try {
      // En production, filtrer par userId dans Redis
      // Ici, on supprime tous les tokens (simplification)
      const tokensToRemove = [];
      
      for (const token of this.refreshTokens) {
        try {
          const decoded = jwt.verify(token, this.jwtSecret);
          if (decoded.userId === userId) {
            tokensToRemove.push(token);
          }
        } catch (error) {
          // Token invalide, on le supprime aussi
          tokensToRemove.push(token);
        }
      }

      tokensToRemove.forEach(token => this.refreshTokens.delete(token));
      
      return true;
    } catch (error) {
      console.error('Erreur lors de la déconnexion globale:', error);
      return false;
    }
  }

  /**
   * Nettoie les refresh tokens expirés
   * @returns {number} Nombre de tokens supprimés
   */
  cleanupExpiredTokens() {
    let removedCount = 0;
    const tokensToRemove = [];

    for (const token of this.refreshTokens) {
      try {
        jwt.verify(token, this.jwtSecret);
      } catch (error) {
        // Token expiré ou invalide
        tokensToRemove.push(token);
      }
    }

    tokensToRemove.forEach(token => {
      this.refreshTokens.delete(token);
      removedCount++;
    });

    if (removedCount > 0) {
      console.log(`🧹 ${removedCount} refresh tokens expirés supprimés`);
    }

    return removedCount;
  }

  /**
   * Obtient les statistiques des tokens actifs
   * @returns {Object} Statistiques
   */
  getTokenStats() {
    return {
      activeRefreshTokens: this.refreshTokens.size,
      jwtConfig: {
        accessTokenExpiry: this.jwtExpiresIn,
        refreshTokenExpiry: this.refreshExpiresIn
      }
    };
  }
}

module.exports = AuthService;
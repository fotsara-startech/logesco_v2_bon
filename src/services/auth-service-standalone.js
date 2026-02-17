/**
 * Service d'authentification pour le mode standalone
 * Utilise le service de base de données adaptatif
 */

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDatabaseService } = require('./database-service');

class AuthServiceStandalone {
  constructor() {
    this.dbService = getDatabaseService();
    this.jwtSecret = process.env.JWT_SECRET || 'dev-secret-key';
    this.jwtExpiresIn = process.env.JWT_EXPIRES_IN || '24h';
    this.refreshExpiresIn = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
  }

  async login(nomUtilisateur, motDePasse) {
    try {
      // Mapper le nom d'utilisateur vers l'email pour la recherche
      let emailToSearch = nomUtilisateur;
      
      // Si c'est "admin", utiliser l'email admin par défaut
      if (nomUtilisateur === 'admin') {
        emailToSearch = 'admin@logesco.com';
      } else if (!nomUtilisateur.includes('@')) {
        // Si ce n'est pas un email, essayer de trouver par nom d'utilisateur
        // Pour l'instant, on suppose que c'est l'email
        emailToSearch = nomUtilisateur;
      }
      
      // Trouver l'utilisateur
      const user = await this.dbService.findUserByEmail(emailToSearch);
      if (!user) {
        return { success: false, message: 'Utilisateur non trouvé' };
      }

      // Vérifier le mot de passe
      const isValidPassword = await bcrypt.compare(motDePasse, user.password);
      if (!isValidPassword) {
        return { success: false, message: 'Mot de passe incorrect' };
      }

      // Générer les tokens
      const token = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        this.jwtSecret,
        { expiresIn: this.jwtExpiresIn }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, type: 'refresh' },
        this.jwtSecret,
        { expiresIn: this.refreshExpiresIn }
      );

      // Calculer la date d'expiration
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 24); // 24h par défaut

      // Sauvegarder la session
      await this.dbService.createSession(user.id, token, refreshToken, expiresAt.toISOString());

      return {
        success: true,
        data: {
          accessToken: token,
          refreshToken,
          utilisateur: {
            id: user.id,
            email: user.email,
            nom: user.nom,
            prenom: user.prenom,
            role: user.role,
            nomUtilisateur: user.nom + ' ' + user.prenom,
            dateCreation: user.created_at || new Date().toISOString(),
            dateModification: user.created_at || new Date().toISOString()
          }
        }
      };
    } catch (error) {
      console.error('❌ Erreur login:', error);
      return { success: false, message: 'Erreur interne du serveur' };
    }
  }

  async register(userData) {
    try {
      // Vérifier si l'utilisateur existe déjà
      const existingUser = await this.dbService.findUserByEmail(userData.email);
      if (existingUser) {
        return { success: false, message: 'Cet email est déjà utilisé' };
      }

      // Hasher le mot de passe
      const hashedPassword = await bcrypt.hash(userData.password, 10);

      // Créer l'utilisateur
      const newUser = await this.dbService.createUser({
        ...userData,
        password: hashedPassword
      });

      return {
        success: true,
        data: {
          id: newUser.id,
          email: newUser.email,
          nom: newUser.nom,
          prenom: newUser.prenom,
          role: newUser.role
        }
      };
    } catch (error) {
      console.error('❌ Erreur register:', error);
      return { success: false, message: 'Erreur lors de la création du compte' };
    }
  }

  async verifyToken(token) {
    try {
      // Vérifier le token JWT
      const decoded = jwt.verify(token, this.jwtSecret);
      
      // Vérifier la session en base
      const session = await this.dbService.findSessionByToken(token);
      if (!session) {
        return { success: false, message: 'Session invalide' };
      }

      return {
        success: true,
        data: {
          userId: session.user_id || session.userId,
          email: session.email,
          nom: session.nom,
          prenom: session.prenom,
          role: session.role
        }
      };
    } catch (error) {
      console.error('❌ Erreur verifyToken:', error);
      return { success: false, message: 'Token invalide' };
    }
  }

  async logout(token) {
    try {
      await this.dbService.deleteSession(token);
      return { success: true, message: 'Déconnexion réussie' };
    } catch (error) {
      console.error('❌ Erreur logout:', error);
      return { success: false, message: 'Erreur lors de la déconnexion' };
    }
  }

  async refreshToken(refreshToken) {
    try {
      // Vérifier le refresh token
      const decoded = jwt.verify(refreshToken, this.jwtSecret);
      
      if (decoded.type !== 'refresh') {
        return { success: false, message: 'Token de rafraîchissement invalide' };
      }

      // Trouver l'utilisateur
      const user = await this.dbService.findUserById(decoded.userId);
      if (!user) {
        return { success: false, message: 'Utilisateur non trouvé' };
      }

      // Générer un nouveau token
      const newToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        this.jwtSecret,
        { expiresIn: this.jwtExpiresIn }
      );

      return {
        success: true,
        data: { token: newToken }
      };
    } catch (error) {
      console.error('❌ Erreur refreshToken:', error);
      return { success: false, message: 'Impossible de rafraîchir le token' };
    }
  }

  async getStats() {
    try {
      const stats = await this.dbService.getStats();
      return { success: true, data: stats };
    } catch (error) {
      console.error('❌ Erreur getStats:', error);
      return { success: false, message: 'Erreur lors de la récupération des statistiques' };
    }
  }
}

// Singleton
let instance = null;

function getAuthService() {
  if (!instance) {
    instance = new AuthServiceStandalone();
  }
  return instance;
}

module.exports = { AuthServiceStandalone, getAuthService };
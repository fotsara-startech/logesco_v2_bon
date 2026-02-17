/**
 * Service de base de données adaptatif
 * Utilise SQLite direct en mode standalone (pkg) et Prisma en développement
 */

const path = require('path');

class DatabaseService {
  constructor() {
    this.adapter = null;
    this.isStandalone = typeof process.pkg !== 'undefined';
  }

  async initialize() {
    try {
      if (this.isStandalone) {
        console.log('🔧 Mode standalone détecté - utilisation de SQLite direct');
        await this.initializeSQLite();
      } else {
        console.log('🔧 Mode développement - utilisation de Prisma');
        await this.initializePrisma();
      }
      
      return true;
    } catch (error) {
      console.error('❌ Erreur initialisation base de données:', error);
      return false;
    }
  }

  async initializeSQLite() {
    const JsonDatabase = require('../database/json-db');
    
    // Obtenir le chemin de la base de données
    const basePath = this.isStandalone ? 
      path.join(process.env.LOCALAPPDATA || path.join(require('os').homedir(), 'AppData', 'Local'), 'LOGESCO', 'backend') :
      path.join(__dirname, '../../database');
    
    const dbPath = path.join(basePath, 'logesco.json');
    
    this.adapter = new JsonDatabase(dbPath);
    await this.adapter.connect();
    
    console.log('✅ Base de données JSON initialisée');
  }

  async initializePrisma() {
    const { PrismaClient } = require('../config/prisma-client.js');
    
    this.adapter = new PrismaClient();
    await this.adapter.$connect();
    
    console.log('✅ Prisma client initialisé');
  }

  // Méthodes unifiées pour les utilisateurs
  async findUserByEmail(email) {
    if (this.isStandalone) {
      return await this.adapter.findUserByEmail(email);
    } else {
      return await this.adapter.user.findUnique({
        where: { email, actif: true }
      });
    }
  }

  async findUserById(id) {
    if (this.isStandalone) {
      return await this.adapter.findUserById(id);
    } else {
      return await this.adapter.user.findUnique({
        where: { id: parseInt(id), actif: true }
      });
    }
  }

  async createUser(userData) {
    if (this.isStandalone) {
      return await this.adapter.createUser(userData);
    } else {
      return await this.adapter.user.create({
        data: userData
      });
    }
  }

  // Méthodes pour les sessions
  async createSession(userId, token, refreshToken, expiresAt) {
    if (this.isStandalone) {
      return await this.adapter.createSession(userId, token, refreshToken, expiresAt);
    } else {
      return await this.adapter.userSession.create({
        data: {
          userId: parseInt(userId),
          token,
          refreshToken,
          expiresAt: new Date(expiresAt)
        }
      });
    }
  }

  async findSessionByToken(token) {
    if (this.isStandalone) {
      return await this.adapter.findSessionByToken(token);
    } else {
      return await this.adapter.userSession.findUnique({
        where: { token },
        include: { user: true }
      });
    }
  }

  async deleteSession(token) {
    if (this.isStandalone) {
      return await this.adapter.deleteSession(token);
    } else {
      return await this.adapter.userSession.delete({
        where: { token }
      });
    }
  }

  // Statistiques
  async getStats() {
    if (this.isStandalone) {
      return await this.adapter.getStats();
    } else {
      const users = await this.adapter.user.count({ where: { actif: true } });
      const products = await this.adapter.product.count({ where: { actif: true } });
      const categories = await this.adapter.category.count({ where: { actif: true } });
      
      return { users, products, categories };
    }
  }

  async close() {
    if (this.adapter) {
      if (this.isStandalone) {
        await this.adapter.close();
      } else {
        await this.adapter.$disconnect();
      }
    }
  }
}

// Singleton
let instance = null;

function getDatabaseService() {
  if (!instance) {
    instance = new DatabaseService();
  }
  return instance;
}

module.exports = { DatabaseService, getDatabaseService };
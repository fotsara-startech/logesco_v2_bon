/**
 * Base de données JSON simple pour éviter les problèmes de compilation native
 * Parfait pour le mode standalone avec pkg
 */

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

class JsonDatabase {
  constructor(databasePath) {
    this.dbPath = databasePath;
    this.data = {
      users: [],
      sessions: [],
      products: [],
      categories: []
    };
    this.nextId = {
      users: 1,
      sessions: 1,
      products: 1,
      categories: 1
    };
  }

  async connect() {
    try {
      // Créer le dossier si nécessaire
      const dbDir = path.dirname(this.dbPath);
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
      }

      // Charger les données existantes
      if (fs.existsSync(this.dbPath)) {
        const fileContent = fs.readFileSync(this.dbPath, 'utf8');
        const loadedData = JSON.parse(fileContent);
        this.data = { ...this.data, ...loadedData };
        
        // Calculer les prochains IDs
        Object.keys(this.nextId).forEach(table => {
          if (this.data[table] && this.data[table].length > 0) {
            this.nextId[table] = Math.max(...this.data[table].map(item => item.id)) + 1;
          }
        });
      }

      console.log(`✓ Base de données JSON connectée: ${this.dbPath}`);
      
      // Créer l'admin par défaut
      await this.createDefaultAdmin();
      
      return true;
    } catch (error) {
      console.error('❌ Erreur connexion JSON DB:', error);
      return false;
    }
  }

  async save() {
    try {
      fs.writeFileSync(this.dbPath, JSON.stringify(this.data, null, 2));
    } catch (error) {
      console.error('❌ Erreur sauvegarde JSON DB:', error);
    }
  }

  async createDefaultAdmin() {
    // Vérifier si admin existe
    const existingAdmin = this.data.users.find(u => u.email === 'admin@logesco.com');
    
    if (!existingAdmin) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      
      const admin = {
        id: this.nextId.users++,
        email: 'admin@logesco.com',
        password: hashedPassword,
        nom: 'Admin',
        prenom: 'LOGESCO',
        role: 'admin',
        actif: true,
        created_at: new Date().toISOString()
      };
      
      this.data.users.push(admin);
      await this.save();
      
      console.log('✓ Admin créé (admin@logesco.com / admin123)');
    } else {
      console.log('✓ Admin existe déjà');
    }
  }

  // Méthodes utilisateur
  async findUserByEmail(email) {
    return this.data.users.find(u => u.email === email && u.actif);
  }

  async findUserById(id) {
    return this.data.users.find(u => u.id === parseInt(id) && u.actif);
  }

  async createUser(userData) {
    const user = {
      id: this.nextId.users++,
      email: userData.email,
      password: userData.password,
      nom: userData.nom,
      prenom: userData.prenom,
      role: userData.role || 'user',
      actif: true,
      created_at: new Date().toISOString()
    };
    
    this.data.users.push(user);
    await this.save();
    
    return user;
  }

  // Méthodes session
  async createSession(userId, token, refreshToken, expiresAt) {
    const session = {
      id: this.nextId.sessions++,
      user_id: parseInt(userId),
      token,
      refresh_token: refreshToken,
      expires_at: expiresAt,
      created_at: new Date().toISOString()
    };
    
    this.data.sessions.push(session);
    await this.save();
    
    return session;
  }

  async findSessionByToken(token) {
    const session = this.data.sessions.find(s => s.token === token);
    if (!session) return null;
    
    // Vérifier l'expiration
    if (new Date(session.expires_at) <= new Date()) {
      return null;
    }
    
    // Joindre avec l'utilisateur
    const user = this.data.users.find(u => u.id === session.user_id && u.actif);
    if (!user) return null;
    
    return {
      ...session,
      user_id: user.id,
      email: user.email,
      nom: user.nom,
      prenom: user.prenom,
      role: user.role
    };
  }

  async deleteSession(token) {
    const index = this.data.sessions.findIndex(s => s.token === token);
    if (index !== -1) {
      this.data.sessions.splice(index, 1);
      await this.save();
    }
  }

  // Nettoyage des sessions expirées
  async cleanExpiredSessions() {
    const now = new Date();
    const initialCount = this.data.sessions.length;
    
    this.data.sessions = this.data.sessions.filter(s => new Date(s.expires_at) > now);
    
    if (this.data.sessions.length !== initialCount) {
      await this.save();
      console.log(`✓ ${initialCount - this.data.sessions.length} sessions expirées supprimées`);
    }
  }

  async getStats() {
    // Nettoyer les sessions expirées
    await this.cleanExpiredSessions();
    
    return {
      users: this.data.users.filter(u => u.actif).length,
      products: this.data.products.filter(p => p.actif).length,
      categories: this.data.categories.filter(c => c.actif).length,
      sessions: this.data.sessions.length
    };
  }

  async close() {
    await this.save();
    console.log('✓ Base de données JSON fermée');
  }
}

module.exports = JsonDatabase;
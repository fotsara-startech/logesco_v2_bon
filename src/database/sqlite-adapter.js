/**
 * Adaptateur SQLite simple pour remplacer Prisma en mode standalone
 * Évite les problèmes de compatibilité avec pkg
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

class SQLiteAdapter {
  constructor(databasePath) {
    this.dbPath = databasePath;
    this.db = null;
  }

  async connect() {
    return new Promise((resolve, reject) => {
      try {
        // Créer le dossier de la base de données s'il n'existe pas
        const dbDir = path.dirname(this.dbPath);
        if (!fs.existsSync(dbDir)) {
          fs.mkdirSync(dbDir, { recursive: true });
        }

        // Ouvrir la base de données
        this.db = new sqlite3.Database(this.dbPath, (err) => {
          if (err) {
            console.error('❌ Erreur connexion SQLite:', err);
            reject(err);
            return;
          }

          console.log(`✓ Base de données SQLite connectée: ${this.dbPath}`);
          
          // Activer les clés étrangères
          this.db.run('PRAGMA foreign_keys = ON', (err) => {
            if (err) {
              console.error('❌ Erreur activation foreign keys:', err);
              reject(err);
              return;
            }

            // Initialiser les tables
            this.initializeTables()
              .then(() => resolve(true))
              .catch(reject);
          });
        });
      } catch (error) {
        console.error('❌ Erreur connexion SQLite:', error);
        reject(error);
      }
    });
  }

  async initializeTables() {
    return new Promise((resolve, reject) => {
      // Créer les tables principales
      const tables = [
        // Table utilisateurs
        `CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          nom TEXT NOT NULL,
          prenom TEXT NOT NULL,
          role TEXT DEFAULT 'user',
          actif BOOLEAN DEFAULT true,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`,
        
        // Table sessions/tokens
        `CREATE TABLE IF NOT EXISTS user_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          token TEXT UNIQUE NOT NULL,
          refresh_token TEXT UNIQUE,
          expires_at DATETIME NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )`,
        
        // Table produits
        `CREATE TABLE IF NOT EXISTS products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          description TEXT,
          prix DECIMAL(10,2) NOT NULL,
          stock INTEGER DEFAULT 0,
          code_barre TEXT UNIQUE,
          category_id INTEGER,
          actif BOOLEAN DEFAULT true,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`,
        
        // Table catégories
        `CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          description TEXT,
          parent_id INTEGER,
          actif BOOLEAN DEFAULT true,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (parent_id) REFERENCES categories(id)
        )`,
        
        // Index pour les performances
        `CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`,
        `CREATE INDEX IF NOT EXISTS idx_products_code_barre ON products(code_barre)`,
        `CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions(token)`,
        `CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions(user_id)`
      ];

      let completed = 0;
      const total = tables.length;

      tables.forEach((sql, index) => {
        this.db.run(sql, (err) => {
          if (err) {
            console.error(`❌ Erreur création table ${index}:`, err);
          }
          
          completed++;
          if (completed === total) {
            console.log('✓ Tables SQLite initialisées');
            
            // Créer l'utilisateur admin par défaut
            this.createDefaultAdmin()
              .then(() => resolve())
              .catch(reject);
          }
        });
      });
    });
  }

  async createDefaultAdmin() {
    try {
      // Vérifier si un admin existe déjà
      const existingAdmin = this.db.prepare('SELECT id FROM users WHERE role = ? LIMIT 1').get('admin');
      
      if (!existingAdmin) {
        const bcrypt = require('bcrypt');
        const hashedPassword = await bcrypt.hash('admin123', 10);
        
        const stmt = this.db.prepare(`
          INSERT INTO users (email, password, nom, prenom, role, actif)
          VALUES (?, ?, ?, ?, ?, ?)
        `);
        
        stmt.run('admin@logesco.com', hashedPassword, 'Admin', 'LOGESCO', 'admin', true);
        console.log('✓ Utilisateur admin créé (admin@logesco.com / admin123)');
      }
    } catch (error) {
      console.error('⚠️ Erreur création admin:', error);
    }
  }

  // Méthodes pour les utilisateurs
  async findUserByEmail(email) {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT * FROM users WHERE email = ? AND actif = true', [email], (err, row) => {
        if (err) {
          console.error('❌ Erreur findUserByEmail:', err);
          resolve(null);
        } else {
          resolve(row || null);
        }
      });
    });
  }

  async findUserById(id) {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT * FROM users WHERE id = ? AND actif = true', [id], (err, row) => {
        if (err) {
          console.error('❌ Erreur findUserById:', err);
          resolve(null);
        } else {
          resolve(row || null);
        }
      });
    });
  }

  async createUser(userData) {
    return new Promise((resolve, reject) => {
      const sql = `
        INSERT INTO users (email, password, nom, prenom, role, actif)
        VALUES (?, ?, ?, ?, ?, ?)
      `;
      
      this.db.run(sql, [
        userData.email,
        userData.password,
        userData.nom,
        userData.prenom,
        userData.role || 'user',
        userData.actif !== false ? 1 : 0
      ], function(err) {
        if (err) {
          console.error('❌ Erreur createUser:', err);
          reject(err);
        } else {
          resolve({ id: this.lastID, ...userData });
        }
      });
    });
  }

  // Méthodes pour les sessions
  async createSession(userId, token, refreshToken, expiresAt) {
    try {
      const stmt = this.db.prepare(`
        INSERT INTO user_sessions (user_id, token, refresh_token, expires_at)
        VALUES (?, ?, ?, ?)
      `);
      
      const result = stmt.run(userId, token, refreshToken, expiresAt);
      return { id: result.lastInsertRowid };
    } catch (error) {
      console.error('❌ Erreur createSession:', error);
      throw error;
    }
  }

  async findSessionByToken(token) {
    try {
      const stmt = this.db.prepare(`
        SELECT s.*, u.email, u.nom, u.prenom, u.role
        FROM user_sessions s
        JOIN users u ON s.user_id = u.id
        WHERE s.token = ? AND s.expires_at > datetime('now') AND u.actif = true
      `);
      return stmt.get(token);
    } catch (error) {
      console.error('❌ Erreur findSessionByToken:', error);
      return null;
    }
  }

  async deleteSession(token) {
    try {
      const stmt = this.db.prepare('DELETE FROM user_sessions WHERE token = ?');
      stmt.run(token);
    } catch (error) {
      console.error('❌ Erreur deleteSession:', error);
    }
  }

  // Méthodes utilitaires
  async getStats() {
    try {
      const users = this.db.prepare('SELECT COUNT(*) as count FROM users WHERE actif = true').get();
      const products = this.db.prepare('SELECT COUNT(*) as count FROM products WHERE actif = true').get();
      const categories = this.db.prepare('SELECT COUNT(*) as count FROM categories WHERE actif = true').get();
      
      return {
        users: users.count,
        products: products.count,
        categories: categories.count
      };
    } catch (error) {
      console.error('❌ Erreur getStats:', error);
      return { users: 0, products: 0, categories: 0 };
    }
  }

  async close() {
    if (this.db) {
      this.db.close();
      console.log('✓ Base de données SQLite fermée');
    }
  }
}

module.exports = SQLiteAdapter;
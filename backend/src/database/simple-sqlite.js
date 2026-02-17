/**
 * Adaptateur SQLite simple et fonctionnel pour le mode standalone
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');

class SimpleSQLite {
  constructor(databasePath) {
    this.dbPath = databasePath;
    this.db = null;
  }

  async connect() {
    return new Promise((resolve, reject) => {
      // Créer le dossier si nécessaire
      const dbDir = path.dirname(this.dbPath);
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
      }

      this.db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          reject(err);
        } else {
          console.log(`✓ SQLite connecté: ${this.dbPath}`);
          this.initTables().then(resolve).catch(reject);
        }
      });
    });
  }

  async initTables() {
    return new Promise((resolve, reject) => {
      const sql = `
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          nom TEXT NOT NULL,
          prenom TEXT NOT NULL,
          role TEXT DEFAULT 'user',
          actif INTEGER DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS user_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          token TEXT UNIQUE NOT NULL,
          refresh_token TEXT,
          expires_at DATETIME NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
      `;

      this.db.exec(sql, (err) => {
        if (err) {
          reject(err);
        } else {
          console.log('✓ Tables créées');
          this.createAdmin().then(resolve).catch(reject);
        }
      });
    });
  }

  async createAdmin() {
    return new Promise(async (resolve, reject) => {
      // Vérifier si admin existe
      this.db.get('SELECT id FROM users WHERE email = ?', ['admin@logesco.com'], async (err, row) => {
        if (err) {
          reject(err);
          return;
        }

        if (!row) {
          // Créer admin
          const hashedPassword = await bcrypt.hash('admin123', 10);
          this.db.run(
            'INSERT INTO users (email, password, nom, prenom, role) VALUES (?, ?, ?, ?, ?)',
            ['admin@logesco.com', hashedPassword, 'Admin', 'LOGESCO', 'admin'],
            (err) => {
              if (err) {
                reject(err);
              } else {
                console.log('✓ Admin créé (admin@logesco.com / admin123)');
                resolve();
              }
            }
          );
        } else {
          console.log('✓ Admin existe déjà');
          resolve();
        }
      });
    });
  }

  // Méthodes utilisateur
  findUserByEmail(email) {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT * FROM users WHERE email = ? AND actif = 1', [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  findUserById(id) {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT * FROM users WHERE id = ? AND actif = 1', [id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  createUser(userData) {
    return new Promise((resolve, reject) => {
      this.db.run(
        'INSERT INTO users (email, password, nom, prenom, role, actif) VALUES (?, ?, ?, ?, ?, ?)',
        [userData.email, userData.password, userData.nom, userData.prenom, userData.role || 'user', 1],
        function(err) {
          if (err) reject(err);
          else resolve({ id: this.lastID, ...userData });
        }
      );
    });
  }

  // Méthodes session
  createSession(userId, token, refreshToken, expiresAt) {
    return new Promise((resolve, reject) => {
      this.db.run(
        'INSERT INTO user_sessions (user_id, token, refresh_token, expires_at) VALUES (?, ?, ?, ?)',
        [userId, token, refreshToken, expiresAt],
        function(err) {
          if (err) reject(err);
          else resolve({ id: this.lastID });
        }
      );
    });
  }

  findSessionByToken(token) {
    return new Promise((resolve, reject) => {
      const sql = `
        SELECT s.*, u.email, u.nom, u.prenom, u.role, u.id as user_id
        FROM user_sessions s
        JOIN users u ON s.user_id = u.id
        WHERE s.token = ? AND s.expires_at > datetime('now') AND u.actif = 1
      `;
      
      this.db.get(sql, [token], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  deleteSession(token) {
    return new Promise((resolve, reject) => {
      this.db.run('DELETE FROM user_sessions WHERE token = ?', [token], (err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }

  getStats() {
    return new Promise((resolve, reject) => {
      this.db.get('SELECT COUNT(*) as users FROM users WHERE actif = 1', (err, row) => {
        if (err) reject(err);
        else resolve({ users: row.users, products: 0, categories: 0 });
      });
    });
  }

  close() {
    if (this.db) {
      this.db.close();
      console.log('✓ SQLite fermé');
    }
  }
}

module.exports = SimpleSQLite;
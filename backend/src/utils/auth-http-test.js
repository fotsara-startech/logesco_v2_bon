/**
 * Test HTTP des endpoints d'authentification
 * Teste les routes d'auth via des requêtes HTTP réelles
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api/v1';

class AuthHTTPTester {
  constructor() {
    this.tokens = {};
    this.testUser = {
      nomUtilisateur: 'testuser_http',
      email: 'testhttp@logesco.com',
      motDePasse: 'password123'
    };
  }

  /**
   * Teste l'inscription d'un utilisateur
   */
  async testRegister() {
    console.log('\n📝 Test HTTP: Inscription utilisateur');

    try {
      const response = await axios.post(`${BASE_URL}/auth/register`, this.testUser);

      console.log('✅ Inscription réussie:', {
        status: response.status,
        userId: response.data.data.utilisateur.id,
        hasTokens: !!(response.data.data.accessToken && response.data.data.refreshToken)
      });

      // Stocker les tokens pour les tests suivants
      this.tokens = {
        accessToken: response.data.data.accessToken,
        refreshToken: response.data.data.refreshToken
      };

      return true;
    } catch (error) {
      console.error('❌ Erreur inscription:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Teste la connexion
   */
  async testLogin() {
    console.log('\n🔐 Test HTTP: Connexion utilisateur');

    try {
      const response = await axios.post(`${BASE_URL}/auth/login`, {
        nomUtilisateur: this.testUser.nomUtilisateur,
        motDePasse: this.testUser.motDePasse
      });

      console.log('✅ Connexion réussie:', {
        status: response.status,
        tokenType: response.data.data.tokenType,
        hasAccessToken: !!response.data.data.accessToken
      });

      // Mettre à jour les tokens
      this.tokens = {
        accessToken: response.data.data.accessToken,
        refreshToken: response.data.data.refreshToken
      };

      return true;
    } catch (error) {
      console.error('❌ Erreur connexion:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Teste la vérification du token
   */
  async testVerify() {
    console.log('\n🔍 Test HTTP: Vérification token');

    try {
      const response = await axios.get(`${BASE_URL}/auth/verify`, {
        headers: {
          'Authorization': `Bearer ${this.tokens.accessToken}`
        }
      });

      console.log('✅ Token vérifié:', {
        status: response.status,
        valid: response.data.data.valid,
        userId: response.data.data.user.id
      });

      return true;
    } catch (error) {
      console.error('❌ Erreur vérification:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Teste les informations utilisateur
   */
  async testMe() {
    console.log('\n👤 Test HTTP: Informations utilisateur');

    try {
      const response = await axios.get(`${BASE_URL}/auth/me`, {
        headers: {
          'Authorization': `Bearer ${this.tokens.accessToken}`
        }
      });

      console.log('✅ Informations récupérées:', {
        status: response.status,
        nomUtilisateur: response.data.data.nomUtilisateur,
        email: response.data.data.email
      });

      return true;
    } catch (error) {
      console.error('❌ Erreur informations:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Teste le rafraîchissement du token
   */
  async testRefresh() {
    console.log('\n🔄 Test HTTP: Rafraîchissement token');

    try {
      const response = await axios.post(`${BASE_URL}/auth/refresh`, {
        refreshToken: this.tokens.refreshToken
      });

      console.log('✅ Token rafraîchi:', {
        status: response.status,
        nouveauToken: !!response.data.data.accessToken,
        nouveauRefresh: !!response.data.data.refreshToken
      });

      // Mettre à jour les tokens
      this.tokens = {
        accessToken: response.data.data.accessToken,
        refreshToken: response.data.data.refreshToken
      };

      return true;
    } catch (error) {
      console.error('❌ Erreur rafraîchissement:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Teste la déconnexion
   */
  async testLogout() {
    console.log('\n👋 Test HTTP: Déconnexion');

    try {
      const response = await axios.post(`${BASE_URL}/auth/logout`, {
        refreshToken: this.tokens.refreshToken
      });

      console.log('✅ Déconnexion réussie:', {
        status: response.status,
        message: response.data.message
      });

      return true;
    } catch (error) {
      console.error('❌ Erreur déconnexion:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Teste les erreurs d'authentification
   */
  async testErrors() {
    console.log('\n❌ Test HTTP: Gestion des erreurs');

    // Test connexion avec mauvais identifiants
    try {
      await axios.post(`${BASE_URL}/auth/login`, {
        nomUtilisateur: 'inexistant',
        motDePasse: 'wrongpassword'
      });
      console.log('❌ Ce test aurait dû échouer');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Erreur 401 correctement retournée pour mauvais identifiants');
      } else {
        console.log('⚠️  Erreur inattendue:', error.response?.status);
      }
    }

    // Test accès sans token
    try {
      await axios.get(`${BASE_URL}/auth/me`);
      console.log('❌ Ce test aurait dû échouer');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Erreur 401 correctement retournée pour accès sans token');
      } else {
        console.log('⚠️  Erreur inattendue:', error.response?.status);
      }
    }

    // Test avec token invalide
    try {
      await axios.get(`${BASE_URL}/auth/me`, {
        headers: {
          'Authorization': 'Bearer invalid.token.here'
        }
      });
      console.log('❌ Ce test aurait dû échouer');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Erreur 401 correctement retournée pour token invalide');
      } else {
        console.log('⚠️  Erreur inattendue:', error.response?.status);
      }
    }
  }

  /**
   * Nettoie les données de test
   */
  async cleanup() {
    console.log('\n🧹 Nettoyage des données de test...');

    // Note: En production, il faudrait un endpoint admin pour supprimer les utilisateurs de test
    // Pour l'instant, on laisse le serveur gérer le nettoyage
    console.log('✅ Nettoyage terminé (géré côté serveur)');
  }

  /**
   * Exécute tous les tests
   */
  async runAllTests() {
    console.log('🚀 Démarrage des tests HTTP d\'authentification');
    console.log(`🌐 URL de base: ${BASE_URL}`);

    try {
      // Vérifier que le serveur est accessible
      await axios.get(`${BASE_URL.replace('/api/v1', '')}/`);
      console.log('✅ Serveur accessible');

      const tests = [
        () => this.testRegister(),
        () => this.testLogin(),
        () => this.testVerify(),
        () => this.testMe(),
        () => this.testRefresh(),
        () => this.testLogout(),
        () => this.testErrors()
      ];

      let passed = 0;
      let failed = 0;

      for (const test of tests) {
        try {
          const result = await test();
          if (result) passed++;
          else failed++;
        } catch (error) {
          console.error('💥 Erreur test:', error.message);
          failed++;
        }
      }

      await this.cleanup();

      console.log('\n📊 Résultats des tests HTTP:');
      console.log(`✅ Tests réussis: ${passed}`);
      console.log(`❌ Tests échoués: ${failed}`);

      if (failed === 0) {
        console.log('🎉 Tous les tests HTTP d\'authentification sont passés!');
        return true;
      } else {
        console.log('⚠️  Certains tests ont échoué');
        return false;
      }

    } catch (error) {
      console.error('💥 Erreur lors des tests HTTP:', error.message);
      console.log('🔧 Assurez-vous que le serveur est démarré sur le port 8080');
      return false;
    }
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  const tester = new AuthHTTPTester();
  tester.runAllTests()
    .then((success) => {
      process.exit(success ? 0 : 1);
    })
    .catch((error) => {
      console.error('💥 Échec des tests HTTP:', error);
      process.exit(1);
    });
}

module.exports = AuthHTTPTester;
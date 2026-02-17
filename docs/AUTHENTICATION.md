# Authentification JWT - LOGESCO v2

## Vue d'ensemble

Le système d'authentification LOGESCO utilise JSON Web Tokens (JWT) pour sécuriser l'API. Il fournit une authentification stateless avec des access tokens de courte durée et des refresh tokens pour le renouvellement.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client App    │    │   Auth Service   │    │   Database      │
│                 │    │                  │    │                 │
│ - Access Token  │◄──►│ - JWT Generation │◄──►│ - Users         │
│ - Refresh Token │    │ - Token Verify   │    │ - Sessions      │
│ - Auto Refresh  │    │ - Password Hash  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Configuration

### Variables d'Environnement

```bash
# JWT Configuration
JWT_SECRET=your-super-secret-key-here
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Base de données (détection automatique)
DATABASE_URL=file:./database/logesco.db  # SQLite local
# ou
DATABASE_URL=postgresql://user:pass@host:5432/db  # PostgreSQL cloud
```

### Configuration par Défaut

```javascript
{
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-key',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '24h',
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
}
```

## Endpoints d'Authentification

### Base URL
```
http://localhost:8080/api/v1/auth
```

### 1. Inscription - `POST /register`

Crée un nouveau compte utilisateur.

**Requête:**
```json
{
  "nomUtilisateur": "johndoe",
  "email": "john@example.com",
  "motDePasse": "password123"
}
```

**Réponse (201):**
```json
{
  "success": true,
  "message": "Inscription réussie",
  "data": {
    "utilisateur": {
      "id": 1,
      "nomUtilisateur": "johndoe",
      "email": "john@example.com",
      "dateCreation": "2024-01-01T00:00:00.000Z",
      "dateModification": "2024-01-01T00:00:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "24h",
    "tokenType": "Bearer"
  }
}
```

**Erreurs:**
- `400` - Données de validation invalides
- `409` - Nom d'utilisateur ou email déjà utilisé

### 2. Connexion - `POST /login`

Authentifie un utilisateur existant.

**Requête:**
```json
{
  "nomUtilisateur": "johndoe",
  "motDePasse": "password123"
}
```

**Réponse (200):**
```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "utilisateur": {
      "id": 1,
      "nomUtilisateur": "johndoe",
      "email": "john@example.com",
      "dateCreation": "2024-01-01T00:00:00.000Z",
      "dateModification": "2024-01-01T00:00:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "24h",
    "tokenType": "Bearer"
  }
}
```

**Erreurs:**
- `401` - Nom d'utilisateur ou mot de passe incorrect
- `429` - Trop de tentatives (rate limiting)

### 3. Rafraîchissement - `POST /refresh`

Renouvelle un access token avec un refresh token valide.

**Requête:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Réponse (200):**
```json
{
  "success": true,
  "message": "Token rafraîchi avec succès",
  "data": {
    "utilisateur": {
      "id": 1,
      "nomUtilisateur": "johndoe",
      "email": "john@example.com"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "24h",
    "tokenType": "Bearer"
  }
}
```

**Erreurs:**
- `401` - Refresh token invalide ou expiré

### 4. Déconnexion - `POST /logout`

Invalide un refresh token.

**Requête:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Réponse (200):**
```json
{
  "success": true,
  "message": "Déconnexion réussie"
}
```

### 5. Informations Utilisateur - `GET /me`

Récupère les informations de l'utilisateur authentifié.

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Réponse (200):**
```json
{
  "success": true,
  "message": "Informations utilisateur récupérées",
  "data": {
    "id": 1,
    "nomUtilisateur": "johndoe",
    "email": "john@example.com"
  }
}
```

### 6. Changement de Mot de Passe - `POST /change-password`

Change le mot de passe de l'utilisateur authentifié.

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Requête:**
```json
{
  "ancienMotDePasse": "password123",
  "nouveauMotDePasse": "newpassword456"
}
```

**Réponse (200):**
```json
{
  "success": true,
  "message": "Mot de passe modifié avec succès"
}
```

### 7. Déconnexion Globale - `POST /logout-all`

Invalide toutes les sessions de l'utilisateur.

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Réponse (200):**
```json
{
  "success": true,
  "message": "Toutes les sessions ont été fermées"
}
```

## Utilisation Côté Client

### 1. Authentification Initiale

```javascript
// Inscription
const registerResponse = await fetch('/api/v1/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    nomUtilisateur: 'johndoe',
    email: 'john@example.com',
    motDePasse: 'password123'
  })
});

const { data } = await registerResponse.json();
const { accessToken, refreshToken } = data;

// Stocker les tokens (localStorage, sessionStorage, ou cookie sécurisé)
localStorage.setItem('accessToken', accessToken);
localStorage.setItem('refreshToken', refreshToken);
```

### 2. Requêtes Authentifiées

```javascript
// Fonction helper pour les requêtes authentifiées
async function authenticatedFetch(url, options = {}) {
  const accessToken = localStorage.getItem('accessToken');
  
  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  });

  // Si le token est expiré, essayer de le rafraîchir
  if (response.status === 401) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      // Réessayer la requête avec le nouveau token
      return authenticatedFetch(url, options);
    } else {
      // Rediriger vers la page de connexion
      window.location.href = '/login';
      return;
    }
  }

  return response;
}
```

### 3. Rafraîchissement Automatique

```javascript
async function refreshAccessToken() {
  try {
    const refreshToken = localStorage.getItem('refreshToken');
    
    const response = await fetch('/api/v1/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ refreshToken })
    });

    if (response.ok) {
      const { data } = await response.json();
      localStorage.setItem('accessToken', data.accessToken);
      localStorage.setItem('refreshToken', data.refreshToken);
      return true;
    } else {
      // Refresh token invalide, déconnecter l'utilisateur
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      return false;
    }
  } catch (error) {
    console.error('Erreur rafraîchissement token:', error);
    return false;
  }
}
```

### 4. Déconnexion

```javascript
async function logout() {
  try {
    const refreshToken = localStorage.getItem('refreshToken');
    
    await fetch('/api/v1/auth/logout', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ refreshToken })
    });
  } catch (error) {
    console.error('Erreur déconnexion:', error);
  } finally {
    // Nettoyer le stockage local
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    window.location.href = '/login';
  }
}
```

## Sécurité

### Rate Limiting

- **Login:** 5 tentatives par 15 minutes par IP
- **Register:** 3 inscriptions par heure par IP
- **Refresh:** 10 rafraîchissements par 15 minutes par utilisateur

### Headers de Sécurité

Tous les endpoints d'authentification incluent automatiquement :

```
Cache-Control: no-store, no-cache, must-revalidate, proxy-revalidate
Pragma: no-cache
Expires: 0
Surrogate-Control: no-store
```

### Bonnes Pratiques

1. **Stockage des Tokens**
   - Utiliser `httpOnly` cookies pour les refresh tokens en production
   - Éviter `localStorage` pour les données sensibles
   - Considérer `sessionStorage` pour les access tokens

2. **Gestion des Erreurs**
   - Ne jamais exposer d'informations sensibles dans les messages d'erreur
   - Logger les tentatives d'authentification suspectes
   - Implémenter un système de blocage temporaire après plusieurs échecs

3. **Rotation des Tokens**
   - Les refresh tokens sont automatiquement renouvelés à chaque utilisation
   - Implémenter une rotation régulière des secrets JWT en production

## Middleware d'Authentification

### Utilisation dans les Routes

```javascript
const { authenticateToken } = require('../middleware/auth');

// Route protégée
router.get('/protected', authenticateToken(authService), (req, res) => {
  // req.user contient les informations de l'utilisateur authentifié
  res.json({
    message: 'Accès autorisé',
    user: req.user
  });
});

// Route avec authentification optionnelle
router.get('/public', optionalAuth(authService), (req, res) => {
  // req.user peut être null si pas authentifié
  const message = req.user 
    ? `Bonjour ${req.user.nomUtilisateur}` 
    : 'Bonjour visiteur';
  
  res.json({ message });
});
```

### Middleware Disponibles

- `authenticateToken(authService)` - Authentification obligatoire
- `optionalAuth(authService)` - Authentification optionnelle
- `requireOwnership(userIdField)` - Vérification de propriété de ressource
- `userRateLimit(maxRequests, windowMs)` - Rate limiting par utilisateur
- `validateRefreshToken` - Validation du format des refresh tokens
- `securityHeaders` - Headers de sécurité automatiques

## Tests

### Tests Unitaires

```bash
# Tester le service d'authentification
npm run test:auth

# Tester toutes les validations
npm run test:validation

# Tous les tests
npm run test
```

### Tests HTTP

```bash
# Démarrer le serveur
npm run dev

# Dans un autre terminal, tester les endpoints
node src/utils/auth-http-test.js
```

## Dépannage

### Erreurs Communes

1. **"Token invalide ou expiré"**
   - Vérifier que le token n'est pas corrompu
   - Vérifier la configuration JWT_SECRET
   - Essayer de rafraîchir le token

2. **"Refresh token invalide"**
   - Le refresh token a peut-être expiré (7 jours par défaut)
   - L'utilisateur doit se reconnecter

3. **"Trop de requêtes"**
   - Rate limiting activé
   - Attendre la fin de la fenêtre de temps
   - Vérifier les logs pour détecter des attaques

### Logs de Debug

```javascript
// Activer les logs détaillés
process.env.LOG_LEVEL = 'debug';

// Les logs incluront :
// - Tentatives de connexion
// - Génération/vérification de tokens
// - Rate limiting
// - Erreurs d'authentification
```

## Migration et Mise à Jour

### Changement de Secret JWT

```javascript
// 1. Générer un nouveau secret
const newSecret = crypto.randomBytes(64).toString('hex');

// 2. Mettre à jour la configuration
process.env.JWT_SECRET = newSecret;

// 3. Invalider tous les tokens existants (optionnel)
await authService.logoutAllSessions();
```

### Mise à Jour de la Durée des Tokens

```javascript
// Modifier dans la configuration
process.env.JWT_EXPIRES_IN = '12h';  // Réduire à 12h
process.env.JWT_REFRESH_EXPIRES_IN = '30d';  // Augmenter à 30 jours
```

## Intégration avec Flutter

L'authentification est conçue pour s'intégrer facilement avec l'application Flutter LOGESCO. Voir la documentation Flutter pour les détails d'implémentation côté client avec GetX et les intercepteurs HTTP.
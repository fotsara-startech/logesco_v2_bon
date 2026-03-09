# Correction: Durée d'Expiration du Token JWT

## Problème

Les tokens JWT expiraient trop rapidement (24 heures), ce qui causait des déconnexions fréquentes et des erreurs "Token invalide ou expiré" lors de l'utilisation de l'application.

## Solution Appliquée

### Modification de la Configuration JWT

**Fichier modifié:** `backend/src/config/environment.js`

**Avant:**
```javascript
this.jwtConfig = {
  secret: process.env.JWT_SECRET || 'dev-secret-key',
  expiresIn: process.env.JWT_EXPIRES_IN || '24h',        // ❌ 24 heures
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'  // ❌ 7 jours
};
```

**Après:**
```javascript
this.jwtConfig = {
  secret: process.env.JWT_SECRET || 'dev-secret-key',
  expiresIn: process.env.JWT_EXPIRES_IN || '365d',       // ✅ 365 jours (1 an)
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '365d'  // ✅ 365 jours (1 an)
};
```

## Résultat

- ✅ Les tokens JWT sont maintenant valides pendant 365 jours
- ✅ Les refresh tokens sont également valides pendant 365 jours
- ✅ Plus de déconnexions intempestives
- ✅ Meilleure expérience utilisateur

## Notes de Sécurité

⚠️ **Important:** Cette configuration est adaptée pour un environnement de développement ou une application locale. 

Pour un environnement de production avec accès externe, il est recommandé de:
- Utiliser une durée plus courte (24h-7j pour l'access token)
- Implémenter un système de révocation de tokens
- Utiliser HTTPS obligatoirement
- Mettre en place un système de refresh automatique

## Configuration via Variables d'Environnement

Vous pouvez également configurer la durée via les variables d'environnement dans le fichier `.env`:

```env
JWT_EXPIRES_IN=365d
JWT_REFRESH_EXPIRES_IN=365d
```

Formats acceptés:
- `60s` = 60 secondes
- `10m` = 10 minutes
- `2h` = 2 heures
- `7d` = 7 jours
- `30d` = 30 jours
- `365d` = 365 jours

## Redémarrage Requis

⚠️ **Important:** Le backend doit être redémarré pour que les changements prennent effet.

Les utilisateurs déjà connectés devront se reconnecter pour obtenir un nouveau token avec la nouvelle durée d'expiration.

## Vérification

Pour vérifier que la configuration est appliquée:

1. Redémarrer le backend
2. Se connecter à l'application
3. Le token reçu sera valide pendant 365 jours
4. Plus d'erreurs "Token invalide ou expiré" pendant l'utilisation normale

## Date de Correction

26 février 2026

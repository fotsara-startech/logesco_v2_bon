# Guide de Déploiement Multi-Clients sur Vercel

## Architecture

Chaque client dispose de :
- ✅ Son propre projet Vercel
- ✅ Son propre frontend avec URL backend configurée
- ✅ Son propre domaine personnalisé (optionnel)
- ✅ Son backend dédié

## Prérequis

1. Compte Vercel configuré (`vercel login`)
2. Flutter installé
3. PowerShell

## 📋 Configuration des Clients

Éditez `clients-config.json` pour ajouter/modifier des clients :

```json
{
  "clients": [
    {
      "name": "client-pharmacie",
      "displayName": "Pharmacie Centrale",
      "projectName": "logesco-pharmacie",
      "backendUrl": "https://api-pharmacie.example.com/api/v1",
      "customDomain": "pharmacie.logesco.com"
    }
  ]
}
```

## 🚀 Déploiement

### Option 1 : Déployer un seul client

```powershell
.\deploy-client.ps1 `
    -ClientName "client-pharmacie" `
    -BackendUrl "https://api-pharmacie.example.com/api/v1" `
    -ProjectName "logesco-pharmacie" `
    -Production
```

**Paramètres :**
- `ClientName` : Identifiant unique du client
- `BackendUrl` : URL complète de l'API backend du client
- `ProjectName` : Nom du projet sur Vercel (doit être unique)
- `-Production` : Flag pour déployer en production (optionnel, sinon preview)

### Option 2 : Déployer tous les clients configurés

```powershell
# Preview pour tous
.\deploy-all-clients.ps1

# Production pour tous
.\deploy-all-clients.ps1 -Production
```

## 📦 Ce qui est déployé

Pour chaque client, le script :

1. ✅ Compile Flutter Web avec la configuration spécifique :
   - `IS_CLIENT_MODE=true`
   - `BASE_URL=<url-backend-client>`
   - `ENABLE_LICENSE_CONTROL=false`
   - Renderer: CanvasKit

2. ✅ Crée un projet Vercel dédié

3. ✅ Configure les headers de sécurité

4. ✅ Déploie sur Vercel

## 🌐 URLs de Déploiement

Après déploiement, vous obtenez :

- **Preview** : `https://<project-name>-xxx.vercel.app`
- **Production** : `https://<project-name>.vercel.app`
- **Custom Domain** : À configurer sur Vercel Dashboard

## 🔧 Configuration d'un Domaine Personnalisé

1. Déployez le client une première fois
2. Allez sur https://vercel.com/black-tech-corps/<project-name>/settings/domains
3. Ajoutez votre domaine personnalisé (ex: `client.logesco.com`)
4. Configurez les DNS selon les instructions Vercel

## 📊 Gestion des Clients

### Ajouter un nouveau client

1. Ajoutez une entrée dans `clients-config.json`
2. Lancez le déploiement :
```powershell
.\deploy-client.ps1 `
    -ClientName "nouveau-client" `
    -BackendUrl "https://api-nouveau.example.com/api/v1" `
    -ProjectName "logesco-nouveau-client"
```

### Mettre à jour un client existant

```powershell
# Redéployer avec les nouvelles modifications
.\deploy-client.ps1 `
    -ClientName "client-existant" `
    -BackendUrl "https://api-client.example.com/api/v1" `
    -ProjectName "logesco-client" `
    -Production
```

## 🔍 Vérification

Après déploiement :

1. Ouvrez l'URL fournie dans le terminal
2. Vérifiez que l'app se connecte au bon backend
3. Testez une authentification
4. Vérifiez dans la console dev que les appels API vont vers le bon backend

## ⚠️ Points Importants

- **Nom de projet unique** : Chaque `projectName` doit être unique sur Vercel
- **Backend accessible** : L'URL backend doit être accessible publiquement avec CORS configuré
- **Build time** : Comptez ~2-3 minutes par client pour le build + déploiement
- **Coûts Vercel** : Plan gratuit = 100 GB bandwidth/mois par projet

## 🔐 Sécurité

Le script configure automatiquement :
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Headers CORS (à configurer côté backend)

## 🆘 Dépannage

### Erreur "Project name already exists"
→ Changez le `projectName` dans clients-config.json

### Build Flutter échoue
→ Vérifiez que Flutter est installé : `flutter doctor`

### Backend non accessible
→ Vérifiez l'URL backend et que CORS est configuré

### Déploiement Vercel échoue
→ Vérifiez que vous êtes connecté : `vercel whoami`

## 📚 Exemples Complets

### Client 1 : Pharmacie

```powershell
.\deploy-client.ps1 `
    -ClientName "pharmacie-centrale" `
    -BackendUrl "https://backend-pharmacie.example.com/api/v1" `
    -ProjectName "logesco-pharmacie-centrale" `
    -Production
```

### Client 2 : Supermarché

```powershell
.\deploy-client.ps1 `
    -ClientName "super-market" `
    -BackendUrl "https://backend-market.example.com/api/v1" `
    -ProjectName "logesco-super-market" `
    -Production
```

## 🎯 Workflow Recommandé

1. **Développement** : Testez localement avec `flutter run -d chrome`
2. **Preview** : Déployez sans `-Production` pour tester
3. **Validation Client** : Partagez l'URL preview au client
4. **Production** : Déployez avec `-Production` après validation
5. **Custom Domain** : Configurez le domaine personnalisé

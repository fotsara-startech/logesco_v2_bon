# Guide de Déploiement Backend LOGESCO - Solution Finale

## Problème Résolu

**Erreur initiale:**
```
Cannot find module 'C:\snapshot\backend\node_modules\.prisma\client\index.js'
```

**Cause:** Prisma ne peut pas être compilé en exécutable avec `pkg` car il génère des fichiers natifs (`.node`) dynamiquement.

**Solution:** Package portable Node.js au lieu d'un exécutable compilé.

---

## Solution Implémentée

### 1. Package Portable (Recommandé)

Au lieu de compiler en `.exe`, nous créons un package Node.js complet qui fonctionne parfaitement avec Prisma.

#### Construction du Package

```batch
build-portable-backend.bat
```

Cela crée le dossier `dist-portable\` avec:
- Code source complet
- Toutes les dépendances Node.js
- Client Prisma généré
- Scripts de démarrage

#### Démarrage du Backend

```batch
cd dist-portable
start-backend.bat
```

Le serveur démarre automatiquement sur **http://localhost:8080**

---

## Structure du Package Portable

```
dist-portable/
├── start-backend.bat          # Double-cliquer pour démarrer
├── install-service.bat        # Installer comme service Windows
├── src/                       # Code source
├── node_modules/              # Dépendances (inclus Prisma)
├── prisma/                    # Schéma de base de données
├── database/                  # Base de données SQLite
├── logs/                      # Fichiers de logs
├── uploads/                   # Fichiers uploadés
└── README.txt                 # Instructions
```

---

## Démarrage Automatique au Boot

### Option 1: Raccourci dans le Dossier de Démarrage

1. Créer un raccourci vers `start-backend.bat`
2. Copier le raccourci dans:
   ```
   %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
   ```

### Option 2: Service Windows avec NSSM (Recommandé)

1. Télécharger NSSM: https://nssm.cc/download
2. Extraire `nssm.exe` dans le dossier `dist-portable\`
3. Exécuter en tant qu'administrateur:
   ```batch
   cd dist-portable
   install-service.bat
   ```

Le service démarre automatiquement au boot Windows.

### Option 3: Tâche Planifiée Windows

1. Ouvrir le Planificateur de tâches
2. Créer une tâche de base
3. Déclencheur: **Au démarrage**
4. Action: Démarrer `dist-portable\start-backend.bat`
5. Cocher "Exécuter même si l'utilisateur n'est pas connecté"

---

## Distribution sur Machines Clientes

### Prérequis

- **Node.js 18+** doit être installé
- Télécharger depuis: https://nodejs.org/

### Installation

1. Copier **tout** le dossier `dist-portable\` vers la machine cible
2. Double-cliquer sur `start-backend.bat`
3. Le serveur crée automatiquement:
   - Base de données SQLite
   - Utilisateur admin (admin/admin123)
   - Catégories de base
   - Logs

---

## Configuration

### Fichier .env

Le fichier `.env` est créé automatiquement au premier démarrage. Vous pouvez le modifier:

```env
NODE_ENV=production
PORT=8080
DATABASE_URL=file:./database/logesco.db
JWT_SECRET=<généré automatiquement>
JWT_EXPIRES_IN=24h
CORS_ORIGIN=*
LOG_LEVEL=info
```

### Changer le Port

Modifier `PORT=8080` dans le fichier `.env`

---

## Vérification

### Test de l'API

```powershell
curl http://localhost:8080/health
```

Réponse attendue:
```json
{
  "status": "OK",
  "timestamp": "2025-11-10T...",
  "environment": "local",
  "database": "sqlite",
  "version": "1.0.0"
}
```

### Connexion Admin

- **URL**: http://localhost:8080/api/v1/auth/login
- **Username**: admin
- **Password**: admin123

---

## Dépannage

### Le serveur ne démarre pas

1. Vérifier que Node.js est installé: `node --version`
2. Vérifier les logs dans `dist-portable\logs\error.log`
3. Vérifier que le port 8080 n'est pas utilisé

### Erreur "Cannot find module"

Reconstruire le package:
```batch
build-portable-backend.bat
```

### Erreur Prisma

Régénérer le client:
```batch
cd dist-portable
npx prisma generate
```

### Base de données corrompue

Supprimer `dist-portable\database\logesco.db` et redémarrer le serveur.

---

## Fichiers Créés

### Scripts de Build

- `backend/build-portable.js` - Script de construction du package
- `build-portable-backend.bat` - Lanceur de build

### Scripts de Démarrage

- `dist-portable/start-backend.bat` - Démarrage manuel
- `dist-portable/install-service.bat` - Installation comme service

### Configuration Prisma

- `backend/src/config/prisma-loader.js` - Chargeur Prisma compatible
- `backend/src/config/prisma-client.js` - Client Prisma singleton

---

## Avantages de cette Solution

✅ **Fonctionne avec Prisma** - Pas de problème de compilation  
✅ **Facile à distribuer** - Un seul dossier à copier  
✅ **Démarrage automatique** - Plusieurs options disponibles  
✅ **Logs complets** - Debugging facile  
✅ **Configuration flexible** - Fichier .env modifiable  
✅ **Base de données locale** - SQLite intégré  

---

## Résumé des Commandes

```batch
# Construction
build-portable-backend.bat

# Test local
cd dist-portable
start-backend.bat

# Installation comme service (admin requis)
cd dist-portable
install-service.bat

# Vérification
curl http://localhost:8080/health
```

---

## Support

Pour toute question ou problème:
1. Vérifier les logs dans `dist-portable\logs\`
2. Consulter `SOLUTION_PRISMA_PKG.md` pour plus de détails
3. Vérifier que Node.js 18+ est installé

---

**Le backend est maintenant 100% fonctionnel et prêt pour la production! 🎉**

# Guide Rapide - Envoyer LOGESCO au Client

## 🚀 Méthode Simple (Recommandée)

### 1. Préparer le Package

```batch
preparer-pour-client.bat
```

Ce script fait **tout automatiquement**:
- ✅ Construit le backend portable
- ✅ Construit l'application Flutter
- ✅ Crée un package complet prêt à envoyer
- ✅ Génère les scripts de démarrage
- ✅ Crée les instructions pour le client

### 2. Envoyer au Client

Compresser et envoyer **tout le dossier**:
```
release\LOGESCO-Client\
```

**Taille**: ~200 MB (compressé: ~80-100 MB)

### 3. Instructions pour le Client

Le client doit:
1. **Installer Node.js 18+** (https://nodejs.org/)
2. **Extraire** le dossier reçu
3. **Double-cliquer** sur `DEMARRER-LOGESCO.bat`

C'est tout! 🎉

---

## 📦 Contenu du Package Client

```
LOGESCO-Client/
├── DEMARRER-LOGESCO.bat    ← Double-cliquer ici!
├── README.txt               ← Instructions
├── backend/                 ← Serveur (Node.js)
│   ├── start-backend.bat
│   ├── install-service.bat
│   ├── src/
│   ├── node_modules/        ← IMPORTANT: Ne pas supprimer!
│   └── prisma/
└── app/                     ← Application
    ├── logesco_v2.exe
    └── data/
```

---

## 🔧 Autres Options

### Option A: Backend Seul (Serveur Dédié)

```batch
build-portable-backend.bat
```

Envoyer: `dist-portable\` (~150 MB)

### Option B: Application Seule

```batch
cd logesco_v2
flutter build windows --release
```

Envoyer: `logesco_v2\build\windows\x64\runner\Release\` (~50 MB)

### Option C: Build Complet (Ancien)

```batch
build-production.bat
```

Envoyer: `release\LOGESCO\`

---

## ✅ Vérification Avant Envoi

### Checklist

- [ ] Le dossier `backend\node_modules\` existe et est complet
- [ ] Le fichier `backend\start-backend.bat` existe
- [ ] Le fichier `app\logesco_v2.exe` existe
- [ ] Le fichier `DEMARRER-LOGESCO.bat` existe
- [ ] Le fichier `README.txt` existe avec les instructions

### Test Local

```batch
cd release\LOGESCO-Client
DEMARRER-LOGESCO.bat
```

Vérifier:
1. Le backend démarre (fenêtre console)
2. L'application s'ouvre
3. Connexion possible avec admin/admin123

---

## 📝 Informations pour le Client

### Prérequis

- **Windows 10/11** (64-bit)
- **Node.js 18+** (obligatoire pour le backend)
  - Télécharger: https://nodejs.org/
  - Installer la version LTS (Long Term Support)

### Première Connexion

- **URL**: http://localhost:8080 (automatique)
- **Username**: admin
- **Password**: admin123

⚠️ **Important**: Changer le mot de passe après la première connexion!

### Démarrage Automatique

Pour que le backend démarre au boot Windows:
1. Ouvrir le dossier `backend\`
2. Clic droit sur `install-service.bat`
3. "Exécuter en tant qu'administrateur"

---

## 🆘 Dépannage Client

### "Node.js n'est pas reconnu"

**Solution**: Installer Node.js depuis https://nodejs.org/

### "Le port 8080 est déjà utilisé"

**Solution**: 
1. Ouvrir `backend\.env`
2. Changer `PORT=8080` en `PORT=8081`
3. Redémarrer

### "Cannot find module"

**Solution**: Le dossier `node_modules` est manquant ou incomplet.
Demander un nouveau package.

### Backend ne démarre pas

**Solution**:
1. Vérifier Node.js: `node --version`
2. Consulter: `backend\logs\error.log`
3. Redémarrer Windows

---

## 📊 Comparaison des Méthodes

| Méthode | Taille | Prérequis | Facilité |
|---------|--------|-----------|----------|
| **Package Complet** | ~200 MB | Node.js | ⭐⭐⭐⭐⭐ |
| Backend Seul | ~150 MB | Node.js | ⭐⭐⭐ |
| App Seule | ~50 MB | Backend externe | ⭐⭐ |

**Recommandation**: Utiliser le **Package Complet** pour la plupart des clients.

---

## 🎯 Résumé Ultra-Rapide

```batch
# Vous (Développeur)
preparer-pour-client.bat
# → Compresser release\LOGESCO-Client\ en ZIP
# → Envoyer au client

# Client
# 1. Installer Node.js
# 2. Extraire le ZIP
# 3. Double-cliquer DEMARRER-LOGESCO.bat
# 4. Se connecter: admin / admin123
```

**C'est tout!** 🚀

---

## 📞 Support

Pour toute question:
- Consulter: `GUIDE_DEPLOIEMENT_BACKEND_FINAL.md`
- Consulter: `FICHIERS_POUR_CLIENT.md`
- Vérifier les logs: `backend\logs\`

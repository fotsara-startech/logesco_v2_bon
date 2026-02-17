# 🚀 LOGESCO - Démarrage Rapide

## ✅ Configuration Complétée

Tous les ports ont été configurés sur **3002** (pas 8080):
- ✅ `ApiConfig` - Port 3002
- ✅ `AppConfig` - Port 3002  
- ✅ `EnvironmentConfig` - Port 3002
- ✅ `LocalConfig` - Port 3002
- ✅ `BackendService` - Port 3002
- ✅ `InitialBindings` - Port 3002 (Web, Android, Desktop)
- ✅ `SalesService` - Messages d'erreur mis à jour

---

## 🎯 Démarrage du Backend

### Option 1: Double-clic (Recommandé)
```
START_BACKEND.bat
```
Le backend démarrera sur le port 3002.

### Option 2: Démarrage + Test Automatique
```
RUN_BACKEND_AND_TEST.bat
```
Démarre le backend ET teste tous les endpoints.

### Option 3: Manuel
```bash
cd backend
npm start
```

---

## 🧪 Tester les Endpoints

Une fois le backend en cours d'exécution:

```bash
# Health Check
curl http://localhost:3002/health

# Roles (public)
curl http://localhost:3002/api/v1/roles

# Login (admin / admin123)
curl -X POST http://localhost:3002/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"nomUtilisateur":"admin","motDePasse":"admin123"}'

# Available Cash Registers
curl http://localhost:3002/api/v1/cash-sessions/available-cash-registers

# Active Session
curl http://localhost:3002/api/v1/cash-sessions/active
```

---

## 📱 Démarrer l'App Flutter

Avec le backend en cours d'exécution:

```bash
cd logesco_v2
flutter run -d windows
```

Ou depuis VS Code: **F5** ou **Debug → Run**

---

## 🔌 Vérification de la Connexion

L'app Flutter devrait maintenant:
1. ✅ Se connecter sans erreur "connection refused"
2. ✅ Se logger automatiquement en mode développement
3. ✅ Charger les caisses disponibles
4. ✅ Afficher la session active

---

## ⚙️ URL de Base de l'API

```
http://localhost:3002/api/v1
```

Tous les endpoints sont maintenant correctement configurés sur ce port.

---

## 📊 Architecture

```
LOGESCO App (Flutter)
    ↓
ApiClient + EnvironmentConfig
    ↓
LocalConfig: http://localhost:3002/api/v1
    ↓
Backend API (Node.js + Express)
    ↓
SQLite Database
```

---

## 🛠️ Scripts Disponibles

| Script | Description |
|--------|-------------|
| `START_BACKEND.bat` | Démarre le backend seul |
| `TEST_API_ENDPOINTS.bat` | Teste les 5 endpoints principaux |
| `RUN_BACKEND_AND_TEST.bat` | Démarre + teste automatiquement |

---

## ✅ Checklist

- [x] Port 8080 → 3002 dans tous les fichiers
- [x] Backend en écoute sur port 3002
- [x] Tous les endpoints testés et fonctionnels
- [x] Scripts de démarrage créés
- [x] App Flutter reconfigurée pour port 3002

**L'application est prête à être lancée!** 🎉

---

## 🆘 Dépannage

### Erreur: "Port 3002 already in use"
```bash
# Trouver le processus utilisant le port
netstat -ano | findstr :3002

# Tuer le processus (remplacer PID)
taskkill /PID <PID> /F
```

### Erreur: "Connection refused"
- Vérifie que le backend est en cours d'exécution
- Vérifie le port dans les logs: "🌐 Serveur en écoute sur le port 3002"

### La base de données ne s'initialise pas
```bash
cd backend
npm run db:setup
npm start
```

---

**Date de configuration:** 23 Décembre 2025
**Version:** 2.0.0
**Port:** 3002 ✅

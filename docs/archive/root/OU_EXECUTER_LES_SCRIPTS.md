# Où Exécuter les Scripts - Guide Complet

## 🎯 DEUX EMPLACEMENTS DIFFÉRENTS

### 📁 Emplacement 1: DOSSIER DE DÉVELOPPEMENT

**Chemin typique:**
```
C:\votre-projet\
D:\dev\logesco\
E:\projets\logesco-v2\
```

**Structure:**
```
votre-projet/
├── backend/
│   ├── src/
│   ├── prisma/
│   └── package.json
├── logesco_v2/
│   ├── lib/
│   └── pubspec.yaml
├── preparer-pour-client-optimise.bat  ← Scripts de BUILD
├── build-portable-backend.bat
└── migration-guidee.bat
```

**Usage:**
- Développement du code
- Création des packages
- Tests en développement

**Scripts à exécuter ICI:**
- `preparer-pour-client-optimise.bat` - Créer le package
- `build-production.bat` - Build de production
- Scripts de développement

---

### 📦 Emplacement 2: DOSSIER D'INSTALLATION CLIENT

**Chemin typique:**
```
C:\LOGESCO\
C:\Program Files\LOGESCO\
C:\Users\[Nom]\Videos\LOGESCO-Client-Ultimate\
D:\Applications\LOGESCO\
```

**Structure:**
```
LOGESCO-Client-Ultimate/
├── backend/
│   ├── database/
│   │   └── logesco.db  ← Base de données du client
│   ├── node_modules/
│   └── src/
├── app/
│   └── logesco_v2.exe
├── DEMARRER-LOGESCO.bat  ← Scripts d'UTILISATION
├── forcer-synchronisation-prisma.bat  ← Scripts de MIGRATION
└── tester-lecture-prisma.bat
```

**Usage:**
- Utilisation quotidienne
- Migration/mise à jour
- Dépannage

**Scripts à exécuter ICI:**
- `DEMARRER-LOGESCO.bat` - Démarrer l'application
- `forcer-synchronisation-prisma.bat` - Synchroniser Prisma
- `tester-lecture-prisma.bat` - Tester la lecture
- `migration-guidee-FIXE.bat` - Migrer
- Tous les scripts de dépannage

---

## 🔄 WORKFLOW COMPLET

### Étape 1: Développement (Dossier DEV)

```batch
# Dans: C:\votre-projet\

# 1. Développer le code
# 2. Tester localement
# 3. Créer le package
preparer-pour-client-optimise.bat
```

**Résultat:** Package créé dans `release\LOGESCO-Client-Optimise\`

### Étape 2: Distribution

```batch
# Copier le package vers le client
# Soit:
# - Clé USB
# - Réseau
# - Téléchargement
# - Email

# Le client extrait dans:
C:\LOGESCO\
```

### Étape 3: Installation Client (Dossier CLIENT)

```batch
# Dans: C:\LOGESCO\

# 1. Première installation
DEMARRER-LOGESCO.bat

# OU

# 2. Migration depuis ancienne version
migration-guidee-FIXE.bat
```

### Étape 4: Dépannage (Dossier CLIENT)

```batch
# Dans: C:\LOGESCO\

# Si problème de données non affichées:
forcer-synchronisation-prisma.bat

# Tester:
tester-lecture-prisma.bat

# Diagnostic:
diagnostic-migration-donnees.bat
```

---

## 📋 CHECKLIST PAR EMPLACEMENT

### ✅ Dans le Dossier DEV

- [ ] Code source complet
- [ ] Scripts de build
- [ ] Tests unitaires
- [ ] Documentation développeur
- [ ] Git repository

**Commandes typiques:**
```batch
npm install
npm run dev
flutter run
preparer-pour-client-optimise.bat
```

### ✅ Dans le Dossier CLIENT

- [ ] Package compilé
- [ ] Base de données
- [ ] Scripts d'utilisation
- [ ] Scripts de migration
- [ ] Documentation utilisateur

**Commandes typiques:**
```batch
DEMARRER-LOGESCO.bat
forcer-synchronisation-prisma.bat
tester-lecture-prisma.bat
```

---

## 🚨 VOTRE CAS ACTUEL

Vous êtes dans:
```
C:\Users\DIGITAL MARKET\Videos\LOGESCO-Client-Ultimate\
```

C'est un **DOSSIER CLIENT** (installation).

### Ce que vous devez faire:

1. **Copier les scripts manquants:**

```batch
# Depuis votre dossier DEV, exécuter:
copier-scripts-vers-package.bat
```

Ou manuellement copier vers `C:\Users\DIGITAL MARKET\Videos\LOGESCO-Client-Ultimate\`:
- `forcer-synchronisation-prisma.bat`
- `tester-lecture-prisma.bat`
- `verifier-schema-bd.bat`
- `backend\test-prisma-connection.js`
- Documentation

2. **Puis dans le dossier CLIENT, exécuter:**

```batch
cd "C:\Users\DIGITAL MARKET\Videos\LOGESCO-Client-Ultimate"
forcer-synchronisation-prisma.bat
```

---

## 📦 INCLURE DANS LES FUTURS PACKAGES

Pour éviter ce problème, modifiez `preparer-pour-client-optimise.bat` pour inclure automatiquement:

```batch
REM Copier les scripts de migration
copy "migration-guidee-FIXE.bat" "release\LOGESCO-Client-Optimise\" >nul
copy "forcer-synchronisation-prisma.bat" "release\LOGESCO-Client-Optimise\" >nul
copy "tester-lecture-prisma.bat" "release\LOGESCO-Client-Optimise\" >nul
copy "verifier-schema-bd.bat" "release\LOGESCO-Client-Optimise\" >nul
copy "diagnostic-migration-donnees.bat" "release\LOGESCO-Client-Optimise\" >nul
copy "restaurer-donnees-urgence.bat" "release\LOGESCO-Client-Optimise\" >nul

REM Copier le script de test Prisma
copy "backend\test-prisma-connection.js" "release\LOGESCO-Client-Optimise\backend\" >nul

REM Copier la documentation
copy "LIRE_EN_PREMIER_SYNCHRONISATION.txt" "release\LOGESCO-Client-Optimise\" >nul
copy "GUIDE_DEPANNAGE_DONNEES_NON_AFFICHEES.md" "release\LOGESCO-Client-Optimise\" >nul
```

---

## 🎯 RÉSUMÉ VISUEL

```
┌─────────────────────────────────────────────────────────────┐
│ DOSSIER DEV (Développement)                                 │
│ ─────────────────────────────                               │
│                                                             │
│ • Code source                                               │
│ • Scripts de BUILD                                          │
│ • Tests                                                     │
│                                                             │
│ Commandes:                                                  │
│ → preparer-pour-client-optimise.bat                         │
│ → npm run dev                                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Créer package
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ PACKAGE (Distribution)                                      │
│ ────────────────────                                        │
│                                                             │
│ • Fichiers compilés                                         │
│ • Scripts d'UTILISATION                                     │
│ • Scripts de MIGRATION                                      │
│ • Documentation                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Installer chez client
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ DOSSIER CLIENT (Installation)                              │
│ ────────────────────────────                                │
│                                                             │
│ • Application installée                                     │
│ • Base de données                                           │
│ • Scripts d'utilisation                                     │
│                                                             │
│ Commandes:                                                  │
│ → DEMARRER-LOGESCO.bat                                      │
│ → forcer-synchronisation-prisma.bat                         │
│ → tester-lecture-prisma.bat                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ ACTION IMMÉDIATE

**Vous êtes dans le dossier CLIENT, donc:**

1. Retournez dans votre dossier DEV
2. Exécutez: `copier-scripts-vers-package.bat`
3. Retournez dans le dossier CLIENT
4. Exécutez: `forcer-synchronisation-prisma.bat`

**OU créez directement le fichier manquant dans le dossier CLIENT:**

Créez `backend\test-prisma-connection.js` avec le contenu fourni précédemment.

---

**Version:** 1.0  
**Date:** 2026-03-06

# Migration NUI et RCCM - Guide Rapide

## Problème

Les colonnes **nui** et **rccm** ne sont pas créées après la mise à jour chez certains clients, empêchant la saisie de ces informations dans la fiche client.

---

## 🚀 Solution Rapide (3 étapes)

### 1. Diagnostic

Vérifiez d'abord si les colonnes sont présentes :

```batch
DIAGNOSTIC-NUI-RCCM.bat
```

**Résultat :**
- ✅ Colonnes présentes → Aucune action nécessaire
- ❌ Colonnes manquantes → Passez à l'étape 2

---

### 2. Migration

**Chez vous (développement) :**
```batch
AJOUTER-COLONNES-NUI-RCCM.bat
```

**Chez un client (production) :**
```batch
AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat
```

---

### 3. Vérification

Relancez le diagnostic pour confirmer :

```batch
DIAGNOSTIC-NUI-RCCM.bat
```

Puis testez dans l'application Flutter :
1. Ouvrir **Clients**
2. Créer ou éditer un client
3. Vérifier que les champs **NUI** et **RCCM** sont visibles
4. Enregistrer et vérifier que les données sont conservées

---

## 📁 Fichiers créés

| Fichier | Description | Usage |
|---------|-------------|-------|
| **DIAGNOSTIC-NUI-RCCM.bat** | Vérification rapide | Diagnostic initial |
| **AJOUTER-COLONNES-NUI-RCCM.bat** | Migration locale | Développement |
| **AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat** | Migration client | Chez les clients |
| **backend/fix-clients-nui-rccm-sqlite.js** | Script Node.js | Appelé par les .bat |
| **backend/check-nui-rccm-columns.js** | Script de diagnostic | Appelé par DIAGNOSTIC-NUI-RCCM.bat |
| **GUIDE_MIGRATION_NUI_RCCM.md** | Guide détaillé | Documentation complète |
| **README_MIGRATION_NUI_RCCM.md** | Guide rapide | Ce fichier |

---

## 🎯 Déploiement chez les clients

### Préparation du package de mise à jour

Incluez ces fichiers dans le package de mise à jour :

```
Package_Mise_A_Jour/
├── DIAGNOSTIC-NUI-RCCM.bat
├── AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat
├── backend/
│   ├── fix-clients-nui-rccm-sqlite.js
│   └── check-nui-rccm-columns.js
└── GUIDE_MIGRATION_NUI_RCCM.md
```

### Instructions pour le client

```
1. Fermez l'application LOGESCO
2. Double-cliquez sur: AJOUTER-COLONNES-NUI-RCCM-CLIENT.bat
3. Attendez le message "Migration réussie"
4. Redémarrez l'application LOGESCO
5. Testez les champs NUI et RCCM dans un client
```

---

## ⚠️ Important

### Sauvegarde automatique

Les scripts créent automatiquement une sauvegarde avant modification :
- Locale : `backend/database/logesco.db.backup`
- Client : `%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db.backup`

### Restauration en cas de problème

```batch
REM Développement
copy backend\database\logesco.db.backup backend\database\logesco.db

REM Production
copy "%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db.backup" "%LOCALAPPDATA%\LOGESCO\backend\database\logesco.db"
```

---

## 📞 Support

### Erreurs courantes

| Erreur | Solution |
|--------|----------|
| "Script de migration non trouvé" | Vérifiez que tous les fichiers sont présents |
| "Base de données non trouvée" | Lancez l'application une fois pour créer la DB |
| "duplicate column name: nui" | Les colonnes existent déjà, migration déjà faite |
| Backend ne démarre pas | Restaurez la sauvegarde et contactez le support |

### Logs

En cas de problème, fournissez :
1. Le résultat du diagnostic
2. Les messages d'erreur exacts
3. L'emplacement de la base de données
4. La version de l'application

---

## ✅ Checklist de déploiement

- [ ] Diagnostic exécuté
- [ ] Sauvegarde créée
- [ ] Migration exécutée avec succès
- [ ] Diagnostic de vérification OK
- [ ] Test dans l'application Flutter OK
- [ ] Champs NUI/RCCM visibles
- [ ] Données sauvegardées correctement
- [ ] Documentation fournie au client

---

## 🔮 Prévention future

Pour éviter ce problème à l'avenir, le backend peut exécuter les migrations automatiquement au démarrage. Voir le guide détaillé : **GUIDE_MIGRATION_NUI_RCCM.md**

---

## 📚 Documentation complète

Pour plus de détails, consultez :
- **GUIDE_MIGRATION_NUI_RCCM.md** - Documentation technique complète
- **AJOUT_CHAMPS_NUI_RCCM_CLIENTS.md** - Documentation de la fonctionnalité

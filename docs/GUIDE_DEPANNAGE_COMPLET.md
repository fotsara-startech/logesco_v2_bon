# Guide de Dépannage Complet - LOGESCO v2

## Table des Matières

1. [Diagnostic Rapide](#diagnostic-rapide)
2. [Problèmes de Démarrage](#problèmes-de-démarrage)
3. [Problèmes de Connexion](#problèmes-de-connexion)
4. [Problèmes de Performance](#problèmes-de-performance)
5. [Problèmes de Base de Données](#problèmes-de-base-de-données)
6. [Problèmes Réseau](#problèmes-réseau)
7. [Problèmes d'Interface](#problèmes-dinterface)
8. [Codes d'Erreur](#codes-derreur)
9. [Outils de Diagnostic](#outils-de-diagnostic)

---

## Diagnostic Rapide

### Checklist de Diagnostic en 5 Minutes

#### Mode Desktop

```batch
@echo off
echo === DIAGNOSTIC LOGESCO v2 ===
echo.

echo 1. Vérification du service...
sc query "LOGESCO API Service"
echo.

echo 2. Vérification du port 8080...
netstat -ano | findstr :8080
echo.

echo 3. Vérification de la base de données...
dir "C:\Program Files\LOGESCO\database\logesco.db"
echo.

echo 4. Dernières erreurs...
type "C:\Program Files\LOGESCO\api\logs\error.log" | find /n "ERROR" | more
echo.

echo === FIN DU DIAGNOSTIC ===
pause
```

Sauvegarder ce script comme `diagnostic-logesco.bat`

#### Mode Web

```bash
#!/bin/bash
echo "=== DIAGNOSTIC LOGESCO v2 ==="
echo

echo "1. État des conteneurs..."
docker-compose ps
echo

echo "2. Santé de l'API..."
curl -s http://localhost:3000/health | jq
echo

echo "3. État PostgreSQL..."
docker-compose exec db pg_isready -U logesco_user
echo

echo "4. Dernières erreurs API..."
docker-compose logs --tail=20 api | grep ERROR
echo

echo "5. Dernières erreurs DB..."
docker-compose logs --tail=20 db | grep ERROR
echo

echo "=== FIN DU DIAGNOSTIC ==="
```

Sauvegarder comme `diagnostic-logesco.sh` et rendre exécutable : `chmod +x diagnostic-logesco.sh`

---

## Problèmes de Démarrage

### Problème 1: "L'application ne démarre pas"

**Symptômes** :
- Double-clic sur l'icône ne fait rien
- L'application se ferme immédiatement
- Message d'erreur au démarrage

**Causes Possibles** :
1. Fichiers corrompus
2. Dépendances manquantes
3. Conflit avec une autre application
4. Permissions insuffisantes

**Solutions** :

**Solution 1 : Vérifier les Logs**
```batch
# Desktop
type "C:\Users\%USERNAME%\AppData\Local\LOGESCO\logs\app.log"
```

**Solution 2 : Réinstaller l'Application**
1. Sauvegarder les données
2. Désinstaller LOGESCO
3. Redémarrer l'ordinateur
4. Réinstaller LOGESCO
5. Restaurer les données

**Solution 3 : Exécuter en Mode Administrateur**
1. Clic droit sur l'icône LOGESCO
2. Sélectionner "Exécuter en tant qu'administrateur"

**Solution 4 : Vérifier les Dépendances**
```batch
# Vérifier Visual C++ Redistributable
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
```

### Problème 2: "Le service API ne démarre pas"

**Symptômes** :
- Message "Impossible de se connecter à l'API"
- Service marqué comme "Arrêté" dans services.msc

**Diagnostic** :
```batch
# Vérifier l'état du service
sc query "LOGESCO API Service"

# Vérifier les logs
type "C:\Program Files\LOGESCO\api\logs\error.log"
```

**Solutions** :

**Solution 1 : Redémarrer le Service**
```batch
sc stop "LOGESCO API Service"
timeout /t 5
sc start "LOGESCO API Service"
```

**Solution 2 : Vérifier le Port**
```batch
# Vérifier si le port 8080 est utilisé
netstat -ano | findstr :8080

# Si utilisé, identifier le processus
tasklist | findstr [PID]

# Arrêter le processus conflictuel ou changer le port LOGESCO
```

**Solution 3 : Réinstaller le Service**
```batch
# Désinstaller le service
sc delete "LOGESCO API Service"

# Réinstaller (exécuter en admin)
cd "C:\Program Files\LOGESCO\api"
install-service.bat
```

**Solution 4 : Vérifier Node.js**
```batch
# Vérifier que Node.js est installé
node --version

# Si non installé, télécharger depuis https://nodejs.org/
```

### Problème 3: "Écran blanc au démarrage"

**Symptômes** :
- L'application s'ouvre mais affiche un écran blanc
- Aucun message d'erreur

**Solutions** :

**Solution 1 : Vider le Cache**
```batch
# Supprimer le cache de l'application
rd /s /q "%LOCALAPPDATA%\LOGESCO\cache"
```

**Solution 2 : Réinitialiser les Paramètres**
```batch
# Sauvegarder puis supprimer les paramètres
copy "%LOCALAPPDATA%\LOGESCO\settings.json" "%LOCALAPPDATA%\LOGESCO\settings.json.bak"
del "%LOCALAPPDATA%\LOGESCO\settings.json"
```

**Solution 3 : Vérifier la Connexion API**
```batch
# Tester l'API manuellement
curl http://localhost:8080/health
```

---

## Problèmes de Connexion

### Problème 4: "Identifiants incorrects"

**Symptômes** :
- Message "Nom d'utilisateur ou mot de passe incorrect"
- Impossible de se connecter avec les identifiants par défaut

**Solutions** :

**Solution 1 : Vérifier les Identifiants par Défaut**
- Utilisateur : `admin`
- Mot de passe : `admin123`
- ⚠️ Sensible à la casse !

**Solution 2 : Réinitialiser le Mot de Passe Admin**

**Desktop**
```batch
cd "C:\Program Files\LOGESCO\api"
node scripts\reset-admin-password.js
```

**Web**
```bash
docker-compose exec api npm run reset:admin
```

**Solution 3 : Vérifier la Base de Données**
```sql
-- Desktop (SQLite)
sqlite3 "C:\Program Files\LOGESCO\database\logesco.db"
SELECT * FROM utilisateurs WHERE nom_utilisateur = 'admin';
.quit

-- Web (PostgreSQL)
docker-compose exec db psql -U logesco_user -d logesco
SELECT * FROM utilisateurs WHERE nom_utilisateur = 'admin';
\q
```

### Problème 5: "Session expirée"

**Symptômes** :
- Déconnexion automatique fréquente
- Message "Votre session a expiré"

**Causes** :
- Inactivité prolongée (>30 minutes)
- Token JWT expiré
- Problème de synchronisation d'horloge

**Solutions** :

**Solution 1 : Augmenter la Durée de Session**

Modifier `.env` :
```env
JWT_EXPIRES_IN=8h  # Au lieu de 24h par défaut
```

Redémarrer le service.

**Solution 2 : Vérifier l'Horloge Système**
```batch
# Synchroniser l'horloge
w32tm /resync
```

**Solution 3 : Vider les Tokens Stockés**
```batch
# Supprimer les tokens en cache
del "%LOCALAPPDATA%\LOGESCO\tokens.dat"
```

### Problème 6: "Erreur de connexion à l'API"

**Symptômes** :
- Message "Impossible de se connecter au serveur"
- Timeout de connexion

**Diagnostic** :
```batch
# Tester la connectivité
ping localhost
curl http://localhost:8080/health
telnet localhost 8080
```

**Solutions** :

**Solution 1 : Vérifier le Service API**
```batch
sc query "LOGESCO API Service"
# Si arrêté :
sc start "LOGESCO API Service"
```

**Solution 2 : Vérifier le Pare-feu**
```batch
# Ajouter une règle de pare-feu
netsh advfirewall firewall add rule name="LOGESCO API" dir=in action=allow protocol=TCP localport=8080
```

**Solution 3 : Vérifier l'URL de l'API**

Dans l'application, vérifier que l'URL est correcte :
- Desktop : `http://localhost:8080`
- Web : `https://api.votre-domaine.com`

---

## Problèmes de Performance

### Problème 7: "L'application est lente"

**Symptômes** :
- Temps de chargement long
- Interface qui rame
- Délai dans les actions

**Diagnostic** :
```batch
# Vérifier l'utilisation des ressources
tasklist /FI "IMAGENAME eq logesco*"

# Vérifier l'espace disque
wmic logicaldisk get size,freespace,caption
```

**Solutions** :

**Solution 1 : Optimiser la Base de Données**

**SQLite**
```sql
sqlite3 "C:\Program Files\LOGESCO\database\logesco.db"
VACUUM;
ANALYZE;
REINDEX;
.quit
```

**PostgreSQL**
```bash
docker-compose exec db psql -U logesco_user -d logesco -c "VACUUM ANALYZE;"
```

**Solution 2 : Nettoyer les Logs**
```batch
# Supprimer les anciens logs
forfiles /p "C:\Program Files\LOGESCO\api\logs" /s /m *.log /d -7 /c "cmd /c del @path"
```

**Solution 3 : Augmenter les Ressources**
- Fermer les applications inutilisées
- Ajouter de la RAM si possible
- Défragmenter le disque

**Solution 4 : Réindexer la Base de Données**
```sql
-- Créer des index sur les colonnes fréquemment recherchées
CREATE INDEX IF NOT EXISTS idx_produits_nom ON produits(nom);
CREATE INDEX IF NOT EXISTS idx_ventes_date ON ventes(date_vente);
CREATE INDEX IF NOT EXISTS idx_clients_nom ON clients(nom);
```

### Problème 8: "Recherche très lente"

**Symptômes** :
- La recherche prend plusieurs secondes
- L'interface se fige pendant la recherche

**Solutions** :

**Solution 1 : Créer des Index**
```sql
-- Index pour la recherche de produits
CREATE INDEX idx_produits_search ON produits(nom, reference);

-- Index pour la recherche de clients
CREATE INDEX idx_clients_search ON clients(nom, prenom, telephone);
```

**Solution 2 : Limiter les Résultats**
- Utiliser la pagination
- Afficher maximum 50 résultats par page

**Solution 3 : Optimiser les Requêtes**
```sql
-- Utiliser LIKE avec index
SELECT * FROM produits WHERE nom LIKE 'ABC%';  -- Bon
-- Éviter :
SELECT * FROM produits WHERE nom LIKE '%ABC%';  -- Lent
```

---

## Problèmes de Base de Données

### Problème 9: "Base de données corrompue"

**Symptômes** :
- Erreur "database disk image is malformed"
- Données manquantes ou incohérentes
- Crashs fréquents

**Diagnostic** :
```batch
# Vérifier l'intégrité
sqlite3 "C:\Program Files\LOGESCO\database\logesco.db" "PRAGMA integrity_check;"
```

**Solutions** :

**Solution 1 : Réparer la Base de Données**
```batch
# Créer une sauvegarde
copy "C:\Program Files\LOGESCO\database\logesco.db" "C:\Program Files\LOGESCO\database\logesco.db.corrupt"

# Exporter et réimporter
sqlite3 "C:\Program Files\LOGESCO\database\logesco.db" ".dump" > dump.sql
sqlite3 "C:\Program Files\LOGESCO\database\logesco_new.db" < dump.sql

# Remplacer
sc stop "LOGESCO API Service"
move "C:\Program Files\LOGESCO\database\logesco_new.db" "C:\Program Files\LOGESCO\database\logesco.db"
sc start "LOGESCO API Service"
```

**Solution 2 : Restaurer une Sauvegarde**
```batch
sc stop "LOGESCO API Service"
copy "C:\Program Files\LOGESCO\backup\logesco_backup_YYYYMMDD.db" "C:\Program Files\LOGESCO\database\logesco.db"
sc start "LOGESCO API Service"
```

### Problème 10: "Erreur de contrainte de clé étrangère"

**Symptômes** :
- Message "FOREIGN KEY constraint failed"
- Impossible de supprimer un enregistrement

**Cause** :
- Tentative de suppression d'un enregistrement référencé ailleurs

**Solutions** :

**Solution 1 : Désactiver au lieu de Supprimer**
- Pour les produits : Décocher "Produit actif"
- Pour les clients/fournisseurs : Marquer comme inactif

**Solution 2 : Supprimer les Références d'Abord**
1. Identifier les références :
```sql
-- Trouver les ventes liées à un produit
SELECT * FROM details_ventes WHERE produit_id = 123;

-- Trouver les commandes liées à un fournisseur
SELECT * FROM commandes_approvisionnement WHERE fournisseur_id = 456;
```

2. Supprimer ou modifier les références
3. Puis supprimer l'enregistrement principal

---

## Problèmes Réseau

### Problème 11: "Impossible d'accéder depuis une autre machine"

**Symptômes** (Mode Web ou Réseau Local) :
- L'application fonctionne sur le serveur
- Impossible d'y accéder depuis un autre PC

**Diagnostic** :
```batch
# Sur le serveur, noter l'IP
ipconfig

# Depuis le client, tester la connectivité
ping [IP_DU_SERVEUR]
telnet [IP_DU_SERVEUR] 8080
```

**Solutions** :

**Solution 1 : Configurer le Pare-feu**

**Sur le Serveur** :
```batch
# Autoriser le port 8080
netsh advfirewall firewall add rule name="LOGESCO API" dir=in action=allow protocol=TCP localport=8080
```

**Solution 2 : Configurer CORS**

Modifier `.env` sur le serveur :
```env
CORS_ORIGIN=*
```

Redémarrer le service.

**Solution 3 : Vérifier la Configuration Réseau**
- Vérifier que les machines sont sur le même réseau
- Vérifier qu'il n'y a pas de proxy bloquant
- Vérifier les paramètres du routeur

### Problème 12: "Certificat SSL invalide" (Mode Web)

**Symptômes** :
- Avertissement de sécurité dans le navigateur
- "Votre connexion n'est pas privée"

**Solutions** :

**Solution 1 : Renouveler le Certificat Let's Encrypt**
```bash
sudo certbot renew
docker-compose restart web
```

**Solution 2 : Vérifier la Configuration SSL**
```bash
# Vérifier les certificats
ls -l /opt/logesco/nginx/ssl/

# Vérifier la configuration Nginx
docker-compose exec web nginx -t
```

**Solution 3 : Forcer HTTPS**

Dans `nginx.conf` :
```nginx
server {
    listen 80;
    server_name votre-domaine.com;
    return 301 https://$server_name$request_uri;
}
```

---

## Problèmes d'Interface

### Problème 13: "Boutons ne répondent pas"

**Symptômes** :
- Clic sur un bouton ne fait rien
- Interface figée

**Solutions** :

**Solution 1 : Actualiser l'Interface**
- Appuyer sur `F5`
- Ou fermer et rouvrir l'application

**Solution 2 : Vider le Cache**
```batch
rd /s /q "%LOCALAPPDATA%\LOGESCO\cache"
```

**Solution 3 : Vérifier les Logs JavaScript**
- Ouvrir les outils de développement (F12)
- Consulter la console pour les erreurs

### Problème 14: "Affichage incorrect / Texte tronqué"

**Symptômes** :
- Texte coupé
- Éléments qui se chevauchent
- Mise en page cassée

**Solutions** :

**Solution 1 : Ajuster la Résolution**
- Résolution minimale : 1280x720
- Résolution recommandée : 1920x1080

**Solution 2 : Ajuster le Zoom**
- Réinitialiser le zoom : `Ctrl + 0`
- Zoom optimal : 100%

**Solution 3 : Mettre à Jour l'Application**
- Vérifier qu'une mise à jour n'est pas disponible

---

## Codes d'Erreur

### Erreurs API (HTTP)

| Code | Signification | Solution |
|------|---------------|----------|
| 400 | Requête invalide | Vérifier les données envoyées |
| 401 | Non authentifié | Se reconnecter |
| 403 | Accès refusé | Vérifier les permissions |
| 404 | Ressource non trouvée | Vérifier l'URL/ID |
| 409 | Conflit | Référence déjà existante |
| 500 | Erreur serveur | Consulter les logs API |
| 503 | Service indisponible | Redémarrer le service |

### Erreurs Base de Données

| Code | Message | Solution |
|------|---------|----------|
| SQLITE_CORRUPT | Base corrompue | Restaurer sauvegarde |
| SQLITE_CONSTRAINT | Contrainte violée | Vérifier les données |
| SQLITE_LOCKED | Base verrouillée | Attendre ou redémarrer |
| SQLITE_FULL | Disque plein | Libérer de l'espace |

### Erreurs Métier

| Code | Message | Solution |
|------|---------|----------|
| INSUFFICIENT_STOCK | Stock insuffisant | Réapprovisionner |
| CREDIT_LIMIT_EXCEEDED | Limite de crédit dépassée | Paiement ou augmenter limite |
| DUPLICATE_REFERENCE | Référence déjà existante | Utiliser une autre référence |
| INVALID_QUANTITY | Quantité invalide | Vérifier la quantité |

---

## Outils de Diagnostic

### Outil 1: Vérificateur de Santé

Créer `health-check.bat` :
```batch
@echo off
echo === VERIFICATION DE SANTE LOGESCO ===
echo.

echo [1/5] Service API...
sc query "LOGESCO API Service" | find "RUNNING" && echo OK || echo ERREUR
echo.

echo [2/5] Base de donnees...
if exist "C:\Program Files\LOGESCO\database\logesco.db" (echo OK) else (echo ERREUR)
echo.

echo [3/5] API Health...
curl -s http://localhost:8080/health && echo OK || echo ERREUR
echo.

echo [4/5] Espace disque...
for /f "tokens=3" %%a in ('dir /-c "C:\Program Files\LOGESCO" ^| find "bytes free"') do set FREE=%%a
echo %FREE% octets libres
echo.

echo [5/5] Derniere erreur...
type "C:\Program Files\LOGESCO\api\logs\error.log" | find /n "ERROR" | more
echo.

echo === FIN DE LA VERIFICATION ===
pause
```

### Outil 2: Collecteur de Logs

Créer `collect-logs.bat` :
```batch
@echo off
set OUTPUT=C:\LOGESCO_Diagnostic_%date:~-4,4%%date:~-10,2%%date:~-7,2%.zip

echo Collecte des logs de diagnostic...

mkdir temp_logs
copy "C:\Program Files\LOGESCO\api\logs\*.log" temp_logs\
copy "%LOCALAPPDATA%\LOGESCO\logs\*.log" temp_logs\

powershell Compress-Archive -Path temp_logs\* -DestinationPath %OUTPUT%
rd /s /q temp_logs

echo Logs collectes dans: %OUTPUT%
pause
```

### Outil 3: Test de Performance

Créer `performance-test.bat` :
```batch
@echo off
echo === TEST DE PERFORMANCE ===
echo.

echo Test 1: Temps de reponse API...
powershell -Command "Measure-Command {Invoke-WebRequest -Uri 'http://localhost:8080/health'} | Select-Object -ExpandProperty TotalMilliseconds"
echo.

echo Test 2: Taille de la base de donnees...
dir "C:\Program Files\LOGESCO\database\logesco.db"
echo.

echo Test 3: Utilisation memoire...
tasklist /FI "IMAGENAME eq node.exe" /FO TABLE
echo.

echo === FIN DU TEST ===
pause
```

---

## Procédure d'Escalade

Si le problème persiste après avoir essayé les solutions ci-dessus :

### Niveau 1 : Documentation
1. Consulter le Guide Utilisateur
2. Consulter la FAQ
3. Rechercher dans la documentation technique

### Niveau 2 : Support Communautaire
1. Forum LOGESCO : community.logesco.com
2. Rechercher des problèmes similaires
3. Poster une question détaillée

### Niveau 3 : Support Technique
1. Email : support@logesco.com
2. Téléphone : +XXX XXX XXX XXX
3. Fournir :
   - Version de LOGESCO
   - Système d'exploitation
   - Description détaillée
   - Logs collectés
   - Captures d'écran

### Niveau 4 : Support Premium
1. Intervention à distance
2. Assistance téléphonique prioritaire
3. Résolution garantie sous 24h

---

**Version du document** : 1.0  
**Dernière mise à jour** : Novembre 2024  
**LOGESCO v2** - Guide de Dépannage Complet


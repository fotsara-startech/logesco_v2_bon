# Guide de Maintenance - LOGESCO v2

## Table des Matières

1. [Maintenance Préventive](#maintenance-préventive)
2. [Sauvegardes](#sauvegardes)
3. [Mises à Jour](#mises-à-jour)
4. [Surveillance et Monitoring](#surveillance-et-monitoring)
5. [Optimisation des Performances](#optimisation-des-performances)
6. [Résolution de Problèmes](#résolution-de-problèmes)
7. [Procédures d'Urgence](#procédures-durgence)

---

## Maintenance Préventive

### Tâches Quotidiennes

#### Vérification de l'État du Système

**Mode Desktop (Local)**
```batch
# Vérifier que le service API est actif
sc query "LOGESCO API Service"

# Vérifier l'espace disque
dir "C:\Program Files\LOGESCO\database\"
```

**Mode Web (Cloud)**
```bash
# Vérifier l'état des conteneurs
docker-compose ps

# Vérifier les logs récents
docker-compose logs --tail=50 api
```

#### Vérification des Logs

**Desktop**
- Emplacement : `C:\Program Files\LOGESCO\api\logs\`
- Vérifier : `error.log` pour les erreurs
- Action : Si erreurs répétées, consulter la section Résolution de Problèmes

**Web**
```bash
# Consulter les erreurs récentes
docker-compose logs --tail=100 api | grep ERROR

# Vérifier les erreurs de base de données
docker-compose logs --tail=100 db | grep ERROR
```

### Tâches Hebdomadaires

#### Nettoyage des Logs

**Desktop**
```batch
# Supprimer les logs de plus de 30 jours
forfiles /p "C:\Program Files\LOGESCO\api\logs" /s /m *.log /d -30 /c "cmd /c del @path"
```

**Web**
```bash
# Nettoyer les logs Docker
docker system prune -f

# Limiter la taille des logs
docker-compose logs --tail=1000 > /opt/logesco/archive/logs_$(date +%Y%m%d).txt
```

#### Vérification de l'Intégrité de la Base de Données

**Desktop (SQLite)**
```batch
cd "C:\Program Files\LOGESCO\database"
sqlite3 logesco.db "PRAGMA integrity_check;"
```

**Web (PostgreSQL)**
```bash
docker-compose exec db psql -U logesco_user -d logesco -c "SELECT pg_database_size('logesco');"
```

### Tâches Mensuelles

#### Optimisation de la Base de Données

**SQLite**
```sql
-- Compacter la base de données
VACUUM;

-- Analyser les statistiques
ANALYZE;

-- Reconstruire les index
REINDEX;
```

**PostgreSQL**
```bash
docker-compose exec db psql -U logesco_user -d logesco -c "VACUUM ANALYZE;"
```

#### Audit de Sécurité

- [ ] Vérifier les comptes utilisateurs actifs
- [ ] Vérifier les tentatives de connexion échouées
- [ ] Vérifier les permissions des fichiers
- [ ] Vérifier les certificats SSL (mode web)
- [ ] Mettre à jour les mots de passe si nécessaire

---

## Sauvegardes

### Stratégie de Sauvegarde

**Règle 3-2-1** :
- **3** copies des données
- **2** supports différents
- **1** copie hors site

### Sauvegarde Mode Desktop

#### Sauvegarde Automatique

Le système crée automatiquement une sauvegarde quotidienne :
- Emplacement : `C:\Program Files\LOGESCO\backup\`
- Format : `logesco_backup_YYYYMMDD.db`
- Rétention : 30 jours

#### Sauvegarde Manuelle

**Méthode 1 : Via l'Application**
1. Menu > Paramètres > Sauvegarder les données
2. Choisir l'emplacement
3. Cliquer sur Sauvegarder

**Méthode 2 : Copie Manuelle**
```batch
# Arrêter le service
sc stop "LOGESCO API Service"

# Copier la base de données
copy "C:\Program Files\LOGESCO\database\logesco.db" "D:\Backups\logesco_%date:~-4,4%%date:~-10,2%%date:~-7,2%.db"

# Redémarrer le service
sc start "LOGESCO API Service"
```

#### Script de Sauvegarde Automatique

Créer `backup-logesco.bat` :
```batch
@echo off
set BACKUP_DIR=D:\Backups\LOGESCO
set DATE=%date:~-4,4%%date:~-10,2%%date:~-7,2%

mkdir %BACKUP_DIR% 2>nul

sc stop "LOGESCO API Service"
copy "C:\Program Files\LOGESCO\database\logesco.db" "%BACKUP_DIR%\logesco_%DATE%.db"
sc start "LOGESCO API Service"

echo Sauvegarde terminée: %BACKUP_DIR%\logesco_%DATE%.db
```

Planifier avec le Planificateur de tâches Windows :
- Déclencheur : Quotidien à 2h du matin
- Action : Exécuter `backup-logesco.bat`

### Sauvegarde Mode Web

#### Sauvegarde Automatique PostgreSQL

Script déjà configuré dans `/opt/logesco/backup.sh` :
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/logesco/backup"

mkdir -p $BACKUP_DIR

# Sauvegarde de la base de données
docker-compose exec -T db pg_dump -U logesco_user logesco > $BACKUP_DIR/logesco_$DATE.sql

# Compression
gzip $BACKUP_DIR/logesco_$DATE.sql

# Suppression des sauvegardes de plus de 30 jours
find $BACKUP_DIR -name "logesco_*.sql.gz" -mtime +30 -delete

echo "Sauvegarde terminée : logesco_$DATE.sql.gz"
```

Vérifier la tâche cron :
```bash
crontab -l | grep backup
```

#### Sauvegarde Hors Site

**Option 1 : Copie vers un serveur distant**
```bash
# Ajouter à backup.sh
rsync -avz $BACKUP_DIR/ user@backup-server:/backups/logesco/
```

**Option 2 : Upload vers le cloud**
```bash
# Avec rclone (Google Drive, Dropbox, etc.)
rclone copy $BACKUP_DIR remote:logesco-backups
```

### Restauration de Sauvegarde

#### Desktop (SQLite)

```batch
# Arrêter le service
sc stop "LOGESCO API Service"

# Sauvegarder la base actuelle (au cas où)
copy "C:\Program Files\LOGESCO\database\logesco.db" "C:\Program Files\LOGESCO\database\logesco.db.old"

# Restaurer la sauvegarde
copy "D:\Backups\logesco_20241110.db" "C:\Program Files\LOGESCO\database\logesco.db"

# Redémarrer le service
sc start "LOGESCO API Service"
```

#### Web (PostgreSQL)

```bash
cd /opt/logesco

# Arrêter l'API
docker-compose stop api

# Restaurer la base de données
gunzip -c backup/logesco_20241110_020000.sql.gz | \
  docker-compose exec -T db psql -U logesco_user logesco

# Redémarrer l'API
docker-compose start api

# Vérifier
docker-compose logs -f api
```

### Test de Restauration

**Fréquence** : Mensuel

**Procédure** :
1. Créer un environnement de test
2. Restaurer la dernière sauvegarde
3. Vérifier l'intégrité des données
4. Tester les fonctionnalités principales
5. Documenter les résultats

---

## Mises à Jour

### Vérification des Mises à Jour

#### Desktop

Vérifier la version actuelle :
- Menu > À propos
- Comparer avec la dernière version disponible

#### Web

```bash
# Vérifier les nouvelles images Docker
docker-compose pull

# Comparer les versions
docker images | grep logesco
```

### Procédure de Mise à Jour Desktop

1. **Préparation**
   ```batch
   # Créer une sauvegarde complète
   backup-logesco.bat
   
   # Noter la version actuelle
   ```

2. **Installation**
   - Télécharger le nouveau `LOGESCO-v2-Setup.exe`
   - Exécuter l'installateur
   - Suivre l'assistant (conserve les données)

3. **Vérification**
   - Lancer l'application
   - Vérifier la nouvelle version (Menu > À propos)
   - Tester les fonctionnalités principales

4. **Rollback si Nécessaire**
   ```batch
   # Désinstaller la nouvelle version
   # Réinstaller l'ancienne version
   # Restaurer la sauvegarde
   ```

### Procédure de Mise à Jour Web

1. **Préparation**
   ```bash
   cd /opt/logesco
   
   # Sauvegarde complète
   ./backup.sh
   
   # Noter la version actuelle
   docker-compose exec api node -e "console.log(require('./package.json').version)"
   ```

2. **Mise à Jour**
   ```bash
   # Télécharger les nouvelles images
   docker-compose pull
   
   # Arrêter les services
   docker-compose down
   
   # Démarrer avec les nouvelles images
   docker-compose up -d
   
   # Exécuter les migrations si nécessaire
   docker-compose exec api npm run migrate
   ```

3. **Vérification**
   ```bash
   # Vérifier l'état des services
   docker-compose ps
   
   # Vérifier les logs
   docker-compose logs -f api
   
   # Tester l'API
   curl https://api.votre-domaine.com/health
   ```

4. **Rollback si Nécessaire**
   ```bash
   # Revenir aux anciennes images
   docker-compose down
   docker-compose up -d logesco/api:previous-version
   
   # Restaurer la base de données
   gunzip -c backup/logesco_YYYYMMDD.sql.gz | \
     docker-compose exec -T db psql -U logesco_user logesco
   ```

---

## Surveillance et Monitoring

### Indicateurs Clés à Surveiller

#### Performance

**Desktop**
- Utilisation CPU du service API
- Utilisation mémoire
- Taille de la base de données
- Temps de réponse de l'API

**Web**
- Charge serveur (CPU, RAM, Disque)
- Temps de réponse API
- Taille base de données PostgreSQL
- Connexions actives

#### Disponibilité

**Desktop**
```batch
# Vérifier que le service est actif
sc query "LOGESCO API Service" | find "RUNNING"
```

**Web**
```bash
# Vérifier la disponibilité de l'API
curl -f https://api.votre-domaine.com/health || echo "API DOWN"

# Vérifier PostgreSQL
docker-compose exec db pg_isready -U logesco_user
```

### Alertes Automatiques

#### Script de Monitoring Desktop

Créer `monitor-logesco.bat` :
```batch
@echo off
sc query "LOGESCO API Service" | find "RUNNING" >nul
if errorlevel 1 (
    echo ALERTE: Service LOGESCO arrêté!
    echo Tentative de redémarrage...
    sc start "LOGESCO API Service"
) else (
    echo Service LOGESCO OK
)
```

Planifier toutes les 5 minutes avec le Planificateur de tâches.

#### Monitoring Web avec Healthchecks

Utiliser un service comme UptimeRobot ou Healthchecks.io :
- URL à surveiller : `https://api.votre-domaine.com/health`
- Fréquence : Toutes les 5 minutes
- Alertes : Email/SMS en cas de panne

### Logs à Surveiller

**Erreurs Critiques** :
- Échecs de connexion à la base de données
- Erreurs d'authentification répétées
- Erreurs de mémoire
- Crashs de l'application

**Avertissements** :
- Stock faible
- Limites de crédit dépassées
- Performances dégradées
- Espace disque faible

---

## Optimisation des Performances

### Base de Données

#### SQLite

```sql
-- Analyser les requêtes lentes
EXPLAIN QUERY PLAN SELECT * FROM ventes WHERE date_vente > '2024-01-01';

-- Créer des index si nécessaire
CREATE INDEX idx_ventes_date ON ventes(date_vente);
CREATE INDEX idx_produits_reference ON produits(reference);

-- Compacter régulièrement
VACUUM;
```

#### PostgreSQL

```sql
-- Analyser les requêtes lentes
EXPLAIN ANALYZE SELECT * FROM ventes WHERE date_vente > '2024-01-01';

-- Créer des index
CREATE INDEX idx_ventes_date ON ventes(date_vente);

-- Mettre à jour les statistiques
ANALYZE;

-- Nettoyer
VACUUM FULL;
```

### Application

#### Desktop

- Fermer les applications inutilisées
- Augmenter la RAM si nécessaire
- Défragmenter le disque régulièrement
- Nettoyer les fichiers temporaires

#### Web

```bash
# Limiter les ressources Docker
docker-compose up -d --scale api=2  # Plusieurs instances API

# Optimiser PostgreSQL
# Éditer postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
```

### Réseau

**Desktop** : Aucune optimisation nécessaire (local)

**Web** :
- Activer la compression gzip
- Utiliser un CDN pour les assets statiques
- Optimiser les images
- Mettre en cache les réponses API

---

## Résolution de Problèmes

### Problèmes Courants et Solutions

#### "Service ne démarre pas"

**Desktop**
```batch
# Vérifier les logs
type "C:\Program Files\LOGESCO\api\logs\error.log"

# Vérifier le port
netstat -ano | findstr :8080

# Redémarrer le service
sc stop "LOGESCO API Service"
sc start "LOGESCO API Service"
```

**Web**
```bash
# Vérifier les logs
docker-compose logs api

# Redémarrer
docker-compose restart api
```

#### "Base de données corrompue"

**Desktop**
```batch
# Vérifier l'intégrité
sqlite3 "C:\Program Files\LOGESCO\database\logesco.db" "PRAGMA integrity_check;"

# Si corrompu, restaurer la sauvegarde
# Voir section Restauration de Sauvegarde
```

**Web**
```bash
# Vérifier PostgreSQL
docker-compose exec db psql -U logesco_user -d logesco -c "SELECT pg_database_size('logesco');"

# Réparer si nécessaire
docker-compose exec db psql -U logesco_user -d logesco -c "REINDEX DATABASE logesco;"
```

#### "Performances dégradées"

1. Vérifier l'espace disque disponible
2. Analyser les logs pour les erreurs
3. Optimiser la base de données (VACUUM, ANALYZE)
4. Redémarrer le service/conteneur
5. Augmenter les ressources si nécessaire

---

## Procédures d'Urgence

### Panne Totale du Système

#### Desktop

1. **Diagnostic**
   ```batch
   sc query "LOGESCO API Service"
   type "C:\Program Files\LOGESCO\api\logs\error.log"
   ```

2. **Tentative de Redémarrage**
   ```batch
   sc stop "LOGESCO API Service"
   timeout /t 5
   sc start "LOGESCO API Service"
   ```

3. **Si Échec : Restauration**
   - Restaurer la dernière sauvegarde
   - Réinstaller l'application si nécessaire

#### Web

1. **Diagnostic**
   ```bash
   docker-compose ps
   docker-compose logs --tail=100
   ```

2. **Redémarrage Complet**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **Si Échec : Restauration**
   ```bash
   # Restaurer la base de données
   gunzip -c backup/logesco_latest.sql.gz | \
     docker-compose exec -T db psql -U logesco_user logesco
   
   # Redémarrer
   docker-compose restart
   ```

### Perte de Données

1. **Ne pas paniquer**
2. **Arrêter immédiatement le système**
3. **Identifier la dernière sauvegarde valide**
4. **Restaurer la sauvegarde**
5. **Vérifier l'intégrité des données restaurées**
6. **Documenter l'incident**

### Contact Support

En cas de problème non résolu :
- 📧 Email : support@logesco.com
- 📞 Téléphone : +XXX XXX XXX XXX
- 🌐 Site web : www.logesco.com/support

**Informations à fournir** :
- Version de LOGESCO
- Système d'exploitation
- Description détaillée du problème
- Logs récents
- Captures d'écran si applicable

---

**Version du document** : 1.0  
**Dernière mise à jour** : Novembre 2024  
**LOGESCO v2** - Guide de Maintenance


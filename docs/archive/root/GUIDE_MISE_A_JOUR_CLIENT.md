# Guide de Mise à Jour Client LOGESCO

## Problématique
- Client existant avec données importantes
- Nouveau schéma de base de données
- Nouveau backend avec modifications
- Nécessité de conserver toutes les données

## Solution : Migration Progressive

### Étape 1 : Analyse et Sauvegarde

#### 1.1 Script d'analyse de l'ancienne BD
```bash
# Analyser la structure existante
sqlite3 database/logesco.db ".schema" > schema_ancien.sql
sqlite3 database/logesco.db ".dump" > sauvegarde_complete.sql
```

#### 1.2 Sauvegarde sécurisée
- Copier tout le dossier `database/`
- Exporter les données critiques en CSV
- Créer un point de restauration

### Étape 2 : Migration des Données

#### 2.1 Script de migration automatique
- Détecte l'ancienne version
- Applique les migrations nécessaires
- Préserve les données existantes

#### 2.2 Mapping des données
- Anciennes tables → Nouvelles tables
- Anciens champs → Nouveaux champs
- Conversion des formats si nécessaire

### Étape 3 : Installation Progressive

#### 3.1 Mode compatibilité
- Backend compatible avec ancien ET nouveau schéma
- Migration transparente pour l'utilisateur
- Rollback possible en cas de problème

#### 3.2 Validation des données
- Vérification de l'intégrité
- Tests de fonctionnement
- Confirmation utilisateur

## Scripts de Migration

### Script Principal : `migrer-client-existant.bat`
### Script de Sauvegarde : `sauvegarder-donnees-client.bat`
### Script de Validation : `valider-migration.bat`
### Script de Rollback : `restaurer-ancienne-version.bat`

## Processus Recommandé

1. **Sauvegarde complète**
2. **Migration des données**
3. **Installation nouvelle version**
4. **Validation fonctionnelle**
5. **Formation utilisateur** (nouvelles fonctionnalités)

## Sécurité

- Sauvegarde automatique avant migration
- Point de restauration
- Validation à chaque étape
- Possibilité de rollback complet
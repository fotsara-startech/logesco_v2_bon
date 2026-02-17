# Processus Complet de Mise à Jour Client LOGESCO

## Vue d'ensemble

Ce guide détaille le processus complet pour mettre à jour un client existant vers la nouvelle version de LOGESCO tout en préservant ses données.

## Étapes du Processus

### 1. Préparation (Chez vous)

#### 1.1 Construire la nouvelle version
```bash
# Construire le package portable avec toutes les corrections
preparer-pour-client-ultimate.bat
```

#### 1.2 Préparer les scripts de migration
- `sauvegarder-donnees-client.bat`
- `migrer-client-existant.bat`
- `valider-migration.bat`
- `restaurer-ancienne-version.bat`

#### 1.3 Créer le package de mise à jour
```
Package-Mise-A-Jour/
├── dist-portable/                    # Nouvelle version
├── sauvegarder-donnees-client.bat    # Sauvegarde
├── migrer-client-existant.bat        # Migration
├── valider-migration.bat             # Validation
├── restaurer-ancienne-version.bat    # Rollback
├── GUIDE_MISE_A_JOUR.txt            # Instructions
└── NOUVELLES_FONCTIONNALITES.txt    # Changelog
```

### 2. Chez le Client

#### 2.1 Sauvegarde (OBLIGATOIRE)
```bash
# Exécuter en premier
sauvegarder-donnees-client.bat
```
**Résultat :** Dossier `sauvegarde_client_YYYYMMDD_HHMMSS/`

#### 2.2 Migration
```bash
# Migrer vers la nouvelle version
migrer-client-existant.bat
```
**Actions :**
- Analyse de l'ancienne BD
- Installation nouvelle version
- Migration des données
- Configuration automatique

#### 2.3 Validation
```bash
# Vérifier que tout fonctionne
valider-migration.bat
```
**Vérifications :**
- Intégrité des données
- Fonctionnement du backend
- Accessibilité de l'application

#### 2.4 En cas de problème
```bash
# Restaurer l'ancienne version
restaurer-ancienne-version.bat
```

## Stratégie de Migration des Données

### Tables Critiques à Préserver
1. **utilisateurs** - Comptes utilisateur
2. **produits** - Catalogue produits
3. **ventes** - Historique des ventes
4. **clients** - Base clients
5. **stock** - Niveaux de stock
6. **categories** - Catégories produits

### Nouvelles Tables (Ajoutées automatiquement)
1. **user_roles** - Système de rôles
2. **cash_registers** - Gestion des caisses
3. **stock_inventories** - Inventaires
4. **financial_movements** - Mouvements financiers
5. **licenses** - Gestion des licences

### Mapping des Données
```sql
-- Exemple de migration utilisateurs
INSERT INTO user_roles (nom, displayName, isAdmin, privileges)
SELECT 'admin', 'Administrateur', 1, '{"all": true}'
WHERE NOT EXISTS (SELECT 1 FROM user_roles WHERE nom = 'admin');

-- Migration des utilisateurs existants
UPDATE utilisateurs SET roleId = 1 WHERE roleId IS NULL;
```

## Sécurité et Rollback

### Points de Sauvegarde
1. **Sauvegarde originale** - Avant toute modification
2. **Sauvegarde pré-migration** - Juste avant la migration
3. **Backend ancien** - Copie de l'ancien backend

### Procédure de Rollback
1. Arrêt des processus
2. Restauration des fichiers
3. Restauration de la BD
4. Test de fonctionnement

## Nouvelles Fonctionnalités

### Interface Utilisateur
- Design modernisé
- Navigation améliorée
- Responsive design

### Fonctionnalités Métier
- Gestion avancée des inventaires
- Système de permissions granulaires
- Rapports détaillés
- Gestion des caisses multiples
- Suivi des mouvements financiers

### Technique
- Performance améliorée
- Sécurité renforcée
- Sauvegarde automatique
- Logs détaillés

## Formation Utilisateur

### Points Clés à Expliquer
1. **Nouvelles fonctionnalités** disponibles
2. **Changements d'interface** principaux
3. **Nouvelles permissions** et rôles
4. **Rapports avancés** disponibles

### Documentation
- Guide utilisateur mis à jour
- Tutoriels vidéo (si disponibles)
- FAQ des nouvelles fonctionnalités

## Support Post-Migration

### Vérifications à Effectuer
- [ ] Toutes les données sont présentes
- [ ] Toutes les fonctionnalités marchent
- [ ] Performance satisfaisante
- [ ] Utilisateur formé aux nouveautés
- [ ] Sauvegardes supprimées (après validation)

### En Cas de Problème
1. **Problème mineur** : Correction sur place
2. **Problème majeur** : Rollback et analyse
3. **Perte de données** : Restauration depuis sauvegarde

## Checklist Complète

### Avant la Visite Client
- [ ] Nouvelle version construite et testée
- [ ] Scripts de migration préparés
- [ ] Documentation mise à jour
- [ ] Plan de rollback défini

### Chez le Client
- [ ] Sauvegarde complète effectuée
- [ ] Migration exécutée avec succès
- [ ] Validation complète passée
- [ ] Formation utilisateur donnée
- [ ] Documentation laissée sur place

### Après la Visite
- [ ] Suivi à distance effectué
- [ ] Problèmes éventuels résolus
- [ ] Satisfaction client confirmée
- [ ] Retour d'expérience documenté

## Temps Estimé

- **Sauvegarde** : 10-15 minutes
- **Migration** : 30-45 minutes
- **Validation** : 15-20 minutes
- **Formation** : 30-60 minutes
- **Total** : 1h30 à 2h30

## Contact Support

En cas de problème durant la migration :
1. Conserver tous les dossiers de sauvegarde
2. Noter les messages d'erreur exacts
3. Contacter le support technique
4. Ne pas supprimer les sauvegardes avant validation complète
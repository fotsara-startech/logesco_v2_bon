# Ajout de l'isolation par boutique pour les dates de péremption

## Problème résolu
L'isolation par boutique n'était pas fonctionnelle dans l'onglet "Expiration" du module stock car la table `DatePeremption` n'avait pas de champ `boutiqueId`.

## Solution implémentée

### 1. Modification de la base de données
- **Ajout du champ `boutiqueId`** à la table `DatePeremption`
- **Migration des données existantes** : toutes les dates de péremption existantes sont assignées à la boutique principale
- **Contraintes ajoutées** : clé étrangère vers la table `Boutique` avec cascade

### 2. Modifications du code Flutter

#### Modèle `ExpirationDate`
- Ajout du champ `boutiqueId` dans la classe
- Mise à jour des méthodes `fromJson`, `toJson` et `copyWith`

#### Service `ExpirationDateService`
- **Création** : inclusion automatique du `boutiqueId` de la boutique active
- **Récupération** : filtrage automatique par boutique active
- **Alertes** : isolation par boutique dans les statistiques

#### Contrôleur `ExpirationDateController`
- Ajout de l'écoute des changements de boutique active
- Rechargement automatique des données lors du changement de boutique
- Support du paramètre `boutiqueId` dans toutes les méthodes

#### Vue `ExpirationTabView`
- Retour au `StatefulWidget` pour gérer l'écoute des changements
- Rechargement automatique lors du changement de boutique
- Mise à jour de la documentation

## Fonctionnalités

### Isolation automatique
- Les dates de péremption sont automatiquement filtrées par boutique active
- Lors de la création d'une nouvelle date, elle est assignée à la boutique active
- Les statistiques sont calculées uniquement pour la boutique active

### Changement de boutique
- Rechargement automatique des données lors du changement de boutique
- Pas d'intervention manuelle nécessaire
- Interface utilisateur mise à jour en temps réel

### Compatibilité
- Les données existantes sont préservées et assignées à la boutique principale
- Aucune perte de données lors de la migration
- Fonctionnement normal pour les installations mono-boutique

## Migration requise

### Base de données
Exécuter le script SQL `MIGRATION_BOUTIQUE_ID_DATE_PEREMPTION.sql` :

```sql
-- Ajouter la colonne boutiqueId
ALTER TABLE DatePeremption ADD COLUMN boutiqueId INT;

-- Mettre à jour les données existantes
UPDATE DatePeremption 
SET boutiqueId = (SELECT id FROM Boutique WHERE estPrincipale = 1 LIMIT 1)
WHERE boutiqueId IS NULL;

-- Rendre la colonne obligatoire
ALTER TABLE DatePeremption MODIFY COLUMN boutiqueId INT NOT NULL;

-- Ajouter la contrainte de clé étrangère
ALTER TABLE DatePeremption 
ADD CONSTRAINT fk_dateperemption_boutique 
FOREIGN KEY (boutiqueId) REFERENCES Boutique(id);
```

### Backend API
Le backend doit être mis à jour pour :
- Accepter le paramètre `boutiqueId` lors de la création
- Filtrer par `boutiqueId` dans les requêtes de récupération
- Inclure le `boutiqueId` dans les réponses JSON

## Tests recommandés

1. **Création de dates de péremption** : vérifier que le `boutiqueId` est correctement assigné
2. **Changement de boutique** : vérifier que les données se rechargent automatiquement
3. **Filtrage** : vérifier que seules les dates de la boutique active sont affichées
4. **Migration** : vérifier que les données existantes ont été correctement migrées

## Impact sur les performances
- Index ajouté sur `boutiqueId` pour optimiser les requêtes
- Filtrage au niveau base de données (plus efficace)
- Réduction du volume de données transférées pour les installations multi-boutiques
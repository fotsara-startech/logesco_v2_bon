# Analyse: Gestion des Dates de Péremption

## 🎯 Objectifs

1. **Simple**: Facile à utiliser pour les clients
2. **Optionnel**: Ne pas compliquer pour ceux qui n'en ont pas besoin
3. **Efficace**: Alertes automatiques pour les produits périmés/proches de la péremption
4. **Flexible**: S'adapter aux différents types de produits

## 📊 Options Analysées

### Option 1: Système de Lots (Complexe)

**Principe**: Chaque entrée de stock crée un lot avec sa date de péremption

**Avantages**:
- ✅ Traçabilité complète (FIFO/FEFO)
- ✅ Gestion précise par lot
- ✅ Historique détaillé

**Inconvénients**:
- ❌ **Très complexe** à implémenter
- ❌ **Lourd** pour l'utilisateur (saisie de lot à chaque entrée)
- ❌ Nécessite refonte complète du système de stock
- ❌ Interface utilisateur complexe
- ❌ Gestion FIFO/FEFO compliquée

**Verdict**: ❌ **TROP COMPLEXE** pour vos besoins

---

### Option 2: Date de Péremption Simple sur le Produit (Trop Simple)

**Principe**: Une seule date de péremption par produit

**Avantages**:
- ✅ Très simple
- ✅ Facile à implémenter

**Inconvénients**:
- ❌ Pas adapté si plusieurs lots avec dates différentes
- ❌ Pas de traçabilité
- ❌ Impossible de gérer plusieurs dates

**Verdict**: ❌ **TROP SIMPLE** - Ne couvre pas tous les cas

---

### Option 3: Dates de Péremption Multiples (RECOMMANDÉ) ⭐

**Principe**: Table séparée pour stocker plusieurs dates de péremption par produit

**Structure**:
```
Produit
  ├── datePeremptionActivee (Boolean) - Active/désactive la gestion
  └── DatesPeremption[] (Table séparée)
        ├── produitId
        ├── datePeremption
        ├── quantite
        ├── numeroLot (optionnel)
        ├── dateEntree
        └── notes
```

**Avantages**:
- ✅ **Simple** pour l'utilisateur
- ✅ **Optionnel** (activé uniquement si nécessaire)
- ✅ **Flexible** (plusieurs dates par produit)
- ✅ Pas de refonte du système existant
- ✅ Alertes automatiques possibles
- ✅ Traçabilité basique suffisante
- ✅ Interface intuitive

**Inconvénients**:
- ⚠️ Pas de FIFO/FEFO automatique (mais pas nécessaire pour la plupart)
- ⚠️ Gestion manuelle des quantités par date

**Verdict**: ✅ **RECOMMANDÉ** - Équilibre parfait simplicité/fonctionnalité

---

## 🎯 Solution Recommandée: Option 3

### Schéma de Base de Données

```prisma
model Produit {
  // ... champs existants ...
  gestionPeremption Boolean @default(false) @map("gestion_peremption")
  datesPeremption   DatePeremption[]
}

model DatePeremption {
  id              Int      @id @default(autoincrement())
  produitId       Int      @map("produit_id")
  datePeremption  DateTime @map("date_peremption")
  quantite        Int      @default(0)
  numeroLot       String?  @map("numero_lot")
  dateEntree      DateTime @default(now()) @map("date_entree")
  notes           String?
  estEpuise       Boolean  @default(false) @map("est_epuise")
  
  produit         Produit  @relation(fields: [produitId], references: [id], onDelete: Cascade)
  
  @@index([produitId], map: "idx_dates_peremption_produit")
  @@index([datePeremption], map: "idx_dates_peremption_date")
  @@index([estEpuise], map: "idx_dates_peremption_epuise")
  @@map("dates_peremption")
}
```

### Workflow Utilisateur

#### 1. Activation pour un Produit

```
Produit > Modifier > Cocher "Gérer les dates de péremption"
```

#### 2. Ajout d'une Date de Péremption

**Lors d'un approvisionnement**:
```
Réception commande > Produit X
  ├── Quantité: 100
  ├── Date de péremption: 31/12/2026
  └── N° lot (optionnel): LOT-2026-001
```

**Ou manuellement**:
```
Produit > Dates de péremption > Ajouter
  ├── Date: 31/12/2026
  ├── Quantité: 100
  └── N° lot: LOT-2026-001
```

#### 3. Lors d'une Vente

**Option A: Automatique (Recommandé)**
- Le système déduit automatiquement de la date la plus proche
- Pas de saisie supplémentaire pour le vendeur

**Option B: Manuel**
- Le vendeur choisit la date de péremption à utiliser
- Utile si besoin de contrôle précis

#### 4. Alertes Automatiques

**Dashboard**:
```
⚠️ 5 produits expirent dans 7 jours
❌ 2 produits périmés
```

**Module Inventaire**:
```
Produit A
  ├── LOT-001: 50 unités - Expire le 15/02/2026 (1 jour) ⚠️
  └── LOT-002: 100 unités - Expire le 30/03/2026 (45 jours) ✅
```

### Interface Utilisateur

#### 1. Fiche Produit

```
┌─────────────────────────────────────────┐
│ Produit: Yaourt Nature                  │
├─────────────────────────────────────────┤
│ Référence: YAO-001                      │
│ Prix: 500 FCFA                          │
│                                         │
│ ☑ Gérer les dates de péremption        │
│                                         │
│ Dates de péremption:                    │
│ ┌─────────────────────────────────────┐ │
│ │ 15/02/2026 | 50 unités | LOT-001   │ │
│ │ 30/03/2026 | 100 unités | LOT-002  │ │
│ │ [+ Ajouter une date]                │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

#### 2. Module Inventaire - Onglet "Péremptions"

```
┌─────────────────────────────────────────────────────────┐
│ Produits Périssables                                    │
├─────────────────────────────────────────────────────────┤
│ Filtres: [Tous] [Périmés] [< 7 jours] [< 30 jours]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ ❌ Yaourt Fraise - LOT-001 (Périmé depuis 2 jours)    │
│    50 unités - Expiré le 13/02/2026                    │
│    [Retirer du stock] [Marquer comme traité]           │
│                                                         │
│ ⚠️ Yaourt Nature - LOT-001 (Expire dans 1 jour)       │
│    50 unités - Expire le 15/02/2026                    │
│    [Promotion] [Retirer]                               │
│                                                         │
│ ⏰ Lait Entier - LOT-003 (Expire dans 5 jours)        │
│    200 unités - Expire le 19/02/2026                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 3. Dashboard - Widget Péremptions

```
┌─────────────────────────────────┐
│ ⚠️ Alertes Péremption          │
├─────────────────────────────────┤
│ Périmés: 2 produits (150 unités)│
│ < 7 jours: 5 produits           │
│ < 30 jours: 12 produits         │
│                                 │
│ [Voir détails]                  │
└─────────────────────────────────┘
```

### Fonctionnalités

#### 1. Alertes Automatiques

- **Périmés**: Produits dont la date est dépassée
- **Proches de la péremption**: 
  - < 7 jours (alerte rouge)
  - < 30 jours (alerte orange)
  - < 90 jours (alerte jaune)

#### 2. Actions Possibles

- **Retirer du stock**: Marque comme épuisé, crée un mouvement de stock
- **Promotion**: Applique une remise automatique
- **Marquer comme traité**: Cache de la liste des alertes
- **Exporter**: Liste des produits à péremption proche

#### 3. Rapports

- **Rapport de péremption**: Liste des produits périmés/proches
- **Historique**: Produits retirés pour péremption
- **Valeur**: Montant des pertes dues à la péremption

### Avantages de Cette Approche

1. **Simplicité**:
   - Activation optionnelle par produit
   - Pas de complexité pour les produits non périssables
   - Interface intuitive

2. **Flexibilité**:
   - Plusieurs dates par produit
   - Numéro de lot optionnel
   - Notes personnalisables

3. **Pas de Refonte**:
   - S'intègre au système existant
   - Pas de modification du flux de vente
   - Compatible avec le stock actuel

4. **Alertes Utiles**:
   - Dashboard avec résumé
   - Notifications visuelles
   - Rapports détaillés

5. **Performance**:
   - Pas d'impact sur les produits non périssables
   - Requêtes optimisées avec index
   - Calculs simples

### Limitations Acceptables

1. **Pas de FIFO automatique**:
   - Le vendeur peut choisir manuellement
   - Ou déduction automatique de la date la plus proche
   - Suffisant pour la plupart des cas

2. **Gestion manuelle des quantités**:
   - L'utilisateur met à jour les quantités
   - Ou déduction automatique lors des ventes
   - Simple et compréhensible

3. **Pas de traçabilité complète**:
   - Pas de suivi lot par lot dans les ventes
   - Suffisant pour les besoins réglementaires de base
   - Peut être ajouté plus tard si nécessaire

## 🎯 Recommandation Finale

**Option 3: Dates de Péremption Multiples**

Cette approche offre le meilleur équilibre entre:
- ✅ Simplicité d'utilisation
- ✅ Fonctionnalités suffisantes
- ✅ Optionnalité (pas d'impact si non utilisé)
- ✅ Facilité d'implémentation
- ✅ Maintenance simple

## 📋 Plan d'Implémentation

### Phase 1: Base de Données
1. Ajouter champ `gestionPeremption` à `Produit`
2. Créer table `DatePeremption`
3. Migration Prisma

### Phase 2: Backend
1. Routes CRUD pour dates de péremption
2. Endpoint alertes péremption
3. Logique de déduction automatique

### Phase 3: Frontend
1. Toggle "Gérer péremption" dans fiche produit
2. Liste des dates de péremption
3. Onglet "Péremptions" dans inventaire
4. Widget dashboard

### Phase 4: Fonctionnalités Avancées
1. Alertes automatiques
2. Rapports
3. Actions (retirer, promotion)
4. Export

## ⏱️ Estimation

- Phase 1: 30 minutes
- Phase 2: 2 heures
- Phase 3: 3 heures
- Phase 4: 2 heures

**Total**: ~7-8 heures de développement

---

**Conclusion**: L'Option 3 est la solution idéale pour vos besoins. Simple, optionnelle, et suffisamment puissante pour gérer les produits périssables sans compliquer le système pour les autres produits.

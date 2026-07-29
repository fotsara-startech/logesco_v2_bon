# Ajout des champs NUI et RCCM aux clients

## Résumé
Ajout des champs **NUI** (Numéro d'Identification Unique) et **RCCM** (Registre du Commerce et du Crédit Mobilier) au formulaire de création de clients. Ces champs sont optionnels et destinés aux clients entreprises. Ils apparaissent automatiquement sur les reçus lorsqu'ils sont renseignés.

## Modifications effectuées

### 1. Backend (Prisma Schema & Migration)

#### Schema Prisma (`backend/prisma/schema.prisma`)
- Ajout des champs `nui` et `rccm` (optionnels) au modèle `Client`

#### Migration SQL (`backend/prisma/migrations/20260717125521_add_nui_rccm_to_clients/migration.sql`)
- Ajout des colonnes `nui` et `rccm` (VARCHAR 255, NULL)
- Création d'index pour faciliter les recherches

### 2. Frontend Flutter

#### Modèle Client (`logesco_v2/lib/features/customers/models/customer.dart`)
- Ajout des propriétés `nui` et `rccm` dans la classe `Customer`
- Ajout des propriétés dans `CustomerForm`
- Mise à jour de `fromJson()`, `toJson()` et `copyWith()` pour inclure les nouveaux champs

#### Contrôleur (`logesco_v2/lib/features/customers/controllers/customer_form_controller.dart`)
- Ajout des contrôleurs `nuiController` et `rccmController`
- Mise à jour de `_populateForm()` pour remplir les champs NUI et RCCM en mode édition
- Mise à jour de `saveCustomer()` pour envoyer les valeurs au backend
- Mise à jour de `resetForm()` et `onClose()` pour gérer les nouveaux contrôleurs

#### Vue Formulaire (`logesco_v2/lib/features/customers/views/customer_form_view.dart`)
- Ajout d'une section "Informations entreprise (optionnel)"
- Ajout des champs de saisie pour NUI et RCCM
- Texte explicatif indiquant que ces champs sont nécessaires pour les clients entreprises

#### Templates de reçus
Mise à jour de tous les templates pour afficher NUI et RCCM quand renseignés :

1. **Template Thermique** (`logesco_v2/lib/features/printing/widgets/receipt_template_thermal.dart`)
   - Affichage NUI et RCCM sous le nom du client

2. **Template Base (A4/A5)** (`logesco_v2/lib/features/printing/widgets/receipt_template_base.dart`)
   - Affichage NUI et RCCM dans les informations client (format lignes)

3. **Preview PDF** (`logesco_v2/lib/features/printing/views/receipt_preview_page.dart`)
   - Affichage NUI et RCCM dans les sections thermique et A4/A5

## Utilisation

### Pour les utilisateurs

1. **Créer/Modifier un client entreprise** :
   - Remplir le formulaire client normalement
   - Faire défiler jusqu'à la section "Informations entreprise (optionnel)"
   - Renseigner le NUI et/ou RCCM si le client est une entreprise
   - Sauvegarder

2. **Sur les reçus** :
   - Les champs NUI et RCCM apparaissent automatiquement sous le nom du client s'ils sont renseignés
   - Format : 
     ```
     Client: NOM DU CLIENT
     NUI: A1234567890
     RCCM: CD/KNG/RCCM/12-A-12345
     ```

### Pour les développeurs

#### Appliquer la migration

```bash
cd backend
npx prisma migrate deploy
```

Ou pour créer une nouvelle migration en développement :
```bash
npx prisma migrate dev --name add_nui_rccm_to_clients
```

#### Régénérer le client Prisma
```bash
npx prisma generate
```

## Exemples de valeurs

- **NUI** : A1234567890, B9876543210
- **RCCM** : CD/KNG/RCCM/12-A-12345, CD/BAS/RCCM/23-B-67890

## Notes techniques

- Les champs sont complètement optionnels (pas de validation requise)
- Capitalisation automatique des caractères (textCapitalization: TextCapitalization.characters)
- Les champs apparaissent sur tous les formats de reçus (thermique, A4, A5)
- Les index sur NUI et RCCM permettent des recherches rapides si nécessaire ultérieurement

## Compatibilité

- ✅ Backend Node.js + Prisma
- ✅ Frontend Flutter (iOS, Android, Web, Desktop)
- ✅ Tous les formats de reçus (Thermique 80mm, A4, A5)
- ✅ Migration réversible (colonnes peuvent être supprimées si nécessaire)

## Date de création
17 juillet 2026

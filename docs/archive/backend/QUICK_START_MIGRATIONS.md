# Guide Rapide - Ajouter une Colonne/Table qui Arrive Chez Tous les Clients

Voir [`MIGRATIONS.md`](MIGRATIONS.md) pour le fonctionnement complet. Ici, le
processus condensé pour le cas le plus courant.

## Processus en 3 étapes

### 1. Modifier le schéma Prisma

```prisma
// backend/prisma/schema.prisma
model MaTable {
  id               Int      @id @default(autoincrement())
  nouvelleColonne  String?  @map("nouvelle_colonne")
  @@map("ma_table")
}
```

### 2. Créer la migration SQL

```
backend/prisma/migrations/add_nouvelle_colonne_ma_table/migration.sql
```
```sql
ALTER TABLE ma_table ADD COLUMN nouvelle_colonne TEXT;
```

### 3. Enregistrer la migration dans le manifest

Dans `backend/src/services/migration-runner.js`, ajouter le nom du dossier à
la **fin** de `MIGRATION_ORDER` :

```javascript
const MIGRATION_ORDER = [
  // ... existantes
  'add_nouvelle_colonne_ma_table',   // ⭐ NOUVEAU
];
```

C'est l'étape qui garantit que la migration sera rejouée chez tous les
clients existants au prochain démarrage après mise à jour. L'oublier =
colonne jamais créée chez personne, silencieusement.

## Vérifier avant de livrer

```bash
node backend/verify-migration-system.js
```

Ce script échoue si un dossier `prisma/migrations/*/migration.sql` n'a pas
d'entrée correspondante dans `MIGRATION_ORDER` (ou inversement) — c'est
exactement la classe de bug qui causait des migrations manquantes chez
certains clients.

## Tester en local

```bash
npm start
```

Logs attendus (poste avec DB existante, migration en attente) :
```
🔄 1 migration(s) en attente — application...
✅ Migration appliquée: add_nouvelle_colonne_ma_table
```

Au redémarrage suivant (rien en attente), aucune de ces lignes n'apparaît —
c'est le fast path normal.

## Déploiement

Le build (`build.ps1`) embarque `prisma/migrations/` dans l'exécutable
portable (`build-exe.js` copie tout `prisma/`). Aucune action manuelle sur
le poste client n'est nécessaire : au premier démarrage après mise à jour,
`migrationRunner.run()` détecte et applique la migration automatiquement.

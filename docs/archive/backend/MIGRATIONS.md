# Système de Migrations Automatiques - LOGESCO Backend

## Vue d'ensemble

Les postes clients (SQLite local) n'exécutent jamais le CLI `prisma migrate` au
démarrage — un spawn de process est trop lent (5-20s). C'est pour ça qu'un
"fast path" existait déjà : sauter toute vérification dès que la base de
données existait. Le problème : ce fast path sautait *toutes* les migrations,
pas seulement le spawn du CLI. Le rattrapage reposait sur 2-3 listes de
`ALTER TABLE` codées à la main dans `server.js` et `schema-validator.js`,
désynchronisées de `schema.prisma` — d'où des colonnes/tables manquantes chez
certains clients après une mise à jour (`ventes_proforma` et
`details_ventes_proforma` n'existaient même pas du tout sur certains postes).

La solution : [`src/services/migration-runner.js`](src/services/migration-runner.js)
lit et exécute directement les fichiers `migration.sql` de `prisma/migrations/`
— la même source que l'historique Prisma — en gardant la trace de ce qui a
déjà été appliqué dans une table `_app_migrations`. Aucun process n'est
spawné : tout passe par la connexion Prisma déjà ouverte, donc le démarrage
reste rapide (le cas normal — rien en attente — coûte une seule requête SQL,
~1ms).

## Comment ça fonctionne

Au démarrage (`server.js` → `start()`) :

```
1. _runAutoMigration()    → `prisma db push` UNIQUEMENT si la DB n'existe pas
                             encore (première installation). Retourne
                             freshInstall = true/false.
2. databaseManager.initialize() → ouvre la connexion Prisma
3. migrationRunner.run(prisma, { freshInstall })
     - freshInstall = true  → marque tout MIGRATION_ORDER comme appliqué
       (le schéma vient d'être créé à jour par db push, rien à rejouer)
     - freshInstall = false → compare MIGRATION_ORDER à _app_migrations,
       exécute uniquement les migrations manquantes (mise à jour d'un poste
       existant), puis les marque appliquées
4. _runAutoSeed()          → crée les données initiales si DB vide
```

Ignoré entièrement en cloud (PostgreSQL/Neon) : ce backend-là utilise
`prisma migrate deploy` au moment du déploiement (voir `deploy-render.sh`),
qui a son propre mécanisme fiable de suivi (`_prisma_migrations`).

## Livrer une nouvelle migration

1. Modifier `prisma/schema.prisma` comme d'habitude.
2. Créer `prisma/migrations/<nom_explicite>/migration.sql` avec le SQL SQLite
   correspondant (`ALTER TABLE ... ADD COLUMN`, `CREATE TABLE`, `CREATE INDEX
   IF NOT EXISTS`, etc.).
3. Ajouter `<nom_explicite>` à la fin de `MIGRATION_ORDER` dans
   `src/services/migration-runner.js`. **C'est l'étape qui compte** : un
   fichier `migration.sql` qui n'est pas dans `MIGRATION_ORDER` ne sera
   jamais appliqué à un client existant.
4. Lancer `node backend/verify-migration-system.js` — il vérifie que chaque
   dossier de `prisma/migrations/` a une entrée dans `MIGRATION_ORDER` et
   inversement (et donc qu'aucune migration ne peut être oubliée).

### Contraintes sur le SQL

Le runner découpe `migration.sql` naïvement sur `;` après avoir retiré les
lignes de commentaire (`--`). Ça suffit pour des `ALTER`/`CREATE`/`UPDATE`
simples (c'est tout ce que contiennent les migrations actuelles), mais
**n'écrivez pas de trigger ni de bloc `BEGIN...END`** dans ces fichiers — le
split naïf le casserait. SQLite ne supporte pas `ADD COLUMN IF NOT EXISTS` ;
le runner absorbe silencieusement les erreurs `duplicate column name` /
`already exists` pour rester idempotent (utile si un client a déjà reçu
l'effet via l'ancien mécanisme ad-hoc).

## Logs

```
✅ 13 migration(s) marquée(s) comme appliquées (installation neuve)
```
— installation neuve, rien à rejouer (le schéma vient d'être créé à jour).

```
🔄 2 migration(s) en attente — application...
✅ Migration appliquée: add_proforma_tables
✅ Migration appliquée: add_financial_movements_statut
```
— mise à jour d'un poste existant : seules les migrations manquantes tournent.

Rien du tout dans les logs = fast path, aucune migration en attente (cas normal).

## Test manuel

`verify-migration-system.js` ne vérifie que la cohérence des fichiers, pas
l'exécution réelle du SQL. Pour tester l'exécution :

```bash
# Créer une DB de test à jour
$env:DATABASE_URL = "file:C:/chemin/vers/test.db"
node backend/node_modules/prisma/build/index.js db push --accept-data-loss --schema=backend/prisma/schema.prisma

# Puis, dans un script node, simuler un vieux client en retirant une table/colonne
# et une ligne de _app_migrations, et appeler migrationRunner.run(prisma, { freshInstall: false })
```

## Limitations

- SQLite ne supporte pas `DROP COLUMN`/`ALTER COLUMN` facilement (nécessite
  recréation de table) — à éviter dans les migrations locales si possible.
- Le découpage SQL est naïf (voir "Contraintes sur le SQL" ci-dessus).

# Guide de Réinitialisation Neon (Après Suppression Manuelle)

## Situation

Vous avez supprimé manuellement toutes les données sur Neon et exécuté le fichier `migration.sql` manuellement. Maintenant, la synchronisation automatique ne fonctionne plus.

## Problème identifié

L'erreur `ETIMEDOUT` indique que la connexion à Neon expire. Causes possibles :
1. **Base de données Neon en pause** (inactivité > 5 minutes sur le plan gratuit)
2. **Pare-feu bloquant le port 5432**
3. **Problème de réseau/proxy**

---

## ÉTAPE 0 — Diagnostic préalable

Avant de commencer, vérifions que Neon est accessible :

```powershell
cd backend
node scripts/check-neon-status.js
```

### Si le test échoue :

#### ✅ Solution 1 : Réactiver la base de données Neon

1. Allez sur https://console.neon.tech/
2. Sélectionnez votre projet
3. Si vous voyez "Database is paused", cliquez sur **"Resume"** ou **"Activate"**
4. Attendez 10-20 secondes que la base redémarre
5. Relancez le test : `node scripts/check-neon-status.js`

#### ✅ Solution 2 : Tester depuis un autre réseau

Si le pare-feu bloque le port 5432 :
1. Activez le partage de connexion sur votre téléphone
2. Connectez votre PC au réseau mobile
3. Relancez le test

#### ✅ Solution 3 : Régénérer les credentials Neon

Si l'authentification échoue :
1. Allez sur https://console.neon.tech/
2. Sélectionnez votre projet
3. Onglet **"Connection Details"**
4. Cliquez sur **"Reset password"**
5. Copiez la nouvelle connection string
6. Mettez à jour `CLOUD_DB_URL` dans `backend/.env`

---

## ÉTAPE 1 — Réinitialiser Neon avec Prisma Migrate

Une fois que Neon est accessible (test réussi), réinitialisez proprement la base de données :

```powershell
cd backend

# 1. Définir l'URL Neon comme DATABASE_URL temporaire
$env:DATABASE_URL = $env:CLOUD_DB_URL

# 2. Sauvegarder les migrations SQLite
if (Test-Path "prisma\migrations") {
    Move-Item -Path "prisma\migrations" -Destination "prisma\migrations_sqlite_bak" -Force
}

# 3. Copier les migrations PostgreSQL
Copy-Item -Path "prisma\migrations_pg" -Destination "prisma\migrations" -Recurse -Force

# 4. Déployer le schéma sur Neon
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma

# 5. Restaurer les migrations SQLite
Remove-Item -Recurse -Force "prisma\migrations"
Move-Item -Path "prisma\migrations_sqlite_bak" -Destination "prisma\migrations" -Force

# 6. Réinitialiser DATABASE_URL
$env:DATABASE_URL = "file:./database/logesco.db"
```

✅ Si vous voyez `All migrations have been successfully applied`, Neon est prêt.

---

## ÉTAPE 2 — Réinitialiser les métadonnées de synchronisation locale

```powershell
npm run sync:reset
```

Cela va :
- Réinitialiser `last_pull` à epoch (1970)
- Réinitialiser `initial_pull_done` à 0
- Marquer toutes les opérations en attente comme non synchronisées

---

## ÉTAPE 3 — Redémarrer le serveur

```powershell
npm start
```

Au démarrage, vous devriez voir :

```
☁️  Connexion Neon établie — mode hybride actif
🔄 Neon est la source de vérité — réinitialisation du local avant pull...
✅ Local vidé — pull complet depuis Neon en cours...
📦 Neon vide — démarrage de la sync initiale...
  ✓ user_roles: X enregistrements
  ✓ utilisateurs: X enregistrements
  ✓ produits: X enregistrements
  ...
✅ Sync initiale terminée — X enregistrements envoyés vers Neon
🔄 Mode sync: hybrid
```

---

## ÉTAPE 4 — Vérification sur Neon

1. Allez sur https://console.neon.tech/
2. Sélectionnez votre projet
3. Onglet **"SQL Editor"**
4. Exécutez :

```sql
SELECT 
  'utilisateurs' as table_name, COUNT(*) as count FROM utilisateurs
UNION ALL
SELECT 'produits', COUNT(*) FROM produits
UNION ALL
SELECT 'clients', COUNT(*) FROM clients
UNION ALL
SELECT 'ventes', COUNT(*) FROM ventes
UNION ALL
SELECT 'boutiques', COUNT(*) FROM boutiques;
```

Vous devriez voir vos données locales synchronisées.

---

## Résumé des commandes

```powershell
# 0. Diagnostic
node scripts/check-neon-status.js

# 1. Réinitialiser Neon avec Prisma (si test réussi)
$env:DATABASE_URL = $env:CLOUD_DB_URL
Move-Item -Path "prisma\migrations" -Destination "prisma\migrations_sqlite_bak" -Force
Copy-Item -Path "prisma\migrations_pg" -Destination "prisma\migrations" -Recurse -Force
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
Remove-Item -Recurse -Force "prisma\migrations"
Move-Item -Path "prisma\migrations_sqlite_bak" -Destination "prisma\migrations" -Force
$env:DATABASE_URL = "file:./database/logesco.db"

# 2. Réinitialiser les métadonnées
npm run sync:reset

# 3. Redémarrer
npm start
```

---

## En cas d'échec persistant

### Si Neon reste inaccessible (ETIMEDOUT)

**Option A : Utiliser un VPN**
- Installez un VPN gratuit (ProtonVPN, Windscribe)
- Connectez-vous à un serveur européen
- Relancez les tests

**Option B : Créer un nouveau projet Neon**
1. Créez un nouveau projet sur https://console.neon.tech/
2. Copiez la nouvelle connection string
3. Mettez à jour `CLOUD_DB_URL` dans `.env`
4. Suivez les étapes 1-3 ci-dessus

**Option C : Mode local uniquement (temporaire)**
1. Commentez `CLOUD_DB_URL` dans `.env` :
   ```env
   # CLOUD_DB_URL="postgresql://..."
   ```
2. Redémarrez le serveur
3. Le système fonctionnera en mode 100% local
4. Réactivez Neon plus tard quand le problème réseau sera résolu

---

## Prévention future

Pour éviter ce problème à l'avenir :

1. **Ne jamais supprimer manuellement les données Neon** sans suivre ce guide
2. **Toujours utiliser Prisma Migrate** pour gérer le schéma :
   ```powershell
   npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
   ```
3. **Faire des sauvegardes** avant toute opération destructive
4. **Utiliser les scripts fournis** pour gérer la synchronisation

---

## Support

Si le problème persiste après avoir suivi ce guide :

1. Vérifiez les logs détaillés du serveur
2. Testez la connexion depuis un autre réseau
3. Vérifiez l'état de Neon sur https://status.neon.tech/
4. Contactez le support Neon si nécessaire

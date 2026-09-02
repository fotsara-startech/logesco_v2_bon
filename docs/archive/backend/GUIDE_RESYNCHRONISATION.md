# Guide de Resynchronisation après Recréation Manuelle de Neon

## Problème

Après avoir supprimé et recréé manuellement la base de données Neon, les synchronisations (local → Neon et Neon → local) ne s'exécutent plus.

## Cause

Le système de synchronisation utilise des métadonnées (`sync_meta`) dans SQLite local pour suivre :
- `last_pull` : Date du dernier pull depuis Neon
- `initial_pull_done` : Indicateur si le pull initial a été effectué

Quand vous recréez Neon manuellement, ces métadonnées ne sont pas réinitialisées, donc le SyncService pense que tout est déjà synchronisé.

## Solution

### Option 1 : Réinitialisation des métadonnées + synchronisation automatique

Cette option réinitialise les métadonnées et laisse le SyncService faire son travail automatiquement.

```bash
# 1. Arrêter le serveur si en cours d'exécution
# Ctrl+C dans le terminal

# 2. Réinitialiser les métadonnées de synchronisation
cd backend
npm run sync:reset

# 3. Redémarrer le serveur
npm start
```

Le serveur va automatiquement :
- Détecter que Neon est vide
- Envoyer toutes les données locales vers Neon (push complet)
- Synchroniser en continu toutes les 30 secondes

### Option 2 : Synchronisation forcée manuelle

Cette option force une synchronisation complète immédiate de toutes les données locales vers Neon.

```bash
# 1. Arrêter le serveur si en cours d'exécution
# Ctrl+C dans le terminal

# 2. Forcer la synchronisation complète
cd backend
npm run sync:force

# 3. Réinitialiser les métadonnées
npm run sync:reset

# 4. Redémarrer le serveur
npm start
```

## Vérification

Après avoir redémarré le serveur, vérifiez les logs :

```
✅ SyncService démarré
🔄 Mode sync: hybrid
📤 Push X opération(s) vers Neon...
✅ Sync initiale terminée — X enregistrements envoyés vers Neon
```

Vous pouvez aussi vérifier l'état de la synchronisation via l'endpoint health :

```bash
curl http://localhost:8080/health
```

Réponse attendue :
```json
{
  "status": "ok",
  "uptime": 123.45,
  "sync": {
    "cloudEnabled": true,
    "cloudAvailable": true,
    "mode": "hybrid"
  }
}
```

## Vérification sur Neon

Connectez-vous à votre console Neon et vérifiez que les tables sont peuplées :

```sql
-- Vérifier le nombre d'enregistrements
SELECT 
  'utilisateurs' as table_name, COUNT(*) as count FROM utilisateurs
UNION ALL
SELECT 'produits', COUNT(*) FROM produits
UNION ALL
SELECT 'clients', COUNT(*) FROM clients
UNION ALL
SELECT 'ventes', COUNT(*) FROM ventes;
```

## Dépannage

### La synchronisation ne démarre toujours pas

1. Vérifiez que `CLOUD_DB_URL` est bien défini dans `.env` :
   ```bash
   cat .env | grep CLOUD_DB_URL
   ```

2. Vérifiez la connexion à Neon :
   ```bash
   node -e "const {Pool}=require('pg');const p=new Pool({connectionString:process.env.CLOUD_DB_URL,ssl:{rejectUnauthorized:false}});p.query('SELECT 1').then(()=>console.log('✅ Neon OK')).catch(e=>console.error('❌',e.message)).finally(()=>p.end())"
   ```

3. Vérifiez les métadonnées de synchronisation :
   ```bash
   node -e "const {PrismaClient}=require('./src/config/prisma-client');const p=new PrismaClient();p.\$queryRawUnsafe('SELECT * FROM sync_meta').then(r=>console.log(r)).finally(()=>p.\$disconnect())"
   ```

### Erreurs de contraintes FK lors de la synchronisation

Si vous voyez des erreurs de type "foreign key constraint failed", cela signifie que l'ordre de synchronisation n'est pas respecté. Le script `force-full-sync.js` respecte l'ordre des dépendances FK.

### Données dupliquées

Si vous avez des données dupliquées après la synchronisation, c'est probablement parce que Neon n'était pas complètement vide. Vous pouvez :

1. Vider complètement Neon via la console Neon
2. Relancer `npm run sync:force`

## Scripts disponibles

- `npm run sync:reset` : Réinitialise les métadonnées de synchronisation
- `npm run sync:force` : Force une synchronisation complète local → Neon

## Notes importantes

- **Toujours arrêter le serveur** avant d'exécuter les scripts de synchronisation
- **Neon est la source de vérité** : si plusieurs machines sont connectées, Neon contient les données partagées
- **SQLite local est le cache** : chaque machine a sa propre copie locale pour fonctionner offline
- **La synchronisation est bidirectionnelle** : local → Neon (push) et Neon → local (pull)
- **La synchronisation est automatique** : toutes les 30 secondes quand le serveur est en cours d'exécution

## Prévention

Pour éviter ce problème à l'avenir :

1. **Ne jamais supprimer manuellement la base Neon** sans réinitialiser les métadonnées locales
2. **Utiliser les migrations Prisma** : `npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma`
3. **Faire des sauvegardes** avant toute opération destructive sur Neon
4. **Utiliser les scripts fournis** pour gérer la synchronisation

## Support

Si le problème persiste, vérifiez :
- Les logs du serveur pour des erreurs spécifiques
- La console Neon pour des problèmes de connexion
- Les permissions de la base de données Neon

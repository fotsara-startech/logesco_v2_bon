# Ajout de la synchronisation pour user_boutique_assignments

## Problème identifié

La table `user_boutique_assignments` n'était **pas synchronisée vers Neon**. Cette table est critique car elle définit quels utilisateurs ont accès à quelles boutiques dans un environnement multi-boutique.

### Conséquences

- ❌ Les assignations boutique-utilisateur restaient uniquement en local (SQLite)
- ❌ En cas de connexion depuis un autre appareil, les utilisateurs n'avaient pas accès aux bonnes boutiques
- ❌ Les droits d'accès multi-boutique n'étaient pas cohérents entre les installations
- ❌ Impossible de gérer centralement les accès depuis Neon

## Structure de la table

### Modèle UserBoutiqueAssignment (Prisma)
```prisma
model UserBoutiqueAssignment {
  id               Int         @id @default(autoincrement())
  utilisateurId    Int         @map("utilisateur_id")
  boutiqueId       Int         @map("boutique_id")
  roleId           Int?        @map("role_id")
  isActive         Boolean     @default(true) @map("is_active")
  
  utilisateur      Utilisateur @relation(...)
  boutique         Boutique    @relation(...)
  role             UserRole?   @relation(...)
  
  @@map("user_boutique_assignments")
  @@unique([utilisateurId, boutiqueId])
}
```

### Endpoints concernés

1. **POST `/api/v1/boutiques/:id/users`** - Assigner un utilisateur à une boutique
2. **DELETE `/api/v1/boutiques/:id/users/:userId`** - Retirer un utilisateur d'une boutique
3. **PUT `/api/v1/users/:id/boutiques`** - Remplacer toutes les assignations d'un utilisateur

## Solution implémentée

### 1. Ajout dans l'ordre de priorité de synchronisation

**Fichiers modifiés :**
- `backend/src/services/sync-service.js`
- `dist-exe/src/services/sync-service.js`

**Changement :**
Ajout de `user_boutique_assignments` à la priorité **4** dans le CASE ORDER BY, juste après `boutiques` (priorité 3) car il dépend de l'existence des utilisateurs et des boutiques.

```javascript
WHEN 'user_roles' THEN 1
WHEN 'utilisateurs' THEN 2
WHEN 'boutiques' THEN 3
WHEN 'user_boutique_assignments' THEN 4  // ✅ Ajouté
WHEN 'categories' THEN 5
// ... etc
```

### 2. Injection du syncService dans les routers

**Fichiers modifiés :**
- `backend/src/server.js`
- `dist-exe/src/server.js`

**Avant :**
```javascript
this.app.use(`/api/${apiVersion}/users`, createUserRouter({
  authService: this.authService
}));

this.app.use(`/api/${apiVersion}/boutiques`, createBoutiquesRouter({
  prisma: this.models.prisma,
  authService: this.authService
}));
```

**Après :**
```javascript
this.app.use(`/api/${apiVersion}/users`, createUserRouter({
  authService: this.authService,
  syncService: this.syncService  // ✅ Ajouté
}));

this.app.use(`/api/${apiVersion}/boutiques`, createBoutiquesRouter({
  prisma: this.models.prisma,
  authService: this.authService,
  syncService: this.syncService  // ✅ Ajouté
}));
```

### 3. Mise à jour des signatures des fonctions

**Fichiers modifiés :**
- `backend/src/routes/users.js`
- `backend/src/routes/boutiques.js`
- `dist-exe/src/routes/users.js`
- `dist-exe/src/routes/boutiques.js`

**Avant :**
```javascript
function createUserRouter(dependencies) {
  const router = express.Router();
  const { authService } = dependencies;
```

**Après :**
```javascript
function createUserRouter(dependencies) {
  const router = express.Router();
  const { authService, syncService } = dependencies;  // ✅ syncService ajouté
```

### 4. Ajout des enqueues dans les endpoints

#### A. POST /boutiques/:id/users (Assigner un utilisateur)

**Fichier :** `backend/src/routes/boutiques.js` & `dist-exe/src/routes/boutiques.js`

```javascript
const assignment = await prisma.userBoutiqueAssignment.upsert({
  where: { utilisateurId_boutiqueId: { utilisateurId: parseInt(utilisateurId), boutiqueId } },
  update: { roleId: roleId ? parseInt(roleId) : null, isActive: true },
  create: { utilisateurId: parseInt(utilisateurId), boutiqueId, roleId: roleId ? parseInt(roleId) : null, isActive: true },
  // ... include
});

res.status(201).json(BaseResponseDTO.success(assignment, 'Utilisateur assigné à la boutique'));

// ✅ Enqueue pour sync vers Neon
if (syncService) {
  await syncService.enqueue('user_boutique_assignments', assignment.id ? 'UPDATE' : 'INSERT', {
    id: assignment.id,
    utilisateurId: assignment.utilisateurId,
    boutiqueId: assignment.boutiqueId,
    roleId: assignment.roleId,
    isActive: assignment.isActive
  });
}
```

#### B. DELETE /boutiques/:id/users/:userId (Retirer un utilisateur)

**Fichier :** `backend/src/routes/boutiques.js` & `dist-exe/src/routes/boutiques.js`

```javascript
await prisma.userBoutiqueAssignment.update({
  where: { utilisateurId_boutiqueId: { utilisateurId, boutiqueId } },
  data: { isActive: false }
});

res.json(BaseResponseDTO.success(null, 'Utilisateur retiré de la boutique'));

// ✅ Enqueue pour sync vers Neon
if (syncService) {
  await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
    utilisateurId,
    boutiqueId,
    isActive: false
  });
}
```

#### C. PUT /users/:id/boutiques (Remplacer toutes les assignations)

**Fichier :** `backend/src/routes/users.js` & `dist-exe/src/routes/users.js`

```javascript
// Désactiver toutes les assignations existantes
await prisma.userBoutiqueAssignment.updateMany({
  where: { utilisateurId: id },
  data: { isActive: false }
});

// Créer ou réactiver les nouvelles assignations
for (const boutiqueId of boutiqueIds) {
  await prisma.userBoutiqueAssignment.upsert({
    where: { utilisateurId_boutiqueId: { utilisateurId: id, boutiqueId: parseInt(boutiqueId) } },
    update: { isActive: true },
    create: { utilisateurId: id, boutiqueId: parseInt(boutiqueId), isActive: true }
  });
}

res.json({ success: true, message: 'Assignations mises à jour avec succès' });

// ✅ Enqueue pour sync vers Neon - récupérer toutes les assignations de l'utilisateur
if (syncService) {
  const allAssignments = await prisma.userBoutiqueAssignment.findMany({
    where: { utilisateurId: id }
  });
  for (const assignment of allAssignments) {
    await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
      id: assignment.id,
      utilisateurId: assignment.utilisateurId,
      boutiqueId: assignment.boutiqueId,
      roleId: assignment.roleId,
      isActive: assignment.isActive
    });
  }
}
```

## Importance de l'ordre de synchronisation

La table `user_boutique_assignments` dépend de :
- `utilisateurs` (priorité 2)
- `boutiques` (priorité 3)

C'est pourquoi elle a la priorité **4** dans le CASE ORDER BY. Cela garantit que lors de la synchronisation :
1. Les utilisateurs sont synchronisés en premier
2. Les boutiques sont synchronisées ensuite
3. Les assignations utilisateur-boutique sont synchronisées après

Sans cet ordre, les contraintes de clés étrangères (FK) pourraient échouer lors de l'insertion dans Neon.

## Impact

### Avant la correction

- ❌ Les assignations restaient uniquement locales
- ❌ Incohérence des accès entre appareils
- ❌ Impossible de gérer centralement les accès multi-boutique

### Après la correction

- ✅ Toutes les assignations sont synchronisées vers Neon
- ✅ Cohérence des accès entre tous les appareils
- ✅ Gestion centralisée possible depuis Neon
- ✅ Traçabilité des assignations (qui a accès à quoi)

## Cas d'usage

### Scénario 1 : Assigner un vendeur à une boutique

```
1. Admin assigne "Jean" à la boutique "Paris Centre"
   → POST /boutiques/2/users { utilisateurId: 5, roleId: 3 }
2. Assignment créé en local (SQLite)
3. Enqueue vers sync_queue
4. Cycle de sync → Push vers Neon
5. ✅ Jean peut maintenant accéder à la boutique depuis n'importe quel appareil
```

### Scénario 2 : Retirer un utilisateur d'une boutique

```
1. Admin retire "Jean" de la boutique "Paris Centre"
   → DELETE /boutiques/2/users/5
2. Assignment.isActive = false en local
3. Enqueue vers sync_queue
4. Cycle de sync → Push vers Neon
5. ✅ Jean perd l'accès immédiatement partout
```

### Scénario 3 : Réassigner toutes les boutiques d'un utilisateur

```
1. Admin change les boutiques de "Marie" (enlever Lyon, ajouter Marseille)
   → PUT /users/8/boutiques { boutiqueIds: [1, 3, 5] }
2. Toutes les assignments sont désactivées, puis réactivées/créées
3. Enqueue de TOUTES les assignments (actives et inactives)
4. Cycle de sync → Push vers Neon
5. ✅ Marie a maintenant accès uniquement aux boutiques 1, 3 et 5
```

## Tests recommandés

### 1. Test d'assignation

```bash
curl -X POST http://localhost:8080/api/v1/boutiques/1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "utilisateurId": 2,
    "roleId": 3
  }'

# Vérifier la queue de sync
SELECT * FROM sync_queue WHERE table_name = 'user_boutique_assignments' ORDER BY id DESC LIMIT 1;
```

### 2. Test de retrait

```bash
curl -X DELETE http://localhost:8080/api/v1/boutiques/1/users/2 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Vérifier que isActive = false est bien enqueued
SELECT data FROM sync_queue WHERE table_name = 'user_boutique_assignments' ORDER BY id DESC LIMIT 1;
```

### 3. Vérification dans Neon

```sql
-- Connexion à Neon PostgreSQL
SELECT 
  uba.id,
  u.nom_utilisateur,
  b.nom as boutique,
  r.nom as role,
  uba.is_active
FROM user_boutique_assignments uba
JOIN utilisateurs u ON uba.utilisateur_id = u.id
JOIN boutiques b ON uba.boutique_id = b.id
LEFT JOIN user_roles r ON uba.role_id = r.id
ORDER BY uba.id DESC;
```

### 4. Test de cohérence multi-appareils

```
1. Sur l'appareil A : Assigner utilisateur X à boutique Y
2. Attendre 30 secondes (cycle de sync)
3. Sur l'appareil B : Se connecter avec l'utilisateur X
4. ✅ L'utilisateur X doit voir la boutique Y dans sa liste
```

## Note sur la gestion des conflits

La table `user_boutique_assignments` a une contrainte unique sur `(utilisateurId, boutiqueId)`. Si deux appareils tentent de créer la même assignation en même temps :

1. SQLite local : Les deux créations réussissent localement
2. Sync vers Neon : Le premier arrive réussit, le second échoue avec conflit
3. Le service de sync gère automatiquement le conflit en ignorant le doublon

C'est pourquoi on utilise `upsert` dans le code, qui crée ou met à jour intelligemment.

## Résumé des fichiers modifiés

1. **Sync Service** (ordre de priorité)
   - `backend/src/services/sync-service.js`
   - `dist-exe/src/services/sync-service.js`

2. **Server** (injection syncService)
   - `backend/src/server.js`
   - `dist-exe/src/server.js`

3. **Routes Boutiques** (enqueue assignments)
   - `backend/src/routes/boutiques.js`
   - `dist-exe/src/routes/boutiques.js`

4. **Routes Users** (enqueue bulk updates)
   - `backend/src/routes/users.js`
   - `dist-exe/src/routes/users.js`

**Total : 8 fichiers modifiés**

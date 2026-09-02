# Ajout de la synchronisation complète pour utilisateurs et assignations

## Problème identifié

Lors de la création ou modification d'un utilisateur avec des assignations boutiques, **seul l'utilisateur** était synchronisé vers Neon. Les assignations boutiques (`user_boutique_assignments`) restaient uniquement en local.

### Flux utilisateur dans l'application

1. L'utilisateur remplit le formulaire de création/modification d'utilisateur
2. Sélectionne les boutiques auxquelles l'utilisateur doit avoir accès
3. Soumet le formulaire

**Côté Flutter (logesco_v2/lib/features/users/views/user_form_view.dart) :**
```dart
if (success) {
  final userId = user.id ?? controller.selectedUser.value?.id;
  if (userId != null && _selectedBoutiqueIds.isNotEmpty) {
    await controller.updateUserBoutiques(userId, _selectedBoutiqueIds.toList());
  }
  Get.back();
}
```

**Côté Backend - 3 appels API :**
1. `POST /api/v1/users` - Créer l'utilisateur ✅
2. `PUT /api/v1/users/:id/boutiques` - Assigner les boutiques ❌ (pas toujours synchronisé)
3. **OU** `PUT /api/v1/users/:id` - Modifier l'utilisateur ✅

## Problèmes identifiés

### 1. POST /users (Création)
- ❌ N'enregistrait pas l'utilisateur dans sync_queue
- ❌ L'utilisateur restait uniquement en SQLite local

### 2. PUT /users/:id (Modification)
- ❌ N'enregistrait pas la modification dans sync_queue
- ❌ Les changements de nom, email, rôle ne se synchronisaient pas

### 3. PUT /users/:id/boutiques (Assignations)
- ⚠️ Utilisait `'UPDATE'` pour toutes les assignations
- ⚠️ Problème : certaines assignations sont nouvellement créées avec `upsert`
- ⚠️ Devrait utiliser `'INSERT'` pour être cohérent

## Solution implémentée

### Fichiers modifiés
- `backend/src/routes/users.js`
- `dist-exe/src/routes/users.js`

### 1. POST /users - Ajout synchronisation utilisateur

**Avant :**
```javascript
const newUser = await prisma.utilisateur.create({
  data: userData,
  include: { role: true }
});

res.status(201).json({
  success: true,
  data: transformedUser
});
// ❌ Pas de synchronisation
```

**Après :**
```javascript
const newUser = await prisma.utilisateur.create({
  data: userData,
  include: { role: true }
});

res.status(201).json({
  success: true,
  data: transformedUser
});

// ✅ Enqueue pour sync vers Neon
if (syncService) {
  await syncService.enqueue('utilisateurs', 'INSERT', {
    id: newUser.id,
    nomUtilisateur: newUser.nomUtilisateur,
    email: newUser.email,
    motDePasseHash: newUser.motDePasseHash,
    roleId: newUser.roleId,
    isActive: newUser.isActive,
    dateCreation: newUser.dateCreation,
    dateModification: newUser.dateModification,
    dateDerniereConnexion: newUser.dateDerniereConnexion
  });
}
```

### 2. PUT /users/:id - Ajout synchronisation modification

**Avant :**
```javascript
const updatedUser = await prisma.utilisateur.update({
  where: { id: id },
  data: updateData,
  include: { role: true }
});

res.json({
  success: true,
  data: transformedUser
});
// ❌ Pas de synchronisation
```

**Après :**
```javascript
const updatedUser = await prisma.utilisateur.update({
  where: { id: id },
  data: updateData,
  include: { role: true }
});

res.json({
  success: true,
  data: transformedUser
});

// ✅ Enqueue pour sync vers Neon
if (syncService) {
  await syncService.enqueue('utilisateurs', 'UPDATE', {
    id: updatedUser.id,
    nomUtilisateur: updatedUser.nomUtilisateur,
    email: updatedUser.email,
    motDePasseHash: updatedUser.motDePasseHash,
    roleId: updatedUser.roleId,
    isActive: updatedUser.isActive,
    dateCreation: updatedUser.dateCreation,
    dateModification: updatedUser.dateModification,
    dateDerniereConnexion: updatedUser.dateDerniereConnexion
  });
}
```

### 3. PUT /users/:id/boutiques - Correction opération INSERT

**Avant :**
```javascript
for (const assignment of allAssignments) {
  await syncService.enqueue('user_boutique_assignments', 'UPDATE', {  // ❌ UPDATE
    id: assignment.id,
    utilisateurId: assignment.utilisateurId,
    boutiqueId: assignment.boutiqueId,
    roleId: assignment.roleId,
    isActive: assignment.isActive
  });
}
```

**Après :**
```javascript
for (const assignment of allAssignments) {
  // ✅ Utiliser INSERT pour toutes (nouvelles et existantes), le service gère les doublons
  await syncService.enqueue('user_boutique_assignments', 'INSERT', {
    id: assignment.id,
    utilisateurId: assignment.utilisateurId,
    boutiqueId: assignment.boutiqueId,
    roleId: assignment.roleId,
    isActive: assignment.isActive
  });
}
```

**Explication :** Comme les assignations utilisent `upsert`, certaines sont créées et d'autres modifiées. En utilisant `'INSERT'`, le service de sync gère automatiquement :
- Si l'ID existe dans Neon → UPDATE
- Si l'ID n'existe pas → INSERT

## Flux complet de synchronisation

### Création d'un nouvel utilisateur avec 2 boutiques

```
1. User remplit formulaire
   - Nom: "Jean Dupont"
   - Email: "jean@test.com"
   - Rôle: Vendeur
   - Boutiques: [Boutique A, Boutique B]

2. Flutter: POST /users
   → Backend crée utilisateur ID=5
   → Enqueue: utilisateurs (INSERT, id=5)
   → Response: { success: true, data: { id: 5, ... } }

3. Flutter: PUT /users/5/boutiques { boutiqueIds: [1, 2] }
   → Backend crée 2 assignations (IDs 10, 11)
   → Enqueue: user_boutique_assignments (INSERT, id=10)
   → Enqueue: user_boutique_assignments (INSERT, id=11)
   → Response: { success: true, message: "..." }

4. Cycle de sync (30 secondes)
   → Push vers Neon:
     - utilisateurs: 1 INSERT (Jean Dupont)
     - user_boutique_assignments: 2 INSERT (boutiques 1 et 2)

5. ✅ Neon contient:
   - Utilisateur Jean Dupont
   - Ses 2 assignations boutiques
```

### Modification d'un utilisateur existant

```
1. User modifie Jean Dupont
   - Nouveau rôle: Manager
   - Boutiques: [Boutique A, Boutique C] (enlève B, ajoute C)

2. Flutter: PUT /users/5
   → Backend modifie utilisateur
   → Enqueue: utilisateurs (UPDATE, id=5)

3. Flutter: PUT /users/5/boutiques { boutiqueIds: [1, 3] }
   → Backend désactive toutes les assignations
   → Réactive/crée les nouvelles
   → Enqueue: user_boutique_assignments (INSERT, id=10, isActive=true)
   → Enqueue: user_boutique_assignments (INSERT, id=11, isActive=false)
   → Enqueue: user_boutique_assignments (INSERT, id=12, isActive=true)

4. Cycle de sync
   → Push vers Neon:
     - utilisateurs: 1 UPDATE (nouveau rôle)
     - user_boutique_assignments: 3 UPSERT (1 existante, 1 désactivée, 1 nouvelle)

5. ✅ Neon contient:
   - Jean Dupont avec rôle Manager
   - Boutique A: active
   - Boutique B: inactive
   - Boutique C: active (nouvelle)
```

## Impact des corrections

### Avant

**Création d'utilisateur :**
- ✅ Utilisateur créé en local (SQLite)
- ❌ Utilisateur pas synchronisé vers Neon
- ❌ Assignations boutiques pas synchronisées
- ❌ Impossible de se connecter depuis un autre appareil

**Modification d'utilisateur :**
- ✅ Modifications en local
- ❌ Modifications pas synchronisées vers Neon
- ❌ Changements de boutiques parfois synchronisés, parfois non

### Après

**Création d'utilisateur :**
- ✅ Utilisateur créé en local
- ✅ Utilisateur synchronisé vers Neon
- ✅ Assignations boutiques synchronisées
- ✅ Connexion possible depuis n'importe quel appareil

**Modification d'utilisateur :**
- ✅ Modifications en local
- ✅ Modifications synchronisées vers Neon
- ✅ Changements de boutiques toujours synchronisés
- ✅ Cohérence totale entre appareils

## Tests recommandés

### 1. Test création utilisateur simple

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "nomUtilisateur": "test_user",
    "email": "test@example.com",
    "motDePasse": "password123",
    "role": { "id": 2 },
    "isActive": true
  }'

# Vérifier la queue
SELECT * FROM sync_queue WHERE table_name = 'utilisateurs' ORDER BY id DESC LIMIT 1;
# Devrait montrer: operation = 'INSERT', data contient l'utilisateur
```

### 2. Test assignation boutiques

```bash
# Après avoir créé un utilisateur ID=X
curl -X PUT http://localhost:8080/api/v1/users/X/boutiques \
  -H "Content-Type: application/json" \
  -d '{ "boutiqueIds": [1, 2, 3] }'

# Vérifier la queue
SELECT * FROM sync_queue WHERE table_name = 'user_boutique_assignments' AND synced = 0;
# Devrait montrer 3 enregistrements (1 par boutique)
```

### 3. Vérification dans Neon

```sql
-- Attendre 30 secondes pour la sync, puis:

-- Utilisateur créé
SELECT * FROM utilisateurs WHERE nom_utilisateur = 'test_user';

-- Ses assignations
SELECT 
  uba.*,
  b.nom as boutique_nom
FROM user_boutique_assignments uba
JOIN boutiques b ON uba.boutique_id = b.id
WHERE uba.utilisateur_id = X;
```

### 4. Test modification

```bash
curl -X PUT http://localhost:8080/api/v1/users/X \
  -H "Content-Type: application/json" \
  -d '{
    "nomUtilisateur": "test_user_modified",
    "isActive": false
  }'

# Vérifier
SELECT * FROM sync_queue WHERE table_name = 'utilisateurs' AND synced = 0 ORDER BY id DESC LIMIT 1;
```

## Ordre de synchronisation

Avec notre configuration actuelle dans `sync-service.js` :

```
Priorité 1: user_roles
Priorité 2: utilisateurs          ← Créé/modifié en premier
Priorité 3: boutiques
Priorité 4: user_boutique_assignments  ← Créé après
```

Cet ordre garantit que :
1. Les utilisateurs existent avant leurs assignations
2. Les boutiques existent avant les assignations
3. Pas d'erreur de contrainte FK dans Neon

## Résumé des changements

**3 endpoints modifiés :**
1. `POST /users` - Ajout enqueue utilisateur
2. `PUT /users/:id` - Ajout enqueue utilisateur
3. `PUT /users/:id/boutiques` - Changement UPDATE → INSERT

**2 fichiers modifiés :**
1. `backend/src/routes/users.js`
2. `dist-exe/src/routes/users.js`

**Impact :**
- ✅ Synchronisation complète utilisateurs + assignations
- ✅ Cohérence totale local ↔ Neon
- ✅ Multi-appareils fonctionnel
- ✅ Gestion centralisée possible

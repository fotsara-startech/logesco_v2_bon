# Correction de la synchronisation user_boutique_assignments

## Problèmes identifiés avec la première implémentation

### 1. Logique INSERT vs UPDATE incorrecte (POST endpoint)

**Problème :**
```javascript
await syncService.enqueue('user_boutique_assignments', 
  assignment.id ? 'UPDATE' : 'INSERT',  // ❌ Toujours vrai !
  { ... }
);
```

**Explication :**
- `upsert()` de Prisma retourne **toujours** un objet avec un `id` (que ce soit une création ou une mise à jour)
- La condition `assignment.id ? 'UPDATE' : 'INSERT'` est donc **toujours vraie**
- Cela envoie toujours `'UPDATE'` au lieu de `'INSERT'` pour les nouvelles assignations
- Le service de sync ne pouvait pas créer de nouveaux enregistrements dans Neon

**Solution :**
Utiliser toujours `'INSERT'` pour les upserts. Le service de sync gère automatiquement les conflits (si l'enregistrement existe déjà, il fait un UPDATE en interne).

```javascript
await syncService.enqueue('user_boutique_assignments', 
  'INSERT',  // ✅ Toujours INSERT pour upsert
  { ... }
);
```

### 2. ID manquant dans le DELETE endpoint

**Problème :**
```javascript
await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
  utilisateurId,      // ✅
  boutiqueId,         // ✅
  isActive: false     // ✅
  // ❌ Pas d'ID !
});
```

**Explication :**
- L'enqueue ne contenait pas le champ `id` de l'assignment
- Le service de sync a besoin de l'`id` pour identifier quel enregistrement mettre à jour dans Neon
- Sans ID, la synchronisation échouait silencieusement

**Solution :**
Récupérer l'objet complet de l'assignment après l'update et inclure tous les champs :

```javascript
const updatedAssignment = await prisma.userBoutiqueAssignment.update({
  where: { utilisateurId_boutiqueId: { utilisateurId, boutiqueId } },
  data: { isActive: false }
});

await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
  id: updatedAssignment.id,                 // ✅ ID inclus
  utilisateurId: updatedAssignment.utilisateurId,
  boutiqueId: updatedAssignment.boutiqueId,
  roleId: updatedAssignment.roleId,
  isActive: updatedAssignment.isActive
});
```

## Corrections appliquées

### Fichiers modifiés
- `backend/src/routes/boutiques.js`
- `dist-exe/src/routes/boutiques.js`

### 1. Correction du POST /boutiques/:id/users

**Avant :**
```javascript
const assignment = await prisma.userBoutiqueAssignment.upsert({
  where: { utilisateurId_boutiqueId: { utilisateurId: parseInt(utilisateurId), boutiqueId } },
  update: { roleId: roleId ? parseInt(roleId) : null, isActive: true },
  create: { utilisateurId: parseInt(utilisateurId), boutiqueId, roleId: roleId ? parseInt(roleId) : null, isActive: true },
  include: { utilisateur: { ... }, role: true }
});

res.status(201).json(BaseResponseDTO.success(assignment, 'Utilisateur assigné à la boutique'));

if (syncService) {
  await syncService.enqueue('user_boutique_assignments', 
    assignment.id ? 'UPDATE' : 'INSERT',  // ❌ Toujours 'UPDATE'
    {
      id: assignment.id,
      utilisateurId: assignment.utilisateurId,
      boutiqueId: assignment.boutiqueId,
      roleId: assignment.roleId,
      isActive: assignment.isActive
    }
  );
}
```

**Après :**
```javascript
const assignment = await prisma.userBoutiqueAssignment.upsert({
  where: { utilisateurId_boutiqueId: { utilisateurId: parseInt(utilisateurId), boutiqueId } },
  update: { roleId: roleId ? parseInt(roleId) : null, isActive: true },
  create: { utilisateurId: parseInt(utilisateurId), boutiqueId, roleId: roleId ? parseInt(roleId) : null, isActive: true },
  include: { utilisateur: { ... }, role: true }
});

res.status(201).json(BaseResponseDTO.success(assignment, 'Utilisateur assigné à la boutique'));

// Enqueue pour sync vers Neon (toujours INSERT pour upsert, le service gère les doublons)
if (syncService) {
  await syncService.enqueue('user_boutique_assignments', 
    'INSERT',  // ✅ Toujours INSERT
    {
      id: assignment.id,
      utilisateurId: assignment.utilisateurId,
      boutiqueId: assignment.boutiqueId,
      roleId: assignment.roleId,
      isActive: assignment.isActive
    }
  );
}
```

### 2. Correction du DELETE /boutiques/:id/users/:userId

**Avant :**
```javascript
await prisma.userBoutiqueAssignment.update({
  where: { utilisateurId_boutiqueId: { utilisateurId, boutiqueId } },
  data: { isActive: false }
});

res.json(BaseResponseDTO.success(null, 'Utilisateur retiré de la boutique'));

if (syncService) {
  await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
    utilisateurId,     // ✅
    boutiqueId,        // ✅
    isActive: false    // ✅
    // ❌ Pas d'ID !
  });
}
```

**Après :**
```javascript
const updatedAssignment = await prisma.userBoutiqueAssignment.update({
  where: { utilisateurId_boutiqueId: { utilisateurId, boutiqueId } },
  data: { isActive: false }
});

res.json(BaseResponseDTO.success(null, 'Utilisateur retiré de la boutique'));

// Enqueue pour sync vers Neon avec l'ID complet
if (syncService) {
  await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
    id: updatedAssignment.id,                 // ✅ ID inclus
    utilisateurId: updatedAssignment.utilisateurId,
    boutiqueId: updatedAssignment.boutiqueId,
    roleId: updatedAssignment.roleId,
    isActive: updatedAssignment.isActive
  });
}
```

## Pourquoi ces bugs étaient insidieux

### 1. Pas d'erreur visible
- Les opérations locales réussissaient (SQLite)
- L'enqueue vers sync_queue réussissait aussi
- Mais la synchronisation vers Neon échouait silencieusement
- L'utilisateur ne voyait aucune erreur

### 2. Comportement incohérent
- **POST** : Envoyait toujours `'UPDATE'` → Les nouvelles assignations n'étaient jamais créées dans Neon
- **DELETE** : Envoyait un UPDATE sans ID → Impossible d'identifier l'enregistrement à modifier dans Neon
- **PUT** (users/:id/boutiques) : Fonctionnait correctement car il récupérait tous les assignments avec leurs IDs

### 3. Tests locaux trompeurs
- En local, tout fonctionnait (SQLite)
- Les problèmes n'apparaissaient qu'après synchronisation vers Neon
- Difficile à détecter sans vérifier directement dans Neon

## Comment le service de sync gère les opérations

### INSERT avec upsert
Le service de sync est intelligent :
```javascript
// Quand on envoie 'INSERT' avec un ID existant :
await syncService.enqueue('user_boutique_assignments', 'INSERT', {
  id: 5,  // Existe déjà dans Neon
  // ... autres champs
});

// Le service de sync fait automatiquement :
// 1. Tente INSERT dans Neon
// 2. Si conflit (ID existe) → Fait UPDATE à la place
// 3. Aucune erreur, opération réussie
```

C'est pourquoi on utilise toujours `'INSERT'` pour les upserts côté application.

### UPDATE nécessite un ID
```javascript
// Pour UPDATE, l'ID est obligatoire :
await syncService.enqueue('user_boutique_assignments', 'UPDATE', {
  id: 5,  // ✅ OBLIGATOIRE
  isActive: false
});

// Sans ID, le service ne sait pas quel enregistrement modifier
// L'opération échoue silencieusement
```

## Tests de validation

### 1. Test d'assignation (POST)
```bash
# Assigner un utilisateur
curl -X POST http://localhost:8080/api/v1/boutiques/1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "utilisateurId": 2,
    "roleId": 3
  }'

# Vérifier la queue de sync
SELECT * FROM sync_queue 
WHERE table_name = 'user_boutique_assignments' 
ORDER BY id DESC LIMIT 1;

# Devrait montrer :
# - operation = 'INSERT' (pas 'UPDATE')
# - data contient l'ID
```

### 2. Test de retrait (DELETE)
```bash
# Retirer un utilisateur
curl -X DELETE http://localhost:8080/api/v1/boutiques/1/users/2 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Vérifier la queue
SELECT data FROM sync_queue 
WHERE table_name = 'user_boutique_assignments' 
ORDER BY id DESC LIMIT 1;

# Le JSON data devrait contenir :
# {"id": X, "utilisateurId": 2, "boutiqueId": 1, "isActive": false, ...}
```

### 3. Vérification dans Neon après sync
```sql
-- Attendre 30 secondes pour la sync
-- Puis vérifier dans Neon

SELECT * FROM user_boutique_assignments
WHERE utilisateur_id = 2 AND boutique_id = 1;

-- Devrait exister avec isActive = false si on a fait DELETE
```

### 4. Test de réassignation
```bash
# Assigner à nouveau le même utilisateur (devrait réactiver)
curl -X POST http://localhost:8080/api/v1/boutiques/1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "utilisateurId": 2,
    "roleId": 3
  }'

# Vérifier dans Neon après sync
SELECT is_active FROM user_boutique_assignments
WHERE utilisateur_id = 2 AND boutique_id = 1;

# Devrait être TRUE (réactivé)
```

## Impact des corrections

### Avant
- ❌ Nouvelles assignations non créées dans Neon
- ❌ Retraits d'utilisateurs non synchronisés
- ❌ Incohérence totale entre local et Neon
- ❌ Gestion multi-boutique cassée en cloud

### Après
- ✅ Toutes les assignations créées correctement
- ✅ Retraits synchronisés avec tous les champs
- ✅ Cohérence parfaite entre local et Neon
- ✅ Gestion multi-boutique fonctionnelle

## Leçons apprises

1. **Ne jamais supposer qu'un ID présent signifie UPDATE**
   - `upsert()` retourne toujours un ID
   - Utiliser `'INSERT'` et laisser le service gérer

2. **Toujours récupérer l'objet complet avant enqueue**
   - Ne pas envoyer seulement les champs modifiés
   - Inclure l'ID et tous les champs de relation

3. **Tester la synchronisation end-to-end**
   - Local → sync_queue → Neon
   - Vérifier les données dans Neon, pas seulement en local

4. **Logger les enqueues pour debugging**
   ```javascript
   if (syncService) {
     console.log('Enqueuing assignment:', {
       operation: 'INSERT',
       data: { id, utilisateurId, boutiqueId, ... }
     });
     await syncService.enqueue(...);
   }
   ```

## Résumé des fichiers modifiés

1. `backend/src/routes/boutiques.js` - Corrections POST et DELETE
2. `dist-exe/src/routes/boutiques.js` - Corrections POST et DELETE

**2 fichiers modifiés** avec corrections critiques sur les enqueues.

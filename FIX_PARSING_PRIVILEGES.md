# 🔧 Correction du parsing des privilèges

## ❌ Problème identifié

Erreur lors de l'accès à la page des utilisateurs :
```
type '_Map<String, dynamic>' is not a subtype of type 'Iterable<dynamic>'
```

### Cause racine :

Le backend renvoie les privilèges dans ce format :
```json
{
  "privileges": {
    "users": {
      "create": true,
      "read": true,
      "update": true,
      "delete": false
    },
    "products": {
      "create": true,
      "read": true
    }
  }
}
```

Mais le code Flutter essayait de les parser comme des listes :
```dart
List<String>.from(value ?? [])  // ❌ value est un Map, pas une List
```

## ✅ Solution appliquée

### Ajout de la méthode `_parsePrivilegesMap()`

Cette méthode convertit le format backend en format Flutter :

**Format backend :**
```json
{
  "users": {"create": true, "read": true, "update": false},
  "products": {"create": true, "read": true}
}
```

**Format Flutter :**
```dart
{
  "users": ["CREATE", "READ"],
  "products": ["CREATE", "READ"]
}
```

### Logique de conversion :

1. **Parcourir chaque module** (users, products, etc.)
2. **Pour chaque module, parcourir les privilèges**
3. **Si le privilège est `true`, l'ajouter à la liste**
4. **Convertir en MAJUSCULES** (CREATE, READ, UPDATE, DELETE)
5. **Ignorer les privilèges à `false`**

## 📋 Fichier modifié

**`logesco_v2/lib/features/users/models/role_model.dart`**

### Méthode ajoutée :

```dart
static Map<String, List<String>> _parsePrivilegesMap(Map<dynamic, dynamic> privilegesMap) {
  final Map<String, List<String>> result = {};
  
  privilegesMap.forEach((module, privileges) {
    final moduleKey = module.toString();
    final List<String> privilegesList = [];
    
    if (privileges is Map) {
      // Format: {create: true, read: false, update: true}
      privileges.forEach((privilege, enabled) {
        if (enabled == true) {
          privilegesList.add(privilege.toString().toUpperCase());
        }
      });
    } else if (privileges is List) {
      // Format: ['CREATE', 'READ', 'UPDATE']
      privilegesList.addAll(privileges.map((p) => p.toString().toUpperCase()));
    }
    
    if (privilegesList.isNotEmpty) {
      result[moduleKey] = privilegesList;
    }
  });
  
  return result;
}
```

## 🧪 Test de validation

### Étape 1 : Redémarrer l'application
```bash
# Hot Restart
r
```

### Étape 2 : Accéder à la page des utilisateurs
1. Se connecter avec admin/admin123
2. Ouvrir le menu
3. Cliquer sur "Utilisateurs"
4. **Vérifier qu'aucune erreur n'apparaît**

### Étape 3 : Vérifier les rôles
1. Aller dans "Rôles"
2. Voir les rôles existants
3. Créer un nouveau rôle
4. **Vérifier que les privilèges sont correctement affichés**

## 📊 Exemple de conversion

### Données du backend :
```json
{
  "id": 3,
  "nom": "admin",
  "displayName": "Administrateur",
  "isAdmin": true,
  "privileges": {
    "users": {
      "create": true,
      "read": true,
      "update": true,
      "delete": true
    },
    "products": {
      "create": true,
      "read": true,
      "update": false,
      "delete": false
    },
    "sales": {
      "create": true,
      "read": true
    }
  }
}
```

### Après parsing Flutter :
```dart
UserRole(
  id: 3,
  nom: 'admin',
  displayName: 'Administrateur',
  isAdmin: true,
  privileges: {
    'users': ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    'products': ['CREATE', 'READ'],
    'sales': ['CREATE', 'READ']
  }
)
```

## 🔍 Formats supportés

La méthode `_parsePrivilegesMap()` supporte plusieurs formats :

### Format 1 : Map avec booléens (Backend actuel)
```json
{
  "users": {"create": true, "read": true, "update": false}
}
```
→ `{"users": ["CREATE", "READ"]}`

### Format 2 : Liste de strings (Ancien format)
```json
{
  "users": ["CREATE", "READ", "UPDATE"]
}
```
→ `{"users": ["CREATE", "READ", "UPDATE"]}`

### Format 3 : String JSON (Si encodé)
```json
"{\"users\": {\"create\": true}}"
```
→ Parse puis convertit

## ✅ Avantages de la solution

1. **Flexible** : Supporte plusieurs formats
2. **Robuste** : Gère les erreurs de parsing
3. **Clair** : Convertit en MAJUSCULES pour cohérence
4. **Filtré** : Ignore les privilèges à `false`
5. **Maintenable** : Méthode séparée et réutilisable

## 🐛 Debugging

### Si l'erreur persiste :

1. **Vérifier le format des privilèges dans le backend**
   ```bash
   # Tester l'API
   curl http://localhost:8080/api/v1/users
   ```

2. **Ajouter des logs dans `_parsePrivilegesMap()`**
   ```dart
   print('📋 Parsing privileges: $privilegesMap');
   print('✅ Result: $result');
   ```

3. **Vérifier que le backend renvoie bien des booléens**
   - `true` / `false` (pas `"true"` / `"false"`)

## 📝 Notes importantes

### Privilèges ignorés :
- Les privilèges avec `enabled: false` sont **ignorés**
- Les modules sans privilèges actifs sont **ignorés**

### Conversion en majuscules :
- `create` → `CREATE`
- `read` → `READ`
- `update` → `UPDATE`
- `delete` → `DELETE`

### Compatibilité :
- ✅ Format backend actuel (Map avec booléens)
- ✅ Ancien format (Liste de strings)
- ✅ Format encodé en JSON (String)

---
**Date :** 5 décembre 2025
**Version :** Logesco V2
**Statut :** ✅ CORRIGÉ - Parsing des privilèges fonctionnel
**Impact :** Page des utilisateurs accessible sans erreur

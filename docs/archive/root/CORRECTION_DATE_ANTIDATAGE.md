# Correction Bug: Date incorrecte lors de l'antidatage de ventes

## Problème
Quand une vente est antidatée (par exemple le 2 juillet 2026), le reçu affichait la date du 1er juillet 2026 à 23:00.

### Cause
Le problème était causé par un décalage de fuseau horaire (timezone) lors de la sérialisation/désérialisation JSON:

1. **Sélection de date**: L'utilisateur sélectionne le 2 juillet 2026
2. **Création locale**: Flutter crée un objet `DateTime(2026, 7, 2, 0, 0, 0)` en heure locale
3. **Sérialisation UTC**: La méthode `.toIso8601String()` convertit en UTC: `2026-07-02T00:00:00.000Z`
4. **Décalage horaire**: Si le fuseau horaire local est UTC+1, la date UTC devient `2026-07-01T23:00:00.000Z`
5. **Désérialisation**: Avec `.toLocal()`, on récupère `2026-07-01 23:00` (heure locale)

## Solution
Créer des méthodes de sérialisation personnalisées qui préservent l'heure locale sans conversion UTC.

### Fichiers modifiés

#### 1. `logesco_v2/lib/features/sales/models/sale.dart`

**Ajout de méthodes de sérialisation personnalisées:**
```dart
@JsonSerializable()
class Sale {
  // ...
  @JsonKey(name: 'dateVente', toJson: _dateToJsonLocal, fromJson: _dateFromJsonLocal)
  final DateTime dateCreation;
  
  // Méthodes statiques pour sérialisation locale
  static String _dateToJsonLocal(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}.${date.millisecond.toString().padLeft(3, '0')}';
  }

  static DateTime _dateFromJsonLocal(String json) {
    return DateTime.parse(json);
  }
}

@JsonSerializable()
class CreateSaleRequest {
  // ...
  @JsonKey(toJson: _dateToJsonLocal, fromJson: _dateFromJsonLocal)
  final DateTime? dateVente;
  
  // Mêmes méthodes de sérialisation
  static String? _dateToJsonLocal(DateTime? date) {
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}.${date.millisecond.toString().padLeft(3, '0')}';
  }

  static DateTime? _dateFromJsonLocal(String? json) {
    if (json == null) return null;
    return DateTime.parse(json);
  }
}
```

#### 2. `logesco_v2/lib/features/printing/models/receipt_model.dart`

**Même correction pour le modèle Receipt:**
```dart
@JsonSerializable()
class Receipt {
  // ...
  @JsonKey(toJson: _dateToJsonLocal, fromJson: _dateFromJsonLocal)
  final DateTime saleDate;
  
  // Méthodes de sérialisation identiques
  static String _dateToJsonLocal(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}.${date.millisecond.toString().padLeft(3, '0')}';
  }

  static DateTime _dateFromJsonLocal(String json) {
    return DateTime.parse(json);
  }
}
```

#### 3. Régénération des fichiers
```bash
cd logesco_v2
flutter pub run build_runner build --delete-conflicting-outputs
```

### Tests
Un nouveau fichier de test vérifie que la date est correctement préservée:
- `logesco_v2/test/features/sales/date_serialization_test.dart`

Les tests confirment que:
- La date sélectionnée (2 juillet à 00:00) est conservée après sérialisation/désérialisation
- Aucun "Z" n'est ajouté (pas de conversion UTC)
- Les heures personnalisées sont également préservées

## Résultat
✅ Quand l'utilisateur sélectionne le 2 juillet 2026, le reçu affiche maintenant correctement "02/07/2026" au lieu de "01/07/2026 à 23:00".

## Impact
- Correction applicable à toutes les ventes antidatées
- Pas d'impact sur les ventes existantes (les nouvelles utilisent le format local)
- Compatible avec le backend existant

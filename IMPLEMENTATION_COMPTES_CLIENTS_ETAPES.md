# Implémentation - Amélioration Comptes Clients

## ✅ Étape 1: Migration Base de Données
**Fichier créé**: `backend/migrations/add-vente-reference-to-transactions.sql`

Colonnes ajoutées à `TransactionCompte`:
- `venteId` (INTEGER NULL)
- `venteReference` (VARCHAR(50) NULL)
- `typeTransactionDetail` (VARCHAR(50) NULL)

## 📝 Étape 2: Backend - Nouvelles Routes

### Route 1: GET /accounts/customers/:id/unpaid-sales
**À ajouter dans**: `backend/src/routes/accounts.js`

```javascript
/**
 * GET /accounts/customers/:id/unpaid-sales
 * Récupère les ventes impayées d'un client
 */
router.get('/customers/:id/unpaid-sales',
  validateId,
  async (req, res) => {
    try {
      const clientId = parseInt(req.params.id);

      // Récupérer les ventes du client avec montantRestant > 0
      const ventesImpayees = await models.prisma.vente.findMany({
        where: {
          clientId,
          montantRestant: { gt: 0 },
          statut: { not: 'annulee' }
        },
        select: {
          id: true,
          reference: true,
          dateVente: true,
          montantTotal: true,
          montantPaye: true,
          montantRestant: true,
          details: {
            select: {
              produitId: true,
              quantite: true,
              prixUnitaire: true,
              montantTotal: true
            }
          }
        },
        orderBy: { dateVente: 'desc' }
      });

      const ventesFormatted = ventesImpayees.map(v => ({
        id: v.id,
        reference: v.reference,
        dateVente: v.dateVente,
        montantTotal: parseFloat(v.montantTotal),
        montantPaye: parseFloat(v.montantPaye),
        montantRestant: parseFloat(v.montantRestant),
        nombreArticles: v.details.length
      }));

      res.json(BaseResponseDTO.success(
        ventesFormatted,
        'Ventes impayées récupérées avec succès'
      ));

    } catch (error) {
      console.error('Erreur récupération ventes impayées:', error);
      res.status(500).json(
        BaseResponseDTO.error('Erreur lors de la récupération des ventes impayées')
      );
    }
  }
);
```

### Route 2: Modifier POST /accounts/customers/:id/transactions
**Modifications à apporter**:

1. Accepter `venteId` et `typeTransactionDetail` dans le body
2. Récupérer la référence de la vente si `venteId` fourni
3. Mettre à jour `montantPaye` de la vente
4. Enregistrer `venteId`, `venteReference` et `typeTransactionDetail` dans la transaction

```javascript
// Dans POST /accounts/customers/:id/transactions
const { montant, typeTransaction, description, venteId, typeTransactionDetail } = req.body;

let venteReference = null;

// Si une vente est spécifiée, récupérer sa référence et mettre à jour le paiement
if (venteId) {
  const vente = await models.prisma.vente.findUnique({
    where: { id: venteId },
    select: { id: true, reference: true, montantPaye: true, montantTotal: true, clientId: true }
  });

  if (!vente) {
    return res.status(404).json(BaseResponseDTO.error('Vente non trouvée'));
  }

  if (vente.clientId !== clientId) {
    return res.status(400).json(BaseResponseDTO.error('Cette vente n\'appartient pas à ce client'));
  }

  venteReference = vente.reference;

  // Mettre à jour le montant payé de la vente
  if (typeTransaction === 'paiement' || typeTransaction === 'credit') {
    const nouveauMontantPaye = parseFloat(vente.montantPaye) + parseFloat(montant);
    const montantRestant = parseFloat(vente.montantTotal) - nouveauMontantPaye;

    await models.prisma.vente.update({
      where: { id: venteId },
      data: {
        montantPaye: nouveauMontantPaye,
        montantRestant: montantRestant > 0 ? montantRestant : 0
      }
    });
  }
}

// Créer l'enregistrement de transaction avec les nouveaux champs
const transaction = await prisma.transactionCompte.create({
  data: {
    typeCompte: 'client',
    compteId: compteUpdated.id,
    typeTransaction,
    typeTransactionDetail: typeTransactionDetail || typeTransaction,
    montant: parseFloat(montant),
    description: description || `Transaction ${typeTransaction}`,
    soldeApres: nouveauSolde,
    venteId: venteId || null,
    venteReference: venteReference
  }
});
```

## 📝 Étape 3: Frontend - Modèles

### Modifier `account.dart`

```dart
class TransactionCompte {
  // Champs existants...
  
  // NOUVEAUX CHAMPS
  final int? venteId;
  final String? venteReference;
  final String? typeTransactionDetail;

  TransactionCompte({
    // ... paramètres existants
    this.venteId,
    this.venteReference,
    this.typeTransactionDetail,
  });

  factory TransactionCompte.fromJson(Map<String, dynamic> json) {
    return TransactionCompte(
      // ... parsing existant
      venteId: json['venteId'] != null ? parseInt(json['venteId']) : null,
      venteReference: json['venteReference']?.toString(),
      typeTransactionDetail: json['typeTransactionDetail']?.toString(),
    );
  }

  /// Retourne le libellé formaté de la transaction
  String get libelleFormate {
    if (venteReference != null) {
      if (typeTransactionDetail == 'paiement_vente') {
        return 'Paiement Facture #$venteReference';
      } else if (typeTransactionDetail == 'paiement_dette') {
        return 'Paiement Dette (Vente #$venteReference)';
      } else if (typeTransactionDetail == 'vente_credit') {
        return 'Vente à Crédit #$venteReference';
      }
    }
    return typeTransactionLibelle;
  }

  /// Vérifie si la transaction est liée à une vente
  bool get isLinkedToSale => venteId != null;
}
```

### Créer modèle `UnpaidSale`

```dart
class UnpaidSale {
  final int id;
  final String reference;
  final DateTime dateVente;
  final double montantTotal;
  final double montantPaye;
  final double montantRestant;
  final int nombreArticles;

  UnpaidSale({
    required this.id,
    required this.reference,
    required this.dateVente,
    required this.montantTotal,
    required this.montantPaye,
    required this.montantRestant,
    required this.nombreArticles,
  });

  factory UnpaidSale.fromJson(Map<String, dynamic> json) {
    return UnpaidSale(
      id: json['id'] as int,
      reference: json['reference'] as String,
      dateVente: DateTime.parse(json['dateVente'] as String),
      montantTotal: (json['montantTotal'] as num).toDouble(),
      montantPaye: (json['montantPaye'] as num).toDouble(),
      montantRestant: (json['montantRestant'] as num).toDouble(),
      nombreArticles: json['nombreArticles'] as int,
    );
  }

  String get dateVenteFormatted => DateFormat('dd/MM/yyyy').format(dateVente);
  String get montantTotalFormatted => '${montantTotal.toStringAsFixed(0)} FCFA';
  String get montantPayeFormatted => '${montantPaye.toStringAsFixed(0)} FCFA';
  String get montantRestantFormatted => '${montantRestant.toStringAsFixed(0)} FCFA';
}
```

## 📝 Étape 4: Frontend - Services

### Ajouter dans `account_api_service.dart`

```dart
/// Récupère les ventes impayées d'un client
Future<List<UnpaidSale>> getUnpaidSales(int clientId) async {
  try {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Token non disponible');

    final response = await http.get(
      Uri.parse('$_baseUrl/accounts/customers/$clientId/unpaid-sales'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final ventesData = data['data'] as List;
      return ventesData.map((v) => UnpaidSale.fromJson(v)).toList();
    } else {
      throw Exception('Erreur ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur getUnpaidSales: $e');
    rethrow;
  }
}

/// Crée une transaction avec lien vers une vente
Future<void> createTransactionWithSale({
  required int clientId,
  required double montant,
  required String typeTransaction,
  required String typeTransactionDetail,
  int? venteId,
  String? description,
}) async {
  try {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Token non disponible');

    final body = {
      'montant': montant,
      'typeTransaction': typeTransaction,
      'typeTransactionDetail': typeTransactionDetail,
      if (venteId != null) 'venteId': venteId,
      if (description != null) 'description': description,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/accounts/customers/$clientId/transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur createTransactionWithSale: $e');
    rethrow;
  }
}
```

## 📝 Étape 5: Frontend - UI

### Modifier `transaction_list_item.dart`

```dart
Widget build(BuildContext context) {
  return Card(
    child: ListTile(
      leading: _buildTransactionIcon(),
      title: Text(transaction.libelleFormate), // Utilise le nouveau getter
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.description != null)
            Text(transaction.description!),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(transaction.dateTransaction),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${transaction.montant.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction.augmenteSolde ? Colors.red : Colors.green,
            ),
          ),
          Text(
            'Solde: ${transaction.soldeApres.toStringAsFixed(0)} F',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTransactionIcon() {
  IconData icon;
  Color color;

  if (transaction.isLinkedToSale) {
    if (transaction.typeTransactionDetail == 'paiement_vente') {
      icon = Icons.receipt;
      color = Colors.blue;
    } else if (transaction.typeTransactionDetail == 'paiement_dette') {
      icon = Icons.payment;
      color = Colors.green;
    } else {
      icon = Icons.shopping_cart;
      color = Colors.orange;
    }
  } else {
    // Icônes par défaut pour les anciennes transactions
    icon = transaction.augmenteSolde ? Icons.add_circle : Icons.remove_circle;
    color = transaction.augmenteSolde ? Colors.red : Colors.green;
  }

  return CircleAvatar(
    backgroundColor: color.withOpacity(0.1),
    child: Icon(icon, color: color),
  );
}
```

### Créer `unpaid_sales_selector_dialog.dart`

```dart
class UnpaidSalesSelectorDialog extends StatefulWidget {
  final int clientId;
  final Function(UnpaidSale, double) onSaleSelected;

  const UnpaidSalesSelectorDialog({
    super.key,
    required this.clientId,
    required this.onSaleSelected,
  });

  @override
  State<UnpaidSalesSelectorDialog> createState() => _UnpaidSalesSelectorDialogState();
}

class _UnpaidSalesSelectorDialogState extends State<UnpaidSalesSelectorDialog> {
  List<UnpaidSale> _unpaidSales = [];
  UnpaidSale? _selectedSale;
  final _montantController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnpaidSales();
  }

  Future<void> _loadUnpaidSales() async {
    try {
      final service = Get.find<AccountApiService>();
      final sales = await service.getUnpaidSales(widget.clientId);
      setState(() {
        _unpaidSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Erreur', 'Impossible de charger les ventes impayées');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une vente à payer'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unpaidSales.isEmpty
              ? const Text('Aucune vente impayée')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._unpaidSales.map((sale) => _buildSaleCard(sale)),
                      if (_selectedSale != null) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _montantController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Montant à payer',
                            suffixText: 'FCFA',
                            helperText: 'Max: ${_selectedSale!.montantRestantFormatted}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (_selectedSale != null)
          ElevatedButton(
            onPressed: _validateAndPay,
            child: const Text('Payer'),
          ),
      ],
    );
  }

  Widget _buildSaleCard(UnpaidSale sale) {
    final isSelected = _selectedSale?.id == sale.id;
    
    return Card(
      color: isSelected ? Colors.blue[50] : null,
      child: RadioListTile<int>(
        value: sale.id,
        groupValue: _selectedSale?.id,
        onChanged: (value) {
          setState(() {
            _selectedSale = sale;
            _montantController.text = sale.montantRestant.toStringAsFixed(0);
          });
        },
        title: Text('Vente #${sale.reference}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${sale.dateVenteFormatted}'),
            Text('Total: ${sale.montantTotalFormatted}'),
            Text('Déjà payé: ${sale.montantPayeFormatted}'),
            Text(
              'Reste: ${sale.montantRestantFormatted}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndPay() {
    final montant = double.tryParse(_montantController.text);
    if (montant == null || montant <= 0) {
      Get.snackbar('Erreur', 'Montant invalide');
      return;
    }
    if (montant > _selectedSale!.montantRestant) {
      Get.snackbar('Erreur', 'Le montant dépasse le reste à payer');
      return;
    }
    widget.onSaleSelected(_selectedSale!, montant);
    Navigator.pop(context);
  }
}
```

## 📝 Étape 6: Intégration dans transaction_form_dialog.dart

Ajouter un bouton "Payer une vente spécifique" qui ouvre le sélecteur.

## ✅ Résumé des Fichiers à Modifier/Créer

### Backend:
1. ✅ `backend/migrations/add-vente-reference-to-transactions.sql` (créé)
2. ⏳ `backend/src/routes/accounts.js` (à modifier)

### Frontend:
1. ⏳ `logesco_v2/lib/features/accounts/models/account.dart` (à modifier)
2. ⏳ `logesco_v2/lib/features/accounts/services/account_api_service.dart` (à modifier)
3. ⏳ `logesco_v2/lib/features/accounts/widgets/transaction_list_item.dart` (à modifier)
4. ⏳ `logesco_v2/lib/features/accounts/widgets/unpaid_sales_selector_dialog.dart` (à créer)
5. ⏳ `logesco_v2/lib/features/accounts/widgets/transaction_form_dialog.dart` (à modifier)

Voulez-vous que je continue avec l'implémentation des modifications backend et frontend ?

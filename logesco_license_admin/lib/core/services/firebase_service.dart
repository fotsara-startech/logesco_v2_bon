import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client.dart';
import '../../models/license.dart';
import '../../models/payment.dart';
import '../../models/expense.dart';
import '../../models/financial_summary.dart';

/// Service Firebase remplaçant SQLite pour un accès multi-plateforme (Windows + mobile)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _clients => _db.collection('clients');
  CollectionReference<Map<String, dynamic>> get _licenses => _db.collection('licenses');
  CollectionReference<Map<String, dynamic>> get _payments => _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get _expenses => _db.collection('expenses');

  // ─── CLIENTS ────────────────────────────────────────────────────────────────

  Future<String> insertClient(Client client) async {
    await _clients.doc(client.id).set(_clientToMap(client));
    return client.id;
  }

  Future<List<Client>> getClients({
    String? searchQuery,
    bool? isActive,
    int? limit,
  }) async {
    // Requête simple sans index composite
    final snapshot = await _clients.get();
    List<Client> clients = snapshot.docs.map((d) => _clientFromMap(d.data())).toList();

    // Filtrage côté client
    if (isActive != null) {
      clients = clients.where((c) => c.isActive == isActive).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      clients = clients.where((c) {
        return c.name.toLowerCase().contains(q) || (c.email?.toLowerCase().contains(q) ?? false) || c.company.toLowerCase().contains(q);
      }).toList();
    }

    // Tri côté client
    clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null && clients.length > limit) {
      clients = clients.sublist(0, limit);
    }

    return clients;
  }

  Future<Client?> getClient(String id) async {
    final doc = await _clients.doc(id).get();
    if (!doc.exists) return null;
    return _clientFromMap(doc.data()!);
  }

  Future<void> updateClient(Client client) async {
    await _clients.doc(client.id).update(_clientToMap(client));
  }

  Future<void> deleteClient(String id) async {
    // Supprimer les licences et paiements associés
    final licenses = await _licenses.where('clientId', isEqualTo: id).get();
    final payments = await _payments.where('clientId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in licenses.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in payments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_clients.doc(id));
    await batch.commit();
  }

  // ─── LICENCES ───────────────────────────────────────────────────────────────

  Future<String> insertLicense(License license) async {
    await _licenses.doc(license.id).set(_licenseToMap(license));
    return license.id;
  }

  Future<List<License>> getLicenses({
    String? clientId,
    LicenseStatus? status,
    SubscriptionType? type,
    bool? isExpired,
    int? limit,
  }) async {
    // Requête simple sans index composite
    final snapshot = await _licenses.get();
    List<License> licenses = snapshot.docs.map((d) => _licenseFromMap(d.data())).toList();

    // Filtrage côté client
    if (clientId != null) {
      licenses = licenses.where((l) => l.clientId == clientId).toList();
    }
    if (status != null) {
      licenses = licenses.where((l) => l.status == status).toList();
    }
    if (type != null) {
      licenses = licenses.where((l) => l.type == type).toList();
    }
    if (isExpired != null) {
      final now = DateTime.now();
      licenses = licenses.where((l) {
        return isExpired ? l.expiresAt.isBefore(now) : l.expiresAt.isAfter(now);
      }).toList();
    }

    // Tri côté client
    licenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null && licenses.length > limit) {
      licenses = licenses.sublist(0, limit);
    }

    return licenses;
  }

  Future<License?> getLicense(String id) async {
    final doc = await _licenses.doc(id).get();
    if (!doc.exists) return null;
    return _licenseFromMap(doc.data()!);
  }

  Future<void> updateLicense(License license) async {
    await _licenses.doc(license.id).update(_licenseToMap(license));
  }

  Future<void> deleteLicense(String id) async {
    await _licenses.doc(id).delete();
  }

  // ─── PAIEMENTS DE SERVICES ──────────────────────────────────────────────────

  Future<String> insertPayment(Payment payment) async {
    await _payments.doc(payment.id).set(_paymentToMap(payment));
    return payment.id;
  }

  Future<List<Payment>> getPayments({
    String? clientId,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    // Requête simple sans index composite
    final snapshot = await _payments.get();
    List<Payment> payments = snapshot.docs.map((d) => _paymentFromMap(d.data())).toList();

    // Filtrage côté client
    if (clientId != null) {
      payments = payments.where((p) => p.clientId == clientId).toList();
    }
    if (from != null) {
      payments = payments.where((p) => !p.paymentDate.isBefore(from)).toList();
    }
    if (to != null) {
      payments = payments.where((p) => !p.paymentDate.isAfter(to)).toList();
    }

    // Tri côté client
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    if (limit != null && payments.length > limit) {
      payments = payments.sublist(0, limit);
    }

    return payments;
  }

  Future<Payment?> getPayment(String id) async {
    final doc = await _payments.doc(id).get();
    if (!doc.exists) return null;
    return _paymentFromMap(doc.data()!);
  }

  Future<void> updatePayment(Payment payment) async {
    await _payments.doc(payment.id).update(_paymentToMap(payment));
  }

  Future<void> deletePayment(String id) async {
    await _payments.doc(id).delete();
  }

  // ─── DÉPENSES ────────────────────────────────────────────────────────────────

  Future<String> insertExpense(Expense expense) async {
    await _expenses.doc(expense.id).set(_expenseToMap(expense));
    return expense.id;
  }

  Future<List<Expense>> getExpenses({
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    // Requête simple sans index composite
    final snapshot = await _expenses.get();
    List<Expense> expenses = snapshot.docs.map((d) => _expenseFromMap(d.data())).toList();

    // Filtrage côté client
    if (category != null) {
      expenses = expenses.where((e) => e.category == category).toList();
    }
    if (from != null) {
      expenses = expenses.where((e) => !e.expenseDate.isBefore(from)).toList();
    }
    if (to != null) {
      expenses = expenses.where((e) => !e.expenseDate.isAfter(to)).toList();
    }

    // Tri côté client
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    if (limit != null && expenses.length > limit) {
      expenses = expenses.sublist(0, limit);
    }

    return expenses;
  }

  Future<Expense?> getExpense(String id) async {
    final doc = await _expenses.doc(id).get();
    if (!doc.exists) return null;
    return _expenseFromMap(doc.data()!);
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenses.doc(expense.id).update(_expenseToMap(expense));
  }

  Future<void> deleteExpense(String id) async {
    await _expenses.doc(id).delete();
  }

  // ─── ÉTAT DE L'ACTIVITÉ ─────────────────────────────────────────────────────

  /// Calcule l'état de l'activité (revenus, dépenses, résultat net) sur une
  /// période donnée, avec ventilation par client et par catégorie de dépense.
  Future<FinancialSummary> getFinancialSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final clientsSnap = await _clients.get();
    final licensesSnap = await _licenses.get();
    final paymentsSnap = await _payments.get();
    final expensesSnap = await _expenses.get();

    final clients = clientsSnap.docs.map((d) => _clientFromMap(d.data())).toList();
    final clientsById = {for (final c in clients) c.id: c};

    final licenses = licensesSnap.docs
        .map((d) => _licenseFromMap(d.data()))
        .where((l) => !l.issuedAt.isBefore(from) && !l.issuedAt.isAfter(to))
        .toList();
    final payments = paymentsSnap.docs
        .map((d) => _paymentFromMap(d.data()))
        .where((p) => !p.paymentDate.isBefore(from) && !p.paymentDate.isAfter(to))
        .toList();
    final expenses = expensesSnap.docs
        .map((d) => _expenseFromMap(d.data()))
        .where((e) => !e.expenseDate.isBefore(from) && !e.expenseDate.isAfter(to))
        .toList();

    // Ventilation des revenus par client
    final Map<String, double> licenseRevenueByClient = {};
    for (final l in licenses) {
      licenseRevenueByClient[l.clientId] = (licenseRevenueByClient[l.clientId] ?? 0) + (l.price ?? 0);
    }
    final Map<String, double> serviceRevenueByClient = {};
    for (final p in payments) {
      serviceRevenueByClient[p.clientId] = (serviceRevenueByClient[p.clientId] ?? 0) + p.amount;
    }
    final clientIds = {...licenseRevenueByClient.keys, ...serviceRevenueByClient.keys};
    final revenueByClient = clientIds
        .map((id) => ClientRevenue(
              clientId: id,
              clientName: clientsById[id]?.name ?? 'Client inconnu',
              licenseRevenue: licenseRevenueByClient[id] ?? 0,
              serviceRevenue: serviceRevenueByClient[id] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // Ventilation des dépenses par catégorie
    final Map<String, double> expensesByCategory = {};
    for (final e in expenses) {
      expensesByCategory[e.categoryLabel] = (expensesByCategory[e.categoryLabel] ?? 0) + e.amount;
    }

    return FinancialSummary(
      from: from,
      to: to,
      licenseRevenue: licenses.fold(0.0, (s, l) => s + (l.price ?? 0)),
      serviceRevenue: payments.fold(0.0, (s, p) => s + p.amount),
      totalExpenses: expenses.fold(0.0, (s, e) => s + e.amount),
      expensesByCategory: expensesByCategory,
      revenueByClient: revenueByClient,
    );
  }

  // ─── STATISTIQUES ───────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatistics() async {
    final now = DateTime.now();

    final clientsSnap = await _clients.get();
    final licensesSnap = await _licenses.get();

    final clients = clientsSnap.docs.map((d) => _clientFromMap(d.data())).toList();
    final licenses = licensesSnap.docs.map((d) => _licenseFromMap(d.data())).toList();

    final totalClients = clients.where((c) => c.isActive).length;
    final totalLicenses = licenses.length;
    final activeLicenses = licenses.where((l) => l.status == LicenseStatus.active && l.expiresAt.isAfter(now)).length;
    final expiredLicenses = licenses.where((l) => l.expiresAt.isBefore(now)).length;

    return {
      'totalClients': totalClients,
      'totalLicenses': totalLicenses,
      'activeLicenses': activeLicenses,
      'expiredLicenses': expiredLicenses,
    };
  }

  // ─── CONVERSIONS ────────────────────────────────────────────────────────────

  Map<String, dynamic> _clientToMap(Client client) => {
        'id': client.id,
        'name': client.name,
        'email': client.email,
        'company': client.company,
        'phone': client.phone,
        'address': client.address,
        'notes': client.notes,
        'createdAt': client.createdAt.toIso8601String(),
        'updatedAt': client.updatedAt.toIso8601String(),
        'isActive': client.isActive,
      };

  Client _clientFromMap(Map<String, dynamic> map) => Client(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        company: map['company'],
        phone: map['phone'],
        address: map['address'],
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        isActive: map['isActive'] ?? true,
      );

  Map<String, dynamic> _licenseToMap(License license) => {
        'id': license.id,
        'clientId': license.clientId,
        'licenseKey': license.licenseKey,
        'type': license.type.name,
        'status': license.status.name,
        'issuedAt': license.issuedAt.toIso8601String(),
        'expiresAt': license.expiresAt.toIso8601String(),
        'deviceFingerprint': license.deviceFingerprint,
        'features': license.features,
        'price': license.price,
        'currency': license.currency,
        'notes': license.notes,
        'privateKey': license.privateKey,
        'publicKey': license.publicKey,
        'revokedAt': license.revokedAt?.toIso8601String(),
        'revocationReason': license.revocationReason,
        'createdAt': license.createdAt.toIso8601String(),
        'updatedAt': license.updatedAt.toIso8601String(),
      };

  License _licenseFromMap(Map<String, dynamic> map) => License(
        id: map['id'],
        clientId: map['clientId'],
        licenseKey: map['licenseKey'],
        type: SubscriptionType.values.firstWhere((e) => e.name == map['type']),
        status: LicenseStatus.values.firstWhere((e) => e.name == map['status']),
        issuedAt: DateTime.parse(map['issuedAt']),
        expiresAt: DateTime.parse(map['expiresAt']),
        deviceFingerprint: map['deviceFingerprint'],
        features: List<String>.from(map['features'] ?? []),
        price: (map['price'] as num?)?.toDouble(),
        currency: map['currency'],
        notes: map['notes'],
        privateKey: map['privateKey'],
        publicKey: map['publicKey'],
        revokedAt: map['revokedAt'] != null ? DateTime.parse(map['revokedAt']) : null,
        revocationReason: map['revocationReason'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );

  Map<String, dynamic> _paymentToMap(Payment payment) => {
        'id': payment.id,
        'clientId': payment.clientId,
        'description': payment.description,
        'amount': payment.amount,
        'currency': payment.currency,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'notes': payment.notes,
        'createdAt': payment.createdAt.toIso8601String(),
        'updatedAt': payment.updatedAt.toIso8601String(),
      };

  Payment _paymentFromMap(Map<String, dynamic> map) => Payment(
        id: map['id'],
        clientId: map['clientId'],
        description: map['description'],
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] ?? 'XAF',
        paymentDate: DateTime.parse(map['paymentDate']),
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );

  Map<String, dynamic> _expenseToMap(Expense expense) => {
        'id': expense.id,
        'category': expense.category.name,
        'otherCategoryLabel': expense.otherCategoryLabel,
        'amount': expense.amount,
        'currency': expense.currency,
        'expenseDate': expense.expenseDate.toIso8601String(),
        'notes': expense.notes,
        'createdAt': expense.createdAt.toIso8601String(),
        'updatedAt': expense.updatedAt.toIso8601String(),
      };

  Expense _expenseFromMap(Map<String, dynamic> map) => Expense(
        id: map['id'],
        category: ExpenseCategory.values.firstWhere((e) => e.name == map['category']),
        otherCategoryLabel: map['otherCategoryLabel'],
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] ?? 'XAF',
        expenseDate: DateTime.parse(map['expenseDate']),
        notes: map['notes'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );
}

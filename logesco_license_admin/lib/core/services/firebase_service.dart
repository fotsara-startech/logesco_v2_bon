import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client.dart';
import '../../models/license.dart';

/// Service Firebase remplaçant SQLite pour un accès multi-plateforme (Windows + mobile)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _clients => _db.collection('clients');
  CollectionReference<Map<String, dynamic>> get _licenses => _db.collection('licenses');

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
    // Supprimer les licences associées
    final licenses = await _licenses.where('clientId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in licenses.docs) {
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
}

import '../../models/client.dart';
import '../../models/license.dart';
import 'firebase_service.dart';

/// Façade conservée pour compatibilité avec les pages existantes.
/// Délègue toutes les opérations à FirebaseService.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  final _fb = FirebaseService.instance;

  Future<void> initialize() async {
    // Firebase s'initialise dans main.dart via Firebase.initializeApp()
  }

  // ─── CLIENTS ────────────────────────────────────────────────────────────────

  Future<String> insertClient(Client client) => _fb.insertClient(client);

  Future<List<Client>> getClients({
    String? searchQuery,
    bool? isActive,
    int? limit,
    int? offset,
  }) =>
      _fb.getClients(searchQuery: searchQuery, isActive: isActive, limit: limit);

  Future<Client?> getClient(String id) => _fb.getClient(id);

  Future<void> updateClient(Client client) => _fb.updateClient(client);

  Future<void> deleteClient(String id) => _fb.deleteClient(id);

  // ─── LICENCES ───────────────────────────────────────────────────────────────

  Future<String> insertLicense(License license) => _fb.insertLicense(license);

  Future<List<License>> getLicenses({
    String? clientId,
    LicenseStatus? status,
    SubscriptionType? type,
    bool? isExpired,
    int? limit,
    int? offset,
  }) =>
      _fb.getLicenses(
        clientId: clientId,
        status: status,
        type: type,
        isExpired: isExpired,
        limit: limit,
      );

  Future<License?> getLicense(String id) => _fb.getLicense(id);

  Future<void> updateLicense(License license) => _fb.updateLicense(license);

  Future<void> deleteLicense(String id) => _fb.deleteLicense(id);

  // ─── STATISTIQUES ───────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatistics() => _fb.getStatistics();
}

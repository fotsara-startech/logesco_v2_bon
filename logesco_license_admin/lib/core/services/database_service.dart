import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/client.dart';
import '../../models/license.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'logesco_license_admin.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des clients
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        company TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Table des licences
    await db.execute('''
      CREATE TABLE licenses (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        license_key TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        issued_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        device_fingerprint TEXT NOT NULL,
        features TEXT NOT NULL,
        price REAL,
        currency TEXT DEFAULT 'EUR',
        notes TEXT,
        revoked_at TEXT,
        revocation_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_licenses_client_id ON licenses(client_id)');
    await db.execute('CREATE INDEX idx_licenses_status ON licenses(status)');
    await db.execute('CREATE INDEX idx_licenses_expires_at ON licenses(expires_at)');
    await db.execute('CREATE INDEX idx_clients_email ON clients(email)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations de base de données ici
    if (oldVersion < 2) {
      // Exemple de migration
      // await db.execute('ALTER TABLE clients ADD COLUMN new_field TEXT');
    }
  }

  // CRUD pour les clients
  Future<String> insertClient(Client client) async {
    final db = await database;
    await db.insert(
      'clients',
      _clientToMap(client),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return client.id;
  }

  Future<List<Client>> getClients({
    String? searchQuery,
    bool? isActive,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += 'name LIKE ? OR email LIKE ? OR company LIKE ?';
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    if (isActive != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_active = ?';
      whereArgs.add(isActive ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _clientFromMap(map)).toList();
  }

  Future<Client?> getClient(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _clientFromMap(maps.first);
    }
    return null;
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      _clientToMap(client),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD pour les licences
  Future<String> insertLicense(License license) async {
    final db = await database;
    await db.insert(
      'licenses',
      _licenseToMap(license),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return license.id;
  }

  Future<List<License>> getLicenses({
    String? clientId,
    LicenseStatus? status,
    SubscriptionType? type,
    bool? isExpired,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (clientId != null) {
      whereClause += 'client_id = ?';
      whereArgs.add(clientId);
    }

    if (status != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status.name);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.name);
    }

    if (isExpired != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      if (isExpired) {
        whereClause += 'expires_at < ?';
        whereArgs.add(DateTime.now().toIso8601String());
      } else {
        whereClause += 'expires_at >= ?';
        whereArgs.add(DateTime.now().toIso8601String());
      }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'licenses',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _licenseFromMap(map)).toList();
  }

  Future<License?> getLicense(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'licenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _licenseFromMap(maps.first);
    }
    return null;
  }

  Future<void> updateLicense(License license) async {
    final db = await database;
    await db.update(
      'licenses',
      _licenseToMap(license),
      where: 'id = ?',
      whereArgs: [license.id],
    );
  }

  Future<void> deleteLicense(String id) async {
    final db = await database;
    await db.delete(
      'licenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistiques
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final totalClients = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM clients WHERE is_active = 1')) ?? 0;

    final totalLicenses = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM licenses')) ?? 0;

    final activeLicenses =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM licenses WHERE status = ? AND expires_at >= ?', [LicenseStatus.active.name, DateTime.now().toIso8601String()])) ?? 0;

    final expiredLicenses = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM licenses WHERE expires_at < ?', [DateTime.now().toIso8601String()])) ?? 0;

    return {
      'totalClients': totalClients,
      'totalLicenses': totalLicenses,
      'activeLicenses': activeLicenses,
      'expiredLicenses': expiredLicenses,
    };
  }

  // Méthodes de conversion
  Map<String, dynamic> _clientToMap(Client client) {
    return {
      'id': client.id,
      'name': client.name,
      'email': client.email,
      'company': client.company,
      'phone': client.phone,
      'address': client.address,
      'notes': client.notes,
      'created_at': client.createdAt.toIso8601String(),
      'updated_at': client.updatedAt.toIso8601String(),
      'is_active': client.isActive ? 1 : 0,
    };
  }

  Client _clientFromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      company: map['company'],
      phone: map['phone'],
      address: map['address'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> _licenseToMap(License license) {
    return {
      'id': license.id,
      'client_id': license.clientId,
      'license_key': license.licenseKey,
      'type': license.type.name,
      'status': license.status.name,
      'issued_at': license.issuedAt.toIso8601String(),
      'expires_at': license.expiresAt.toIso8601String(),
      'device_fingerprint': license.deviceFingerprint,
      'features': license.features.join(','),
      'price': license.price,
      'currency': license.currency,
      'notes': license.notes,
      'revoked_at': license.revokedAt?.toIso8601String(),
      'revocation_reason': license.revocationReason,
      'created_at': license.createdAt.toIso8601String(),
      'updated_at': license.updatedAt.toIso8601String(),
    };
  }

  License _licenseFromMap(Map<String, dynamic> map) {
    return License(
      id: map['id'],
      clientId: map['client_id'],
      licenseKey: map['license_key'],
      type: SubscriptionType.values.firstWhere((e) => e.name == map['type']),
      status: LicenseStatus.values.firstWhere((e) => e.name == map['status']),
      issuedAt: DateTime.parse(map['issued_at']),
      expiresAt: DateTime.parse(map['expires_at']),
      deviceFingerprint: map['device_fingerprint'],
      features: map['features']?.split(',') ?? [],
      price: map['price']?.toDouble(),
      currency: map['currency'],
      notes: map['notes'],
      revokedAt: map['revoked_at'] != null ? DateTime.parse(map['revoked_at']) : null,
      revocationReason: map['revocation_reason'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

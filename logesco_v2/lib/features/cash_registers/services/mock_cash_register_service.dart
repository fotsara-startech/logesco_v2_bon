import '../models/cash_register_model.dart';

/// Service mock pour la gestion des caisses (données simulées)
class MockCashRegisterService {
  static final List<CashRegister> _cashRegisters = [
    CashRegister(
      id: 1,
      nom: 'Caisse Principale',
      description: 'Caisse principale du magasin',
      soldeInitial: 1000.0,
      soldeActuel: 1250.0,
      isActive: true,
      utilisateurId: 1,
      nomUtilisateur: 'Admin',
      dateCreation: DateTime.now().subtract(const Duration(days: 30)),
      dateModification: DateTime.now().subtract(const Duration(hours: 2)),
      dateOuverture: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CashRegister(
      id: 2,
      nom: 'Caisse Secondaire',
      description: 'Caisse pour les périodes de pointe',
      soldeInitial: 500.0,
      soldeActuel: 500.0,
      isActive: true,
      utilisateurId: null,
      nomUtilisateur: null,
      dateCreation: DateTime.now().subtract(const Duration(days: 15)),
      dateModification: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CashRegister(
      id: 3,
      nom: 'Caisse Express',
      description: 'Caisse rapide pour petits achats',
      soldeInitial: 200.0,
      soldeActuel: 180.0,
      isActive: false,
      utilisateurId: 2,
      nomUtilisateur: 'Manager',
      dateCreation: DateTime.now().subtract(const Duration(days: 10)),
      dateModification: DateTime.now().subtract(const Duration(days: 3)),
      dateOuverture: DateTime.now().subtract(const Duration(days: 3)),
      dateFermeture: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static final List<CashMovement> _movements = [
    CashMovement(
      id: 1,
      caisseId: 1,
      type: 'ouverture',
      montant: 1000.0,
      description: 'Ouverture de caisse',
      utilisateurId: 1,
      nomUtilisateur: 'Admin',
      dateCreation: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CashMovement(
      id: 2,
      caisseId: 1,
      type: 'vente',
      montant: 150.0,
      description: 'Vente #001',
      utilisateurId: 1,
      nomUtilisateur: 'Admin',
      dateCreation: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    CashMovement(
      id: 3,
      caisseId: 1,
      type: 'vente',
      montant: 100.0,
      description: 'Vente #002',
      utilisateurId: 1,
      nomUtilisateur: 'Admin',
      dateCreation: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  static int _nextCashRegisterId = 4;
  static int _nextMovementId = 4;

  /// Récupérer toutes les caisses
  static Future<List<CashRegister>> getAllCashRegisters() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_cashRegisters);
  }

  /// Récupérer une caisse par ID
  static Future<CashRegister> getCashRegisterById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final cashRegister = _cashRegisters.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Caisse non trouvée'),
    );
    return cashRegister;
  }

  /// Créer une nouvelle caisse
  static Future<CashRegister> createCashRegister(CashRegister cashRegister) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Vérifier si le nom existe déjà
    if (_cashRegisters.any((c) => c.nom == cashRegister.nom)) {
      throw Exception('Une caisse avec ce nom existe déjà');
    }

    final newCashRegister = cashRegister.copyWith(
      id: _nextCashRegisterId++,
      dateCreation: DateTime.now(),
      dateModification: DateTime.now(),
    );

    _cashRegisters.add(newCashRegister);
    return newCashRegister;
  }

  /// Mettre à jour une caisse
  static Future<CashRegister> updateCashRegister(int id, CashRegister cashRegister) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final index = _cashRegisters.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('Caisse non trouvée');
    }

    // Vérifier si le nom existe déjà (sauf pour la caisse actuelle)
    if (_cashRegisters.any((c) => c.nom == cashRegister.nom && c.id != id)) {
      throw Exception('Une caisse avec ce nom existe déjà');
    }

    final updatedCashRegister = cashRegister.copyWith(
      id: id,
      dateCreation: _cashRegisters[index].dateCreation,
      dateModification: DateTime.now(),
    );

    _cashRegisters[index] = updatedCashRegister;
    return updatedCashRegister;
  }

  /// Supprimer une caisse
  static Future<void> deleteCashRegister(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _cashRegisters.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('Caisse non trouvée');
    }

    // Vérifier si la caisse est ouverte
    if (_cashRegisters[index].isOpen) {
      throw Exception('Impossible de supprimer une caisse ouverte');
    }

    _cashRegisters.removeAt(index);

    // Supprimer aussi les mouvements associés
    _movements.removeWhere((m) => m.caisseId == id);
  }

  /// Ouvrir une caisse
  static Future<CashRegister> openCashRegister(int id, double initialAmount, int userId, String userName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _cashRegisters.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('Caisse non trouvée');
    }

    final cashRegister = _cashRegisters[index];

    if (cashRegister.isOpen) {
      throw Exception('Cette caisse est déjà ouverte');
    }

    if (!cashRegister.isActive) {
      throw Exception('Cette caisse est inactive');
    }

    final updatedCashRegister = cashRegister.copyWith(
      soldeInitial: initialAmount,
      soldeActuel: initialAmount,
      utilisateurId: userId,
      nomUtilisateur: userName,
      dateOuverture: DateTime.now(),
      dateFermeture: null,
      dateModification: DateTime.now(),
    );

    _cashRegisters[index] = updatedCashRegister;

    // Ajouter un mouvement d'ouverture
    final movement = CashMovement(
      id: _nextMovementId++,
      caisseId: id,
      type: 'ouverture',
      montant: initialAmount,
      description: 'Ouverture de caisse',
      utilisateurId: userId,
      nomUtilisateur: userName,
      dateCreation: DateTime.now(),
    );
    _movements.add(movement);

    return updatedCashRegister;
  }

  /// Fermer une caisse
  static Future<CashRegister> closeCashRegister(int id, double finalAmount, int userId, String userName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _cashRegisters.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('Caisse non trouvée');
    }

    final cashRegister = _cashRegisters[index];

    if (!cashRegister.isOpen) {
      throw Exception('Cette caisse n\'est pas ouverte');
    }

    final updatedCashRegister = cashRegister.copyWith(
      soldeActuel: finalAmount,
      dateFermeture: DateTime.now(),
      dateModification: DateTime.now(),
    );

    _cashRegisters[index] = updatedCashRegister;

    // Ajouter un mouvement de fermeture
    final movement = CashMovement(
      id: _nextMovementId++,
      caisseId: id,
      type: 'fermeture',
      montant: finalAmount,
      description: 'Fermeture de caisse',
      utilisateurId: userId,
      nomUtilisateur: userName,
      dateCreation: DateTime.now(),
    );
    _movements.add(movement);

    return updatedCashRegister;
  }

  /// Ajouter un mouvement de caisse
  static Future<CashMovement> addCashMovement(CashMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final cashRegisterIndex = _cashRegisters.indexWhere((c) => c.id == movement.caisseId);
    if (cashRegisterIndex == -1) {
      throw Exception('Caisse non trouvée');
    }

    if (!_cashRegisters[cashRegisterIndex].isOpen) {
      throw Exception('La caisse doit être ouverte pour ajouter un mouvement');
    }

    final newMovement = movement.copyWith(
      id: _nextMovementId++,
      dateCreation: DateTime.now(),
    );

    _movements.add(newMovement);

    // Mettre à jour le solde de la caisse
    final cashRegister = _cashRegisters[cashRegisterIndex];
    final newBalance = cashRegister.soldeActuel + movement.montant;

    _cashRegisters[cashRegisterIndex] = cashRegister.copyWith(
      soldeActuel: newBalance,
      dateModification: DateTime.now(),
    );

    return newMovement;
  }

  /// Récupérer les mouvements d'une caisse
  static Future<List<CashMovement>> getCashMovements(int cashRegisterId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return _movements.where((m) => m.caisseId == cashRegisterId).toList()..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  }

  /// Obtenir des statistiques sur les caisses
  static Future<Map<String, dynamic>> getCashRegisterStats() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final activeCashRegisters = _cashRegisters.where((c) => c.isActive).length;
    final openCashRegisters = _cashRegisters.where((c) => c.isOpen).length;
    final totalBalance = _cashRegisters.fold<double>(0.0, (sum, c) => sum + c.soldeActuel);

    final todayMovements = _movements.where((m) {
      final today = DateTime.now();
      final movementDate = m.dateCreation;
      return movementDate.year == today.year && movementDate.month == today.month && movementDate.day == today.day;
    }).length;

    return {
      'total': _cashRegisters.length,
      'active': activeCashRegisters,
      'open': openCashRegisters,
      'totalBalance': totalBalance,
      'todayMovements': todayMovements,
      'lastActivity': _movements.isNotEmpty ? _movements.map((m) => m.dateCreation).reduce((a, b) => a.isAfter(b) ? a : b) : null,
    };
  }
}

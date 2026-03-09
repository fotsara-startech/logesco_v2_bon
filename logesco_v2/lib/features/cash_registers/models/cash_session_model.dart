/// Modèle pour les sessions de caisse
class CashSession {
  final int? id;
  final int caisseId;
  final String nomCaisse;
  final int utilisateurId;
  final String nomUtilisateur;
  final double soldeOuverture;
  final double? soldeFermeture;
  final double? soldeAttendu;
  final double? ecart;
  final DateTime dateOuverture;
  final DateTime? dateFermeture;
  final bool isActive;
  final double totalEntrees;
  final double totalSorties;
  final Map<String, dynamic>? metadata;

  CashSession({
    this.id,
    required this.caisseId,
    required this.nomCaisse,
    required this.utilisateurId,
    required this.nomUtilisateur,
    required this.soldeOuverture,
    this.soldeFermeture,
    this.soldeAttendu,
    this.ecart,
    required this.dateOuverture,
    this.dateFermeture,
    this.isActive = true,
    this.totalEntrees = 0.0,
    this.totalSorties = 0.0,
    this.metadata,
  });

  factory CashSession.fromJson(Map<String, dynamic> json) {
    print('📦 MODEL - Parsing CashSession:');
    print('   json[\'ecart\']: ${json['ecart']}');
    print('   Type: ${json['ecart'].runtimeType}');

    final ecartValue = json['ecart'] != null ? (json['ecart']).toDouble() : null;
    print('   ecart parsé: $ecartValue');
    print('   Type parsé: ${ecartValue.runtimeType}');

    return CashSession(
      id: json['id'],
      caisseId: json['caisseId'],
      nomCaisse: json['nomCaisse'] ?? '',
      utilisateurId: json['utilisateurId'],
      nomUtilisateur: json['nomUtilisateur'] ?? '',
      soldeOuverture: (json['soldeOuverture'] ?? 0.0).toDouble(),
      soldeFermeture: json['soldeFermeture'] != null ? (json['soldeFermeture']).toDouble() : null,
      soldeAttendu: json['soldeAttendu'] != null ? (json['soldeAttendu']).toDouble() : null,
      ecart: ecartValue,
      dateOuverture: DateTime.parse(json['dateOuverture']),
      dateFermeture: json['dateFermeture'] != null ? DateTime.parse(json['dateFermeture']) : null,
      isActive: json['isActive'] ?? true,
      totalEntrees: (json['totalEntrees'] ?? 0.0).toDouble(),
      totalSorties: (json['totalSorties'] ?? 0.0).toDouble(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caisseId': caisseId,
      'nomCaisse': nomCaisse,
      'utilisateurId': utilisateurId,
      'nomUtilisateur': nomUtilisateur,
      'soldeOuverture': soldeOuverture,
      'soldeFermeture': soldeFermeture,
      'soldeAttendu': soldeAttendu,
      'ecart': ecart,
      'dateOuverture': dateOuverture.toIso8601String(),
      'dateFermeture': dateFermeture?.toIso8601String(),
      'isActive': isActive,
      'totalEntrees': totalEntrees,
      'totalSorties': totalSorties,
      'metadata': metadata,
    };
  }

  CashSession copyWith({
    int? id,
    int? caisseId,
    String? nomCaisse,
    int? utilisateurId,
    String? nomUtilisateur,
    double? soldeOuverture,
    double? soldeFermeture,
    double? soldeAttendu,
    double? ecart,
    DateTime? dateOuverture,
    DateTime? dateFermeture,
    bool? isActive,
    double? totalEntrees,
    double? totalSorties,
    Map<String, dynamic>? metadata,
  }) {
    return CashSession(
      id: id ?? this.id,
      caisseId: caisseId ?? this.caisseId,
      nomCaisse: nomCaisse ?? this.nomCaisse,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      soldeOuverture: soldeOuverture ?? this.soldeOuverture,
      soldeFermeture: soldeFermeture ?? this.soldeFermeture,
      soldeAttendu: soldeAttendu ?? this.soldeAttendu,
      ecart: ecart ?? this.ecart,
      dateOuverture: dateOuverture ?? this.dateOuverture,
      dateFermeture: dateFermeture ?? this.dateFermeture,
      isActive: isActive ?? this.isActive,
      totalEntrees: totalEntrees ?? this.totalEntrees,
      totalSorties: totalSorties ?? this.totalSorties,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Vérifie si la session est ouverte
  bool get isOpen => isActive && dateFermeture == null;

  /// Vérifie si la session est fermée
  bool get isClosed => !isActive && dateFermeture != null;

  /// Durée de la session
  Duration get duration {
    final end = dateFermeture ?? DateTime.now();
    return end.difference(dateOuverture);
  }

  /// Durée formatée
  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  /// Statut de la session (pour affichage)
  String get status {
    if (isOpen) return 'Ouverte';
    if (isClosed) return 'Fermée';
    return 'Inactive';
  }

  @override
  String toString() {
    return 'CashSession(id: $id, caisse: $nomCaisse, utilisateur: $nomUtilisateur, isActive: $isActive)';
  }
}

/// Filtre de période pour l'historique des sessions
enum SessionPeriodFilter {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
  all;

  String get label {
    switch (this) {
      case SessionPeriodFilter.today:
        return 'Aujourd\'hui';
      case SessionPeriodFilter.yesterday:
        return 'Hier';
      case SessionPeriodFilter.thisWeek:
        return 'Cette semaine';
      case SessionPeriodFilter.lastWeek:
        return 'Semaine dernière';
      case SessionPeriodFilter.thisMonth:
        return 'Ce mois';
      case SessionPeriodFilter.lastMonth:
        return 'Mois dernier';
      case SessionPeriodFilter.custom:
        return 'Période personnalisée';
      case SessionPeriodFilter.all:
        return 'Toutes les sessions';
    }
  }

  /// Obtenir la plage de dates pour le filtre
  DateRange? getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case SessionPeriodFilter.today:
        return DateRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        );
      case SessionPeriodFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRange(
          start: yesterday,
          end: today.subtract(const Duration(seconds: 1)),
        );
      case SessionPeriodFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          start: weekStart,
          end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        );
      case SessionPeriodFilter.lastWeek:
        final lastWeekEnd = today.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        return DateRange(
          start: lastWeekStart,
          end: lastWeekEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        );
      case SessionPeriodFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return DateRange(
          start: monthStart,
          end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        );
      case SessionPeriodFilter.lastMonth:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return DateRange(
          start: lastMonthStart,
          end: lastMonthEnd,
        );
      case SessionPeriodFilter.custom:
      case SessionPeriodFilter.all:
        return null;
    }
  }
}

/// Plage de dates
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) && (date.isBefore(end) || date.isAtSameMomentAs(end));
  }
}

// Doublons probables de fiches (clients, fournisseurs, boutiques) saisis sur deux postes, signalés par le serveur
// dans GET /sync/drift (champ doublons). L application ne fusionne rien seule : elle montre, la personne décide.

/// Une fiche d'un groupe de doublons
class SyncDoublonFiche {
  final int id;
  final String libelle;

  /// Solde du compte (clients et fournisseurs) ; null si la fiche n'a pas de compte
  final double? solde;

  const SyncDoublonFiche({required this.id, required this.libelle, this.solde});

  factory SyncDoublonFiche.fromJson(Map<String, dynamic> json) => SyncDoublonFiche(
        id: (json['id'] as num?)?.toInt() ?? 0,
        libelle: (json['libelle'] ?? '').toString(),
        solde: (json['solde'] as num?)?.toDouble(),
      );
}

/// Des fiches qui semblent désigner la même personne ou la même boutique
class SyncDoublonGroup {
  /// clients | fournisseurs | boutiques
  final String table;

  /// « Client », « Fournisseur », « Boutique »
  final String libelle;
  final List<SyncDoublonFiche> fiches;

  const SyncDoublonGroup({required this.table, required this.libelle, required this.fiches});

  int get nombre => fiches.length;

  factory SyncDoublonGroup.fromJson(Map<String, dynamic> json) => SyncDoublonGroup(
        table: (json['table'] ?? '').toString(),
        libelle: (json['libelle'] ?? json['table'] ?? '').toString(),
        fiches: (json['fiches'] as List<dynamic>? ?? const []).map((e) => SyncDoublonFiche.fromJson((e as Map).cast<String, dynamic>())).toList(),
      );

  /// Nom à montrer pour le groupe : la première fiche
  String get titre => fiches.isEmpty ? libelle : fiches.first.libelle;

  /// Somme des soldes des fiches qui en ont un (null si aucune n'a de compte)
  double? get soldeTotal {
    final soldes = fiches.map((f) => f.solde).whereType<double>().toList();
    return soldes.isEmpty ? null : soldes.fold<double>(0, (a, b) => a + b);
  }

  static List<SyncDoublonGroup> listeDepuis(dynamic brut) =>
      (brut as List<dynamic>? ?? const []).map((e) => SyncDoublonGroup.fromJson((e as Map).cast<String, dynamic>())).toList();
}

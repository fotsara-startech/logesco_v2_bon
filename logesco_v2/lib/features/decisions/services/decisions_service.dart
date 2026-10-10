import 'package:get/get.dart';
import '../../../core/api/api_client.dart';

/// Une raison pour laquelle un cas est à décider
class DecisionReason {
  final String code;
  final String titre;
  final String detail;

  const DecisionReason({required this.code, required this.titre, required this.detail});

  factory DecisionReason.fromJson(Map<String, dynamic> json) => DecisionReason(
        code: (json['code'] ?? '').toString(),
        titre: (json['titre'] ?? '').toString(),
        detail: (json['detail'] ?? '').toString(),
      );
}

/// Un choix possible, avec son résultat chiffré
class DecisionOption {
  final String id;
  final String label;
  final String description;
  final int cible;
  final int delta;
  final String consequence;
  final bool recommandee;

  /// Le produit (marqué « service ») redeviendra un produit physique si cette option est choisie
  final bool marquePhysique;

  const DecisionOption({
    required this.id,
    required this.label,
    required this.description,
    required this.cible,
    required this.delta,
    required this.consequence,
    this.recommandee = false,
    this.marquePhysique = false,
  });

  factory DecisionOption.fromJson(Map<String, dynamic> json) => DecisionOption(
        id: (json['id'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        cible: (json['cible'] as num?)?.toInt() ?? 0,
        delta: (json['delta'] as num?)?.toInt() ?? 0,
        consequence: (json['consequence'] ?? '').toString(),
        recommandee: json['recommandee'] == true,
        marquePhysique: json['marquePhysique'] == true,
      );
}

class DecisionSale {
  final String numeroVente;
  final DateTime? date;
  final int quantite;

  const DecisionSale({required this.numeroVente, required this.quantite, this.date});

  factory DecisionSale.fromJson(Map<String, dynamic> json) => DecisionSale(
        numeroVente: (json['numeroVente'] ?? '').toString(),
        quantite: (json['quantite'] as num?)?.toInt() ?? 0,
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString())?.toLocal() : null,
      );
}

class DecisionDuplicate {
  final int quantite;
  final DateTime? date;
  final DateTime? dateOriginal;

  const DecisionDuplicate({required this.quantite, this.date, this.dateOriginal});

  factory DecisionDuplicate.fromJson(Map<String, dynamic> json) => DecisionDuplicate(
        quantite: (json['quantite'] as num?)?.toInt() ?? 0,
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString())?.toLocal() : null,
        dateOriginal: json['dateOriginal'] != null ? DateTime.tryParse(json['dateOriginal'].toString())?.toLocal() : null,
      );
}

/// Un cas de stock à décider
class DecisionCase {
  final String key;
  final int produitId;
  final String produitNom;
  final String produitReference;
  final bool produitEstService;
  final String? boutiqueNom;
  final int stockAffiche;
  final int? dernierMouvementStock;
  final List<DecisionReason> raisons;
  final List<DecisionSale> ventes;
  final List<DecisionDuplicate> doublons;
  final List<DecisionOption> options;
  final int priorite;

  const DecisionCase({
    required this.key,
    required this.produitId,
    required this.produitNom,
    required this.produitReference,
    required this.produitEstService,
    required this.stockAffiche,
    required this.raisons,
    required this.ventes,
    required this.doublons,
    required this.options,
    required this.priorite,
    this.boutiqueNom,
    this.dernierMouvementStock,
  });

  factory DecisionCase.fromJson(Map<String, dynamic> json) {
    final produit = (json['produit'] as Map).cast<String, dynamic>();
    final boutique = (json['boutique'] as Map?)?.cast<String, dynamic>();
    List<T> liste<T>(String cle, T Function(Map<String, dynamic>) f) =>
        (json[cle] as List<dynamic>? ?? const []).map((e) => f((e as Map).cast<String, dynamic>())).toList();
    return DecisionCase(
      key: (json['key'] ?? '').toString(),
      produitId: (produit['id'] as num).toInt(),
      produitNom: (produit['nom'] ?? '').toString(),
      produitReference: (produit['reference'] ?? '').toString(),
      produitEstService: produit['estService'] == true,
      boutiqueNom: boutique?['nom']?.toString(),
      stockAffiche: (json['stockAffiche'] as num?)?.toInt() ?? 0,
      dernierMouvementStock: (json['dernierMouvementStock'] as num?)?.toInt(),
      raisons: liste('raisons', DecisionReason.fromJson),
      ventes: liste('ventes', DecisionSale.fromJson),
      doublons: liste('doublons', DecisionDuplicate.fromJson),
      options: liste('options', DecisionOption.fromJson),
      priorite: (json['priorite'] as num?)?.toInt() ?? 9,
    );
  }

  int get unitesVenduesSansSortie => ventes.fold(0, (s, v) => s + v.quantite);
}

/// Accès aux cas à décider et application d'une décision
class DecisionsService {
  ApiClient get _api => Get.find<ApiClient>();

  /// null si le serveur est trop ancien pour fournir la liste (ou en cas d'erreur réseau)
  Future<List<DecisionCase>?> fetch() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/decisions');
      if (!response.isSuccess || response.data == null) return null;
      final data = response.data!['data'] as Map<String, dynamic>?;
      final cases = (data?['cases'] as List<dynamic>? ?? const []);
      return cases.map((e) => DecisionCase.fromJson((e as Map).cast<String, dynamic>())).toList();
    } catch (_) {
      return null;
    }
  }

  /// Applique la décision. Lève une exception portant le message du serveur en cas de refus.
  Future<void> apply({required String caseKey, required String optionId, required int stockVu, int? cible}) async {
    final response = await _api.post<Map<String, dynamic>>('/decisions/apply', {
      'caseKey': caseKey,
      'optionId': optionId,
      'stockVu': stockVu,
      if (cible != null) 'cible': cible,
    });
    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Échec de l\'application de la décision');
    }
  }
}

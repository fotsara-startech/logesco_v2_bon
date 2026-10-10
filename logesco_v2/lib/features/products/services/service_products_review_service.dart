import 'package:get/get.dart';
import '../../../core/api/api_client.dart';

/// Un produit marqué « service » qui a pourtant reçu du stock : probablement un produit
/// physique marqué à tort. Ses ventes ne diminuent jamais son stock.
class ServiceProductToReview {
  final int id;
  final String reference;
  final String nom;
  final int quantiteRecue;
  final int quantiteVendue;
  final int stockAffiche;

  const ServiceProductToReview({
    required this.id,
    required this.reference,
    required this.nom,
    required this.quantiteRecue,
    required this.quantiteVendue,
    required this.stockAffiche,
  });

  factory ServiceProductToReview.fromJson(Map<String, dynamic> json) => ServiceProductToReview(
        id: (json['id'] as num).toInt(),
        reference: (json['reference'] ?? '').toString(),
        nom: (json['nom'] ?? '').toString(),
        quantiteRecue: (json['quantiteRecue'] as num?)?.toInt() ?? 0,
        quantiteVendue: (json['quantiteVendue'] as num?)?.toInt() ?? 0,
        stockAffiche: (json['stockAffiche'] as num?)?.toInt() ?? 0,
      );

  /// Unités vendues qui n'ont jamais quitté le stock
  bool get aDesVentesSansSortie => quantiteVendue > 0;
}

/// Accès à la liste « Produits à vérifier » et à la correction d'un produit.
class ServiceProductsReviewService {
  ApiClient get _api => Get.find<ApiClient>();

  /// null si le serveur est trop ancien pour fournir la liste (ou en cas d'erreur réseau)
  Future<List<ServiceProductToReview>?> fetch() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/products/service-with-stock');
      if (!response.isSuccess || response.data == null) return null;
      final data = response.data!['data'] as Map<String, dynamic>?;
      final items = (data?['produits'] as List<dynamic>? ?? const []);
      return items.map((e) => ServiceProductToReview.fromJson((e as Map).cast<String, dynamic>())).toList();
    } catch (_) {
      return null;
    }
  }

  /// Remet le produit en produit physique. Lève une exception portant le message du serveur.
  Future<void> markPhysical(int productId) async {
    final response = await _api.post<Map<String, dynamic>>('/products/$productId/mark-physical', <String, dynamic>{});
    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Échec de la modification du produit');
    }
  }
}

import '../models/ville.dart';
import '../models/zone.dart';
import '../models/commercial.dart';

/// Service abstrait pour la gestion des villes, zones et commerciaux terrain
abstract class CommercialService {
  Future<List<Ville>> getVilles();
  Future<Ville> createVille(String nom);
  Future<Ville> updateVille(int id, String nom);
  Future<bool> deleteVille(int id);

  Future<List<Zone>> getZones({int? villeId});
  Future<Zone> createZone(String nom, int villeId);
  Future<Zone> updateZone(int id, {String? nom, int? villeId});
  Future<bool> deleteZone(int id);

  Future<List<Commercial>> getCommerciaux({int? zoneId, int? villeId, bool? isActive, String? search});
  Future<Commercial> createCommercial(CommercialForm form);
  Future<Commercial> updateCommercial(int id, CommercialForm form);
  Future<bool> deleteCommercial(int id);
}

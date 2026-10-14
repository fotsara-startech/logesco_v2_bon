import 'package:flutter/material.dart';
import '../models/sync_doublons.dart';

/// Doublons probables de fiches (clients, fournisseurs, boutiques) saisis sur deux postes.
///
/// Le même client saisi sur deux postes devient deux fiches : le cloud n'a aucune clé unique sur ces tables, donc il ne
/// refuse rien et personne ne s'en aperçoit (deux comptes, deux soldes). L'application ne FUSIONNE RIEN seule, car
/// fusionner deux clients touche à des comptes : elle montre les doublons avec le solde de chaque fiche, et la
/// personne décide.
///
/// Cette carte n'est affichée que pour les clients qui ont une base cloud (voir SyncStatusPage : `isType3`), et
/// seulement s'il y a des doublons.
class SyncDoublonsCard extends StatelessWidget {
  final List<SyncDoublonGroup> groupes;
  final bool verification;
  final VoidCallback? onActualiser;

  const SyncDoublonsCard({super.key, required this.groupes, this.verification = false, this.onActualiser});

  /// Plage d'identifiants réservée à chaque poste : 10 000 000 par poste. En dessous : poste historique / avant la synchronisation.
  static const int _taillePlage = 10000000;

  static String posteDe(int id) {
    final n = id ~/ _taillePlage;
    return n == 0 ? 'poste d\'origine' : 'poste n°$n';
  }

  static String montant(double v) {
    final entier = v.round();
    final signe = entier < 0 ? '-' : '';
    final chiffres = entier.abs().toString();
    final tampon = StringBuffer();
    for (var i = 0; i < chiffres.length; i++) {
      if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write(' ');
      tampon.write(chiffres[i]);
    }
    return '$signe$tampon';
  }

  @override
  Widget build(BuildContext context) {
    if (groupes.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt_outlined, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${groupes.length} doublon(s) probable(s) de fiches',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (onActualiser != null)
                  IconButton(
                    tooltip: 'Revérifier',
                    onPressed: verification ? null : onActualiser,
                    icon: verification
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ces fiches semblent désigner la même personne ou la même boutique, saisies sur deux postes. '
              'L\'application ne les fusionne pas toute seule : vérifiez-les, puis gardez la bonne fiche.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),
            for (final g in groupes) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${g.libelle} · ${g.titre}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    for (final f in g.fiches)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• fiche n°${f.id} (${posteDe(f.id)})${f.solde != null ? ' — solde ${montant(f.solde!)}' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (g.soldeTotal != null && g.fiches.where((f) => f.solde != null && f.solde != 0).length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Les deux fiches ont un solde : ne supprimez aucune fiche avant d\'avoir regroupé les montants (total ${montant(g.soldeTotal!)}).',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

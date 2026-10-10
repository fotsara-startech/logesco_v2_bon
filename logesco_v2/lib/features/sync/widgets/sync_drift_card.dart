import 'package:flutter/material.dart';
import '../services/sync_status_service.dart';

/// Résultat du contrôle d'écart entre ce poste et le cloud.
///
/// Vert : les deux bases concordent. Orange/rouge : des éléments existent d'un seul côté ou ont une valeur
/// différente, sans que le système sache pourquoi (donc invisibles dans « ce qui n'est pas synchronisé »).
class SyncDriftCard extends StatelessWidget {
  final SyncDriftReport? report;
  final bool checking;
  final VoidCallback onCheck;

  /// Proposer le renvoi vers le cloud des éléments présents ici mais jamais arrivés dans le cloud
  final VoidCallback? onResend;

  const SyncDriftCard({super.key, required this.report, required this.checking, required this.onCheck, this.onResend});

  String _quand(DateTime? d) {
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} à ${two(d.hour)}:${two(d.minute)}';
  }

  String _sens(String sens) {
    switch (sens) {
      case 'a_recevoir':
        return 'Dans le cloud, pas ici';
      case 'a_envoyer':
        return 'Ici, pas dans le cloud';
      default:
        return 'Valeur différente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = report;
    final inexpliques = r?.inexpliques ?? 0;
    final alerte = inexpliques > 0;
    final groupes = (r?.ecarts ?? const <SyncDriftGroup>[]).where((g) => !g.connue).toList();

    return Card(
      color: r == null ? null : (alerte ? Colors.orange.shade50 : Colors.green.shade50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  r == null ? Icons.compare_arrows : (alerte ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                  color: r == null ? Colors.grey : (alerte ? Colors.orange.shade800 : Colors.green.shade700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r == null
                        ? 'Écart avec le cloud : pas encore vérifié'
                        : (alerte ? '$inexpliques élément(s) en écart avec le cloud' : 'Ce poste et le cloud concordent'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (r?.verifieLe != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Vérifié le ${_quand(r!.verifieLe)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ),
            if (alerte) ...[
              const SizedBox(height: 6),
              Text(
                "Ces éléments existent d'un seul côté ou ont une valeur différente, sans envoi ni réception en cours qui l'explique."
                '${r!.anciens > 0 ? ' ${r.anciens} durent depuis plus d\'un jour.' : ''}',
                style: TextStyle(fontSize: 12, color: r.anciens > 0 ? Colors.red.shade800 : Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              ...groupes.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g.tableLabel} · ${_sens(g.sens)} (${g.nombre})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(g.libelle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ...g.exemples.map((e) => Text('• ${e.resume}', style: const TextStyle(fontSize: 12))),
                        if (g.nombre > g.exemples.length)
                          Text('… et ${g.nombre - g.exemples.length} autre(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onResend != null && groupes.any((g) => g.sens == 'a_envoyer'))
                  ElevatedButton.icon(
                    onPressed: checking ? null : onResend,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Renvoyer vers le cloud'),
                  ),
                OutlinedButton.icon(
                  onPressed: checking ? null : onCheck,
                  icon: checking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  label: Text(checking ? 'Comparaison en cours…' : "Vérifier l'écart avec le cloud"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

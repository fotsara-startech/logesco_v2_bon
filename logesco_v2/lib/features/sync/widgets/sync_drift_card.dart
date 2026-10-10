import 'package:flutter/material.dart';
import '../services/sync_status_service.dart';

/// Résultat du contrôle d'écart entre ce poste et le cloud.
///
/// Vert : les deux bases concordent. Orange/rouge : des éléments existent d'un seul côté ou ont une valeur
/// différente, sans que le système sache pourquoi (donc invisibles dans « ce qui n'est pas synchronisé »).
///
/// Pour chaque écart « ici, pas dans le cloud », la carte dit tout de suite ce que le renvoi ferait :
/// envoyable sans risque, ou refusé avec la raison. Les actions proposées en découlent : renvoyer, envoyer
/// quand même (seul refus levable) ou ignorer l'écart (« vu, volontaire »).
class SyncDriftCard extends StatelessWidget {
  final SyncDriftReport? report;
  final bool checking;
  final VoidCallback onCheck;

  /// Renvoyer vers le cloud ce qui est sans risque (proposé seulement s'il y a quelque chose d'envoyable)
  final VoidCallback? onResend;

  /// Envoyer quand même les éléments refusés d'un groupe (seulement quand le refus est levable)
  final void Function(SyncDriftGroup group)? onForce;

  /// Déclarer un groupe d'écarts « vu, volontaire »
  final void Function(SyncDriftGroup group)? onIgnore;

  /// Réafficher les écarts précédemment ignorés
  final VoidCallback? onRestore;

  const SyncDriftCard({super.key, required this.report, required this.checking, required this.onCheck, this.onResend, this.onForce, this.onIgnore, this.onRestore});

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

  /// Ce que le renvoi ferait de ce groupe, en une phrase lisible
  Widget? _verdict(SyncDriftGroup g) {
    final v = g.renvoi;
    if (v == null) return null;
    final lignes = <Widget>[];
    if (v.envoyables > 0) {
      lignes.add(Text('${v.envoyables} peut/peuvent être renvoyé(s) sans risque.', style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w600)));
    }
    if (v.refuses > 0) {
      lignes.add(Text('${v.refuses} ne sera/seront pas renvoyé(s) automatiquement :', style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600)));
      for (final r in v.raisons) {
        lignes.add(Text('   $r', style: TextStyle(fontSize: 12, color: Colors.orange.shade900)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lignes);
  }

  @override
  Widget build(BuildContext context) {
    final r = report;
    final inexpliques = r?.inexpliques ?? 0;
    final alerte = inexpliques > 0;
    final groupes = (r?.ecarts ?? const <SyncDriftGroup>[]).where((g) => !g.connue).toList();
    final quelqueChoseAEnvoyer = groupes.any((g) => (g.renvoi?.envoyables ?? 0) > 0);

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
              ...groupes.map((g) {
                final verdict = _verdict(g);
                final peutForcer = onForce != null && (g.renvoi?.forcable ?? false);
                final peutIgnorer = onIgnore != null && g.ignorable;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${g.tableLabel} · ${_sens(g.sens)} (${g.nombre})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(g.libelle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ...g.exemples.map((e) => Text('• ${e.resume}', style: const TextStyle(fontSize: 12))),
                      if (g.nombre > g.exemples.length) Text('… et ${g.nombre - g.exemples.length} autre(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (verdict != null) Padding(padding: const EdgeInsets.only(top: 4), child: verdict),
                      if (peutForcer || peutIgnorer)
                        Wrap(
                          spacing: 8,
                          children: [
                            if (peutForcer) TextButton(onPressed: checking ? null : () => onForce!(g), child: const Text('Envoyer quand même')),
                            if (peutIgnorer) TextButton(onPressed: checking ? null : () => onIgnore!(g), child: const Text('Ignorer cet écart')),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            ],
            if ((r?.ignores ?? 0) > 0 && onRestore != null)
              Row(
                children: [
                  Expanded(child: Text('${r!.ignores} écart(s) ignoré(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                  TextButton(onPressed: checking ? null : onRestore, child: const Text('Réafficher')),
                ],
              ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                // Proposé seulement s'il y a réellement quelque chose à envoyer sans risque
                if (onResend != null && quelqueChoseAEnvoyer)
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

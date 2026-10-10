import 'package:flutter/material.dart';
import '../services/decisions_service.dart';

/// Un conflit de synchronisation : les deux fiches côte à côte, les options chiffrées, et la décision.
class SyncConflictCard extends StatefulWidget {
  final SyncConflict conflict;
  final bool peutDecider;

  /// Envoie la décision ; lève une exception portant le message du serveur en cas de refus
  final Future<void> Function(String optionId, String? valeur) onApply;

  const SyncConflictCard({super.key, required this.conflict, required this.peutDecider, required this.onApply});

  @override
  State<SyncConflictCard> createState() => _SyncConflictCardState();
}

class _SyncConflictCardState extends State<SyncConflictCard> {
  String? _choix;
  bool _busy = false;
  late final TextEditingController _valeur = TextEditingController();

  SyncConflict get _c => widget.conflict;

  @override
  void initState() {
    super.initState();
    final rec = _c.options.where((o) => o.recommandee);
    if (rec.isNotEmpty) _choisir(rec.first);
  }

  @override
  void dispose() {
    _valeur.dispose();
    super.dispose();
  }

  void _choisir(SyncConflictOption o) {
    _choix = o.id;
    _valeur.text = o.valeurSuggeree ?? '';
  }

  Future<void> _appliquer() async {
    final option = _c.options.firstWhere((o) => o.id == _choix);
    final valeur = option.valeurSuggeree != null ? _valeur.text.trim() : null;
    if (option.valeurSuggeree != null && (valeur == null || valeur.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saisissez le nouveau ${_c.cleMot}.')));
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer cette décision ?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_c.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(option.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (valeur != null) Text('Nouveau ${_c.cleMot} : $valeur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(option.consequence),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Appliquer')),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _busy = true);
    try {
      await widget.onApply(option.id, valeur);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _fiche(String titre, SyncConflictSide side, Color couleur) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('n° ${side.id}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            ...side.resume.map((l) => Text(l, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final choix = _choix;
    final actif = widget.peutDecider && !_busy;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(_c.key),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(_c.titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('${_c.libelle} · ${_c.cleMot} : ${_c.cleValeur}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          children: [
            if (_c.explication.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_c.explication, style: const TextStyle(fontSize: 12))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fiche('Sur ce poste', _c.local, Colors.blue.shade50),
                const SizedBox(width: 8),
                _fiche('Dans le cloud', _c.cloud, Colors.green.shade50),
              ],
            ),
            const Divider(),
            const Text('Votre décision', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._c.options.map((o) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: o.id,
                  groupValue: choix,
                  onChanged: actif ? (_) => setState(() => _choisir(o)) : null,
                  title: Row(
                    children: [
                      Expanded(child: Text(o.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      if (o.recommandee)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text('conseillé', style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.consequence, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      Text(o.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      if (choix == o.id && o.valeurSuggeree != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          // bucket isolé : le défilement du champ ne doit pas relire l'état de l'ExpansionTile
                          child: PageStorage(
                            bucket: PageStorageBucket(),
                            child: TextField(
                              controller: _valeur,
                              enabled: actif,
                              decoration: InputDecoration(isDense: true, labelText: 'Nouveau ${_c.cleMot}', border: const OutlineInputBorder()),
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: (actif && choix != null) ? _appliquer : null,
                icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                label: const Text('Appliquer cette décision'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

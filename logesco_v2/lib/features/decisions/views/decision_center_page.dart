import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/decisions_service.dart';

/// Centre de décisions : les cas où l'application ne peut pas trancher seule.
///
/// Pour chaque cas : les faits, des options avec leur résultat chiffré, et c'est la personne qui
/// décide. Le choix est appliqué par un mouvement de correction tracé.
class DecisionCenterPage extends StatefulWidget {
  /// Pour les tests : service de remplacement
  final DecisionsService? service;

  /// Pour les tests : droit d'appliquer (sinon lu depuis l'utilisateur connecté)
  final bool? canDecide;

  const DecisionCenterPage({super.key, this.service, this.canDecide});

  @override
  State<DecisionCenterPage> createState() => _DecisionCenterPageState();
}

class _DecisionCenterPageState extends State<DecisionCenterPage> {
  late final DecisionsService _service = widget.service ?? DecisionsService();
  List<DecisionCase>? _cases;
  bool _loading = true;
  final Set<String> _working = {};

  /// Option choisie par cas, et quantité saisie le cas échéant
  final Map<String, String> _choix = {};
  final Map<String, TextEditingController> _manuel = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _manuel.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _peutDecider {
    if (widget.canDecide != null) return widget.canDecide!;
    // Administrateur seulement : appliquer une décision modifie le stock (le serveur le vérifie aussi)
    if (!Get.isRegistered<AuthController>()) return true;
    return Get.find<AuthController>().currentUser.value?.role.isAdmin ?? false;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cases = await _service.fetch();
    if (!mounted) return;
    setState(() {
      _cases = cases;
      _loading = false;
      // option recommandée pré-sélectionnée ; sinon aucune (la personne doit choisir)
      for (final c in cases ?? const <DecisionCase>[]) {
        final recommandee = c.options.where((o) => o.recommandee);
        if (!_choix.containsKey(c.key) && recommandee.isNotEmpty) _choix[c.key] = recommandee.first.id;
      }
    });
  }

  TextEditingController _controleurManuel(String key) => _manuel.putIfAbsent(key, () => TextEditingController());

  Future<void> _appliquer(DecisionCase c) async {
    final optionId = _choix[c.key];
    if (optionId == null) {
      SnackbarHelper.warning('Choisissez d\'abord une option.');
      return;
    }
    int? cible;
    String resume;
    bool physique = false;
    if (optionId == 'manuel') {
      cible = int.tryParse(_controleurManuel(c.key).text.trim());
      if (cible == null || cible < 0) {
        SnackbarHelper.warning('Saisissez une quantité entière (0 ou plus).');
        return;
      }
      resume = 'Stock ${c.stockAffiche} → $cible (${cible - c.stockAffiche >= 0 ? '+' : ''}${cible - c.stockAffiche})';
      physique = c.produitEstService;
    } else {
      final o = c.options.firstWhere((x) => x.id == optionId);
      resume = o.consequence;
      physique = o.marquePhysique;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer cette décision ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.produitNom, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (c.boutiqueNom != null) Text(c.boutiqueNom!, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Text(resume, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (physique) ...[
              const SizedBox(height: 8),
              const Text('Le produit sera marqué « produit physique » (géré en stock).'),
            ],
            const SizedBox(height: 8),
            Text(
              'Un mouvement de correction sera enregistré avec cette décision ; l\'historique n\'est pas modifié.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Appliquer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _envoyer(c, optionId, cible);
  }

  Future<void> _laisserTelQuel(DecisionCase c) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Laisser tel quel ?'),
        content: const Text('Rien ne sera modifié et ce cas ne sera plus affiché (il réapparaîtra seulement si la situation change).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Laisser tel quel')),
        ],
      ),
    );
    if (confirme != true) return;
    await _envoyer(c, 'ignorer', null);
  }

  Future<void> _envoyer(DecisionCase c, String optionId, int? cible) async {
    setState(() => _working.add(c.key));
    try {
      await _service.apply(caseKey: c.key, optionId: optionId, stockVu: c.stockAffiche, cible: cible);
      SnackbarHelper.success(optionId == 'ignorer' ? 'Cas laissé tel quel' : 'Décision appliquée : « ${c.produitNom} »');
      _choix.remove(c.key);
      await _load();
    } catch (e) {
      SnackbarHelper.error(e.toString().replaceFirst('Exception: ', ''));
      await _load(); // le stock a peut-être changé entre-temps
    } finally {
      if (mounted) setState(() => _working.remove(c.key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Décisions à prendre'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualiser')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cases == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Impossible de charger la liste (serveur injoignable ou trop ancien).', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _cases!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade400),
                          const SizedBox(height: 12),
                          const Text('Aucune décision à prendre', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    )
                  : _buildList(_cases!),
    );
  }

  Widget _buildList(List<DecisionCase> cases) {
    final peutDecider = _peutDecider;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.orange.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rule, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${cases.length} cas où l\'application ne peut pas trancher seule',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pour chacun : les faits, des options avec leur résultat chiffré, et c\'est vous qui décidez. '
                  'Le choix est appliqué par un mouvement de correction ; l\'historique n\'est jamais réécrit. '
                  'Idéalement, appuyez-vous sur un comptage physique.',
                  style: TextStyle(fontSize: 13),
                ),
                if (!peutDecider) ...[
                  const SizedBox(height: 8),
                  Text('Seul un administrateur peut appliquer une décision.', style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...cases.map((c) => _buildCase(c, peutDecider)),
      ],
    );
  }

  Widget _buildCase(DecisionCase c, bool peutDecider) {
    final busy = _working.contains(c.key);
    final choix = _choix[c.key];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(c.key),
          initiallyExpanded: c.priorite == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(c.produitNom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            '${c.boutiqueNom != null ? '${c.boutiqueNom} · ' : ''}Stock affiché : ${c.stockAffiche}'
            '${c.produitEstService ? ' · marqué « service »' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          children: [
            ...c.raisons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(r.detail, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (c.ventes.isNotEmpty) _faits('Ventes sans mouvement de stock', c.ventes.map((v) => '${v.numeroVente}${v.date != null ? ' (${_date(v.date!)})' : ''} : ${v.quantite} unité(s)').toList()),
            if (c.doublons.isNotEmpty)
              _faits(
                'Réceptions suspectes',
                c.doublons.map((d) => '${d.quantite} unité(s) reçues le ${d.date != null ? _date(d.date!) : '?'}, déjà reçues le ${d.dateOriginal != null ? _date(d.dateOriginal!) : '?'} sans lien entre les deux saisies').toList(),
              ),
            if (c.dernierMouvementStock != null) _faits('Historique', ['Le dernier mouvement indique un stock de ${c.dernierMouvementStock}']),
            const Divider(),
            const Text('Votre décision', style: TextStyle(fontWeight: FontWeight.bold)),
            ...c.options.map((o) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: o.id,
                  groupValue: choix,
                  onChanged: (busy || !peutDecider) ? null : (v) => setState(() => _choix[c.key] = v!),
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
                      Text(o.consequence, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: o.delta == 0 ? Colors.grey.shade700 : Colors.blue.shade800)),
                      Text(o.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      if (o.marquePhysique) Text('→ le produit sera marqué « produit physique »', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                )),
            RadioListTile<String>(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: 'manuel',
              groupValue: choix,
              onChanged: (busy || !peutDecider) ? null : (v) => setState(() => _choix[c.key] = v!),
              title: const Text('Saisir la quantité comptée', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: choix == 'manuel'
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 160,
                        // bucket isolé : sinon le défilement du champ relit l'état (booléen) de l'ExpansionTile
                        child: PageStorage(
                          bucket: PageStorageBucket(),
                          child: TextField(
                            controller: _controleurManuel(c.key),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, labelText: 'Quantité réelle', border: OutlineInputBorder()),
                          ),
                        ),
                      ),
                    )
                  : const Text('Après comptage physique : le plus fiable', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(height: 8),
            // Wrap : sur un téléphone les deux boutons passent à la ligne au lieu de déborder
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(onPressed: (busy || !peutDecider) ? null : () => _laisserTelQuel(c), child: const Text('Laisser tel quel')),
                ElevatedButton.icon(
                  onPressed: (busy || !peutDecider || choix == null) ? null : () => _appliquer(c),
                  icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                  label: const Text('Appliquer ma décision'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _faits(String titre, List<String> lignes) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            ...lignes.map((l) => Text('• $l', style: const TextStyle(fontSize: 12))),
          ],
        ),
      );

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

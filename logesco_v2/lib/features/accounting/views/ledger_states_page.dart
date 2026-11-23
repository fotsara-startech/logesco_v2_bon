import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_entry_form_page.dart';

// ───────────────────────────── Résumé (mode simple) ─────────────────────────────

/// Résumé financier en langage clair : résultat du mois, trésorerie, créances, dettes, TVA.
class LedgerSummaryTab extends StatefulWidget {
  const LedgerSummaryTab({super.key});

  @override
  State<LedgerSummaryTab> createState() => _LedgerSummaryTabState();
}

class _LedgerSummaryTabState extends State<LedgerSummaryTab> {
  final c = Get.find<LedgerController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.chargerResume());
  }

  Widget _carte(String titre, num valeur, IconData icone, Color couleur, {String? note}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icone, color: couleur, size: 20), const SizedBox(width: 8), Expanded(child: Text(titre, style: const TextStyle(fontSize: 13)))]),
            const SizedBox(height: 8),
            Text('${formatFcfa(valeur)} FCFA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valeur < 0 ? Colors.red : null)),
            if (note != null) Text(note, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = c.resume.value;
      final mois = c.moisResume.value;
      return RefreshIndicator(
        onRefresh: c.chargerResume,
        child: ListView(padding: const EdgeInsets.all(12), children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => c.changerMoisResume(-1)),
            Text(DateFormat('MMMM yyyy').format(mois), style: Theme.of(context).textTheme.titleMedium),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => c.changerMoisResume(1)),
          ]),
          if (r == null)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(c.isLoading.value ? '' : 'compta_summary_empty'.tr)))
          else ...[
            _carte('compta_summary_result'.tr, r['resultat'] as num, (r['resultat'] as num) >= 0 ? Icons.trending_up : Icons.trending_down, (r['resultat'] as num) >= 0 ? Colors.green : Colors.red,
                note: '${'compta_summary_sales'.tr} ${formatFcfa(r['chiffreAffaires'] as num)} · ${'compta_summary_expenses'.tr} ${formatFcfa(r['charges'] as num)}'),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _carte('compta_summary_cash'.tr, r['tresorerie'] as num, Icons.account_balance_wallet, Colors.blue),
                _carte('compta_summary_receivables'.tr, r['creancesClients'] as num, Icons.people, Colors.orange),
                _carte('compta_summary_payables'.tr, r['dettesFournisseurs'] as num, Icons.local_shipping, Colors.brown),
                _carte('compta_summary_stock'.tr, r['stock'] as num, Icons.inventory_2, Colors.purple),
                _carte('compta_summary_vat'.tr, r['tvaAPayer'] as num, Icons.receipt_long, Colors.teal,
                    note: (r['creditTva'] as num) > 0 ? '${'compta_summary_vat_credit'.tr} ${formatFcfa(r['creditTva'] as num)}' : null),
              ],
            ),
            if ((r['topCharges'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('compta_summary_top_expenses'.tr, style: Theme.of(context).textTheme.titleMedium),
              for (final x in r['topCharges'] as List)
                ListTile(dense: true, title: Text('${x['numero']} - ${x['libelle']}'), trailing: Text(formatFcfa(x['montant'] as num))),
            ],
            Padding(padding: const EdgeInsets.only(top: 12), child: Text('compta_summary_disclaimer'.tr, style: const TextStyle(fontSize: 11, color: Colors.grey))),
          ],
        ]),
      );
    });
  }
}

// ───────────────────────────── États financiers ─────────────────────────────

class _EtatDef {
  final String id;
  final String cleLibelle;
  final String chemin;
  final String fichier;
  final Map<String, dynamic> Function(DateTime mois)? parametres;
  final bool smtMasque;
  final bool expertSeul;
  const _EtatDef(this.id, this.cleLibelle, this.chemin, this.fichier, {this.parametres, this.smtMasque = false, this.expertSeul = false});
}

final List<_EtatDef> _etats = [
  const _EtatDef('resultat', 'compta_state_income', '/etats/resultat', 'compte-de-resultat'),
  const _EtatDef('bilan', 'compta_state_balance_sheet', '/etats/bilan', 'bilan', smtMasque: true),
  const _EtatDef('tft', 'compta_state_cash_flow', '/etats/tft', 'tableau-flux-tresorerie', smtMasque: true),
  _EtatDef('tva', 'compta_state_vat', '/etats/tva', 'declaration-tva', parametres: (m) => {'annee': m.year, 'mois': m.month}),
  const _EtatDef('clients', 'compta_state_receivables', '/etats/balance-agee', 'balance-agee-clients'),
  const _EtatDef('fournisseurs', 'compta_state_payables', '/etats/balance-agee', 'balance-agee-fournisseurs'),
  const _EtatDef('recettes', 'compta_state_cash_book', '/etats/recettes-depenses', 'recettes-depenses'),
  const _EtatDef('journal', 'compta_state_journal', '/etats/journal', 'journal', expertSeul: true),
];

/// Compte de résultat, bilan, TVA, balances âgées, livre des recettes et dépenses, journal — avec export.
class LedgerStatesTab extends StatefulWidget {
  const LedgerStatesTab({super.key});

  @override
  State<LedgerStatesTab> createState() => _LedgerStatesTabState();
}

class _LedgerStatesTabState extends State<LedgerStatesTab> {
  final c = Get.find<LedgerController>();
  String _courant = 'resultat';
  DateTime _mois = DateTime(DateTime.now().year, DateTime.now().month, 1);

  _EtatDef get _def => _etats.firstWhere((e) => e.id == _courant);

  Map<String, dynamic> get _query {
    final q = <String, dynamic>{...?_def.parametres?.call(_mois)};
    if (_courant == 'clients') q['type'] = 'client';
    if (_courant == 'fournisseurs') q['type'] = 'fournisseur';
    return q;
  }

  Future<void> _charger() => c.chargerTableau(_def.chemin, _query);

  Future<void> _exporter(String format) async {
    final nom = '${_def.fichier}-${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    final chemin = await c.exporter(_def.chemin, _query, format, nom);
    if (chemin != null) SnackbarHelper.success('${'compta_export_saved'.tr} : $chemin');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  String _cellule(dynamic v, Map<String, dynamic> col) {
    if (v == null) return '';
    if (col['type'] == 'montant' && v is num) return formatFcfa(v);
    if (col['type'] == 'date') {
      final d = DateTime.tryParse(v.toString());
      return d == null ? '' : DateFormat('dd/MM/yyyy').format(d.toUtc());
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final smt = c.parametres['regime'] == 'smt';
      final expert = c.modeExpert;
      final visibles = _etats.where((e) => !(e.smtMasque && smt) && !(e.expertSeul && !expert)).toList();
      if (!visibles.any((e) => e.id == _courant)) _courant = visibles.first.id;
      final t = c.tableauCourant.value;
      return Column(children: [
        SizedBox(
          height: 54,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), children: [
            for (final e in visibles)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(e.cleLibelle.tr),
                  selected: e.id == _courant,
                  onSelected: (_) {
                    setState(() => _courant = e.id);
                    _charger();
                  },
                ),
              ),
          ]),
        ),
        if (_courant == 'tva')
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { setState(() => _mois = DateTime(_mois.year, _mois.month - 1, 1)); _charger(); }),
            Text(DateFormat('MMMM yyyy').format(_mois)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { setState(() => _mois = DateTime(_mois.year, _mois.month + 1, 1)); _charger(); }),
          ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            if (c.etatEnCours.value) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const Spacer(),
            if (expert && (_courant == 'clients' || _courant == 'fournisseurs'))
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: Text('compta_auto_lettering'.tr),
                onPressed: () async {
                  await c.lettrageAuto(_courant == 'clients' ? 'client' : 'fournisseur');
                  _charger();
                },
              ),
            TextButton.icon(icon: const Icon(Icons.table_chart), label: const Text('Excel'), onPressed: () => _exporter('xlsx')),
            TextButton.icon(icon: const Icon(Icons.description), label: const Text('CSV'), onPressed: () => _exporter('csv')),
          ]),
        ),
        Expanded(child: t == null ? Center(child: Text(c.etatEnCours.value ? '' : 'compta_no_entries'.tr)) : _tableau(context, t)),
      ]);
    });
  }

  Widget _tableau(BuildContext context, Map<String, dynamic> t) {
    final colonnes = List<Map<String, dynamic>>.from((t['colonnes'] as List).map((x) => Map<String, dynamic>.from(x as Map)));
    final lignes = List<Map<String, dynamic>>.from((t['lignes'] as List).map((x) => Map<String, dynamic>.from(x as Map)));
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text(t['titre'].toString(), style: Theme.of(context).textTheme.titleMedium),
      if (t['sousTitre'] != null) Text(t['sousTitre'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowHeight: 38,
          dataRowMinHeight: 30,
          dataRowMaxHeight: 44,
          columns: [for (final col in colonnes) DataColumn(label: Text(col['libelle'].toString()), numeric: col['type'] == 'montant')],
          rows: [
            for (final l in lignes)
              DataRow(cells: [
                for (final col in colonnes)
                  DataCell(Text(_cellule(l[col['cle']], col), style: TextStyle(fontWeight: l['gras'] == true ? FontWeight.bold : FontWeight.normal))),
              ]),
          ],
        ),
      ),
    ]);
  }
}

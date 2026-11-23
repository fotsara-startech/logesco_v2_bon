import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_entry_form_page.dart';

/// Immobilisations : liste, ajout, plan d'amortissement, cession, calcul des dotations de l'exercice.
class LedgerAssetsTab extends StatefulWidget {
  const LedgerAssetsTab({super.key});

  @override
  State<LedgerAssetsTab> createState() => _LedgerAssetsTabState();
}

class _LedgerAssetsTabState extends State<LedgerAssetsTab> {
  final c = Get.find<LedgerController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.chargerImmobilisations());
  }

  String _jour(dynamic iso) {
    final d = DateTime.tryParse((iso ?? '').toString());
    return d == null ? '' : DateFormat('dd/MM/yyyy').format(d.toUtc());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        onPressed: () => _ajouter(context),
        icon: const Icon(Icons.add),
        label: Text('compta_asset_add'.tr),
      ),
      body: Obx(() {
        final liste = c.immobilisations;
        if (liste.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('compta_asset_none'.tr, textAlign: TextAlign.center)));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          itemCount: liste.length,
          itemBuilder: (_, i) {
            final a = liste[i];
            final cedee = a['statut'] == 'cedee';
            return Card(
              child: ListTile(
                title: Text(a['libelle'].toString()),
                subtitle: Text('${a['compteNumero']} · ${_jour(a['dateAcquisition'])} · ${a['dureeMois']} ${'compta_asset_months'.tr}'
                    '${cedee ? ' · ${'compta_asset_sold'.tr} ${_jour(a['dateCession'])}' : ''}'),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatFcfa(a['valeurNette'] as num), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${'compta_asset_cost'.tr} ${formatFcfa(a['valeur'] as num)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
                onTap: () => _detail(context, a),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _detail(BuildContext context, Map<String, dynamic> a) async {
    final plan = await c.planAmortissement(a['id'] as int);
    if (plan == null || !context.mounted) return;
    final lignes = List<Map<String, dynamic>>.from((plan['lignes'] as List).map((x) => Map<String, dynamic>.from(x as Map)));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
          Text(a['libelle'].toString(), style: Theme.of(context).textTheme.titleMedium),
          Text('${'compta_asset_plan'.tr} (${a['compteNumero']} → ${a['compteAmortNumero']})', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          DataTable(
            columns: [
              DataColumn(label: Text('compta_asset_year'.tr)),
              DataColumn(label: Text('compta_asset_charge'.tr), numeric: true),
              DataColumn(label: Text('compta_asset_accumulated'.tr), numeric: true),
              DataColumn(label: Text('compta_asset_net'.tr), numeric: true),
            ],
            rows: [for (final l in lignes) DataRow(cells: [DataCell(Text('${l['annee']}')), DataCell(Text(formatFcfa(l['dotation'] as num))), DataCell(Text(formatFcfa(l['cumul'] as num))), DataCell(Text(formatFcfa(l['valeurNette'] as num)))])],
          ),
          const SizedBox(height: 12),
          if (a['statut'] != 'cedee')
            OutlinedButton.icon(
              icon: const Icon(Icons.sell),
              label: Text('compta_asset_sell'.tr),
              onPressed: () {
                Navigator.pop(ctx);
                _ceder(context, a);
              },
            ),
        ]),
      ),
    );
  }

  void _ajouter(BuildContext context) {
    final libelle = TextEditingController();
    final compte = TextEditingController(text: '2183');
    final date = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final valeur = TextEditingController();
    final duree = TextEditingController(text: '36');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('compta_asset_add'.tr),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: libelle, decoration: InputDecoration(labelText: 'compta_label'.tr)),
            TextField(controller: compte, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'compta_asset_account'.tr)),
            TextField(controller: date, decoration: InputDecoration(labelText: 'compta_asset_date'.tr, hintText: 'AAAA-MM-JJ')),
            TextField(controller: valeur, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'compta_asset_cost'.tr, suffixText: 'FCFA')),
            TextField(controller: duree, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'compta_asset_months'.tr)),
            const SizedBox(height: 8),
            Text('compta_asset_help'.tr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              final ok = await c.creerImmobilisation({
                'libelle': libelle.text.trim(),
                'compteNumero': compte.text.trim(),
                'dateAcquisition': date.text.trim(),
                'valeur': int.tryParse(valeur.text.replaceAll(' ', '')) ?? 0,
                'dureeMois': int.tryParse(duree.text.trim()) ?? 0,
              });
              if (ok && ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _ceder(BuildContext context, Map<String, dynamic> a) {
    final date = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final prix = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('compta_asset_sell'.tr),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: date, decoration: InputDecoration(labelText: 'compta_asset_sale_date'.tr, hintText: 'AAAA-MM-JJ')),
          TextField(controller: prix, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'compta_asset_sale_price'.tr, suffixText: 'FCFA')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              final r = await c.ceder(a['id'] as int, date.text.trim(), int.tryParse(prix.text.replaceAll(' ', '')) ?? 0);
              if (r != null && ctx.mounted) {
                Navigator.pop(ctx);
                SnackbarHelper.info('${'compta_asset_gain'.tr} : ${formatFcfa(r['plusOuMoinsValue'] as num)} FCFA');
              }
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}

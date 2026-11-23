import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';

/// Formate un montant entier en FCFA avec séparateur de milliers (ex. 1 250 000)
String formatFcfa(num? montant) => NumberFormat('#,##0').format(montant ?? 0).replaceAll(',', ' ');

/// Libellé « 411 - Clients » d'un compte
String libelleCompte(Map<String, dynamic> c) => '${c['numero']} - ${c['libelle']}';

class _LigneForm {
  String? compteNumero;
  final TextEditingController compte = TextEditingController();
  final TextEditingController debit = TextEditingController();
  final TextEditingController credit = TextEditingController();
  final TextEditingController libelle = TextEditingController();

  int get montantDebit => int.tryParse(debit.text.replaceAll(' ', '')) ?? 0;
  int get montantCredit => int.tryParse(credit.text.replaceAll(' ', '')) ?? 0;

  void dispose() {
    compte.dispose();
    debit.dispose();
    credit.dispose();
    libelle.dispose();
  }
}

/// Saisie ou modification d'une écriture en partie double (brouillon).
/// Argument optionnel : l'écriture à modifier (avec ses lignes).
class LedgerEntryFormPage extends StatefulWidget {
  const LedgerEntryFormPage({super.key});

  @override
  State<LedgerEntryFormPage> createState() => _LedgerEntryFormPageState();
}

class _LedgerEntryFormPageState extends State<LedgerEntryFormPage> {
  final LedgerController c = Get.find<LedgerController>();
  final _libelle = TextEditingController();
  final List<_LigneForm> _lignes = [];
  String _journal = 'OD';
  DateTime _date = DateTime.now();
  int? _id;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    final existante = Get.arguments is Map<String, dynamic> ? Get.arguments as Map<String, dynamic> : null;
    if (existante != null) {
      _id = existante['id'] as int?;
      _libelle.text = (existante['libelle'] ?? '').toString();
      _journal = ((existante['journal'] as Map?)?['code'] ?? 'OD').toString();
      _date = DateTime.tryParse((existante['dateEcriture'] ?? '').toString())?.toUtc() ?? DateTime.now();
      for (final l in (existante['lignes'] as List? ?? [])) {
        final f = _LigneForm();
        final compte = l['compte'] as Map?;
        f.compteNumero = compte?['numero']?.toString();
        f.compte.text = compte == null ? '' : '${compte['numero']} - ${compte['libelle']}';
        if ((l['debit'] ?? 0) > 0) f.debit.text = '${l['debit']}';
        if ((l['credit'] ?? 0) > 0) f.credit.text = '${l['credit']}';
        f.libelle.text = (l['libelle'] ?? '').toString();
        _lignes.add(f);
      }
    }
    while (_lignes.length < 2) {
      _lignes.add(_LigneForm());
    }
  }

  @override
  void dispose() {
    _libelle.dispose();
    for (final l in _lignes) {
      l.dispose();
    }
    super.dispose();
  }

  int get _totalDebit => _lignes.fold(0, (s, l) => s + l.montantDebit);
  int get _totalCredit => _lignes.fold(0, (s, l) => s + l.montantCredit);
  int get _ecart => _totalDebit - _totalCredit;

  String get _dateApi => DateFormat('yyyy-MM-dd').format(_date);

  Map<String, dynamic> _donnees() => {
        'journalCode': _journal,
        'dateEcriture': _dateApi,
        'libelle': _libelle.text.trim(),
        'lignes': [
          for (final l in _lignes)
            if (l.compteNumero != null || l.montantDebit > 0 || l.montantCredit > 0)
              {
                'compteNumero': l.compteNumero,
                if (l.montantDebit > 0) 'debit': l.montantDebit,
                if (l.montantCredit > 0) 'credit': l.montantCredit,
                if (l.libelle.text.trim().isNotEmpty) 'libelle': l.libelle.text.trim(),
              }
        ],
      };

  Future<void> _enregistrer() async {
    setState(() => _enCours = true);
    final ok = await c.enregistrerEcriture(id: _id, donnees: _donnees());
    if (mounted) setState(() => _enCours = false);
    if (ok) Get.back();
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final equilibre = _ecart == 0 && _totalDebit > 0;
    final journauxSaisie = c.journaux.where((j) => j['type'] != 'a_nouveaux').toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_id == null ? 'compta_new_entry'.tr : 'compta_edit_entry'.tr),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: journauxSaisie.any((j) => j['code'] == _journal) ? _journal : null,
                decoration: InputDecoration(labelText: 'compta_journal'.tr, border: const OutlineInputBorder()),
                items: [
                  for (final j in journauxSaisie)
                    DropdownMenuItem(value: j['code'] as String, child: Text('${j['code']} - ${j['libelle']}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _journal = v ?? 'OD'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _choisirDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'compta_date'.tr, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
                  child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _libelle,
            decoration: InputDecoration(labelText: 'compta_label'.tr, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          Text('compta_lines'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _lignes.length; i++) _ligne(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _lignes.add(_LigneForm())),
              icon: const Icon(Icons.add),
              label: Text('compta_add_line'.tr),
            ),
          ),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${'compta_debit'.tr} : ${formatFcfa(_totalDebit)}'),
            Text('${'compta_credit'.tr} : ${formatFcfa(_totalCredit)}'),
          ]),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: equilibre ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(equilibre ? Icons.check_circle : Icons.warning_amber, color: equilibre ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(equilibre ? 'compta_balanced'.tr : '${'compta_unbalanced'.tr} : ${formatFcfa(_ecart.abs())} FCFA'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: equilibre && !_enCours ? _enregistrer : null,
            icon: _enCours ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text('compta_save_draft'.tr),
          ),
        ],
      ),
    );
  }

  Widget _ligne(int i) {
    final l = _lignes[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Autocomplete<Map<String, dynamic>>(
                initialValue: TextEditingValue(text: l.compte.text),
                displayStringForOption: libelleCompte,
                optionsBuilder: (v) {
                  final q = v.text.trim().toLowerCase();
                  if (q.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                  return c.comptes.where((x) => x['numero'].toString().startsWith(q) || x['libelle'].toString().toLowerCase().contains(q)).take(30);
                },
                onSelected: (o) => setState(() {
                  l.compteNumero = o['numero'].toString();
                  l.compte.text = libelleCompte(o);
                }),
                fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
                  controller: controller,
                  focusNode: focus,
                  decoration: InputDecoration(labelText: 'compta_account'.tr, border: const OutlineInputBorder(), isDense: true),
                  onChanged: (_) => l.compteNumero = null,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _lignes.length > 2 ? () => setState(() => _lignes.removeAt(i).dispose()) : null,
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: l.debit,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'compta_debit'.tr, border: const OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {
                  if (l.montantDebit > 0) l.credit.clear();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: l.credit,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'compta_credit'.tr, border: const OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {
                  if (l.montantCredit > 0) l.debit.clear();
                }),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

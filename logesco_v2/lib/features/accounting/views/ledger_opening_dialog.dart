import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_entry_form_page.dart';

class _SoldeOuverture {
  final String compte;
  final String libelleKey;
  final bool debit; // true : solde débiteur (actif), false : créditeur (passif)
  final TextEditingController montant = TextEditingController();
  _SoldeOuverture(this.compte, this.libelleKey, this.debit);
  int get valeur => int.tryParse(montant.text.replaceAll(' ', '')) ?? 0;
}

/// Assistant d'ouverture : date, régime fiscal et soldes de départ.
/// Un écart éventuel est versé sur un compte d'attente, à justifier ensuite.
class LedgerOpeningDialog extends StatefulWidget {
  const LedgerOpeningDialog({super.key});

  @override
  State<LedgerOpeningDialog> createState() => _LedgerOpeningDialogState();
}

class _LedgerOpeningDialogState extends State<LedgerOpeningDialog> {
  final c = Get.find<LedgerController>();
  DateTime _date = DateTime(DateTime.now().year, 1, 1);
  String _regime = 'normal';
  bool _enCours = false;

  final List<_SoldeOuverture> _soldes = [
    _SoldeOuverture('571', 'compta_open_cash', true),
    _SoldeOuverture('521', 'compta_open_bank', true),
    _SoldeOuverture('578', 'compta_open_mobile', true),
    _SoldeOuverture('31', 'compta_open_stock', true),
    _SoldeOuverture('411', 'compta_open_receivables', true),
    _SoldeOuverture('401', 'compta_open_payables', false),
    _SoldeOuverture('162', 'compta_open_loans', false),
    _SoldeOuverture('101', 'compta_open_capital', false),
  ];

  int get _debit => _soldes.where((s) => s.debit).fold(0, (a, s) => a + s.valeur);
  int get _credit => _soldes.where((s) => !s.debit).fold(0, (a, s) => a + s.valeur);

  @override
  void dispose() {
    for (final s in _soldes) {
      s.montant.dispose();
    }
    super.dispose();
  }

  Future<void> _valider() async {
    setState(() => _enCours = true);
    final ok = await c.enregistrerOuverture({
      'dateOuverture': DateFormat('yyyy-MM-dd').format(_date),
      'regime': _regime,
      'soldes': [
        for (final s in _soldes)
          if (s.valeur > 0) {'compteNumero': s.compte, s.debit ? 'debit' : 'credit': s.valeur},
      ],
    });
    if (mounted) setState(() => _enCours = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ecart = _debit - _credit;
    return AlertDialog(
      title: Text('compta_opening_title'.tr),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('compta_opening_help'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) setState(() => _date = d);
              },
              child: InputDecorator(
                decoration: InputDecoration(labelText: 'compta_opening_date'.tr, border: const OutlineInputBorder(), isDense: true),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _regime,
              decoration: InputDecoration(labelText: 'compta_regime'.tr, border: const OutlineInputBorder(), isDense: true),
              items: [
                DropdownMenuItem(value: 'normal', child: Text('compta_regime_normal'.tr)),
                DropdownMenuItem(value: 'smt', child: Text('compta_regime_smt'.tr)),
              ],
              onChanged: (v) => setState(() => _regime = v ?? 'normal'),
            ),
            const SizedBox(height: 14),
            for (final s in _soldes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: s.montant,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${s.libelleKey.tr} (${s.compte})',
                    suffixText: 'FCFA',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            if (ecart != 0)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.shade50,
                child: Text('${'compta_opening_gap'.tr} : ${formatFcfa(ecart.abs())} FCFA'),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr)),
        ElevatedButton(onPressed: _enCours ? null : _valider, child: Text('compta_opening_confirm'.tr)),
      ],
    );
  }
}

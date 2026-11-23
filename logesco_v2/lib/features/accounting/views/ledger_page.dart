import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_entry_form_page.dart';
import 'ledger_opening_dialog.dart';

String _jour(dynamic iso) {
  final d = DateTime.tryParse((iso ?? '').toString());
  return d == null ? '' : DateFormat('dd/MM/yyyy').format(d.toUtc());
}

/// Comptabilité en partie double : écritures, plan comptable, grand livre, balance, exercices.
class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('compta_title'.tr),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: c.refreshAll, tooltip: 'refresh'.tr),
            Obx(() => Row(children: [
                  Text('compta_this_shop'.tr, style: const TextStyle(fontSize: 12)),
                  Switch(
                    value: c.parBoutique.value,
                    activeColor: Colors.white,
                    onChanged: (v) {
                      c.parBoutique.value = v;
                      c.loadEcritures();
                    },
                  ),
                ])),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'compta_tab_entries'.tr),
              Tab(text: 'compta_tab_chart'.tr),
              Tab(text: 'compta_tab_ledger'.tr),
              Tab(text: 'compta_tab_balance'.tr),
              Tab(text: 'compta_tab_fiscal_years'.tr),
            ],
          ),
        ),
        body: Column(children: [
          Obx(() => c.isLoading.value ? const LinearProgressIndicator() : const SizedBox(height: 4)),
          Obx(() => c.ouvertureFaite
              ? const SizedBox.shrink()
              : MaterialBanner(
                  backgroundColor: Colors.orange.shade50,
                  content: Text('compta_opening_needed'.tr),
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  actions: [
                    TextButton(onPressed: () => showDialog(context: context, builder: (_) => const LedgerOpeningDialog()), child: Text('compta_opening_start'.tr)),
                  ],
                )),
          Expanded(
            child: TabBarView(children: [
              _EntriesTab(c),
              _ChartTab(c),
              _LedgerTab(c),
              _BalanceTab(c),
              _FiscalYearsTab(c),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────────── Écritures ─────────────────────────────
class _EntriesTab extends StatelessWidget {
  final LedgerController c;
  const _EntriesTab(this.c);

  Color _couleur(String s) => s == 'validee' ? Colors.green : (s == 'contrepassee' ? Colors.grey : Colors.orange);
  String _statut(String s) => s == 'validee' ? 'compta_status_validated'.tr : (s == 'contrepassee' ? 'compta_status_reversed'.tr : 'compta_status_draft'.tr);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Get.to(() => const LedgerEntryFormPage());
          c.loadEcritures();
        },
        icon: const Icon(Icons.add),
        label: Text('compta_new_entry'.tr),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Obx(() => Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: c.filtreJournal.value,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'compta_journal'.tr, isDense: true, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text('compta_all'.tr)),
                      for (final j in c.journaux) DropdownMenuItem<String?>(value: j['code'] as String, child: Text('${j['code']} - ${j['libelle']}', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      c.filtreJournal.value = v;
                      c.loadEcritures();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: c.filtreStatut.value,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'compta_status'.tr, isDense: true, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text('compta_all'.tr)),
                      DropdownMenuItem<String?>(value: 'brouillon', child: Text('compta_status_draft'.tr)),
                      DropdownMenuItem<String?>(value: 'validee', child: Text('compta_status_validated'.tr)),
                      DropdownMenuItem<String?>(value: 'contrepassee', child: Text('compta_status_reversed'.tr)),
                    ],
                    onChanged: (v) {
                      c.filtreStatut.value = v;
                      c.loadEcritures();
                    },
                  ),
                ),
              ])),
        ),
        Expanded(
          child: Obx(() {
            if (c.ecritures.isEmpty) return Center(child: Text('compta_no_entries'.tr));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: c.ecritures.length,
              itemBuilder: (_, i) {
                final e = c.ecritures[i];
                final lignes = List<Map<String, dynamic>>.from(e['lignes'] as List);
                final total = lignes.fold<int>(0, (s, l) => s + ((l['debit'] ?? 0) as num).toInt());
                final statut = e['statut'].toString();
                return Card(
                  child: ListTile(
                    onTap: () => _detail(context, e),
                    title: Text(e['libelle'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${e['numeroPiece'] ?? 'compta_no_number'.tr} · ${_jour(e['dateEcriture'])} · ${e['journal']['code']}'),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(formatFcfa(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_statut(statut), style: TextStyle(color: _couleur(statut), fontSize: 12)),
                    ]),
                  ),
                );
              },
            );
          }),
        ),
      ]),
    );
  }

  void _detail(BuildContext context, Map<String, dynamic> e) {
    final statut = e['statut'].toString();
    final lignes = List<Map<String, dynamic>>.from(e['lignes'] as List);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
          Text(e['libelle'].toString(), style: Theme.of(context).textTheme.titleMedium),
          Text('${e['numeroPiece'] ?? 'compta_no_number'.tr} · ${_jour(e['dateEcriture'])} · ${_statut(statut)}'),
          const Divider(),
          for (final l in lignes)
            ListTile(
              dense: true,
              title: Text(libelleCompte(Map<String, dynamic>.from(l['compte'] as Map))),
              subtitle: (l['libelle'] ?? '').toString().isEmpty ? null : Text(l['libelle'].toString()),
              trailing: Text(((l['debit'] ?? 0) as num) > 0 ? '${'compta_debit'.tr} ${formatFcfa(l['debit'] as num)}' : '${'compta_credit'.tr} ${formatFcfa(l['credit'] as num)}'),
            ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (statut == 'brouillon' && e['origine'] == 'manuelle') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text('compta_validate'.tr),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await c.valider(e['id'] as int);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text('edit'.tr),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Get.to(() => const LedgerEntryFormPage(), arguments: e);
                  c.loadEcritures();
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text('delete'.tr),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await c.supprimer(e['id'] as int);
                },
              ),
            ],
            if (statut == 'validee' && e['origine'] != 'contrepassation')
              OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                label: Text('compta_reverse'.tr),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final motif = await _demanderMotif(context);
                  if (motif != null) await c.contrepasser(e['id'] as int, motif: motif);
                },
              ),
          ]),
        ]),
      ),
    );
  }

  Future<String?> _demanderMotif(BuildContext context) {
    final t = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('compta_reverse'.tr),
        content: TextField(controller: t, decoration: InputDecoration(labelText: 'compta_reason'.tr)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, t.text.trim()), child: Text('confirm'.tr)),
        ],
      ),
    );
  }
}

// ───────────────────────────── Plan comptable ─────────────────────────────
class _ChartTab extends StatelessWidget {
  final LedgerController c;
  const _ChartTab(this.c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        onPressed: () => _ajouter(context),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: 'compta_search_account'.tr, border: const OutlineInputBorder(), isDense: true),
            onChanged: (v) => c.loadComptes(q: v.trim()),
          ),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: c.comptes.length,
                itemBuilder: (_, i) {
                  final x = c.comptes[i];
                  final niveau = (x['numero'].toString().length - 2).clamp(0, 4);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.only(left: 16.0 + niveau * 14, right: 16),
                    title: Text(libelleCompte(x), style: TextStyle(fontWeight: niveau == 0 ? FontWeight.bold : FontWeight.normal)),
                    trailing: x['systeme'] == true ? null : const Icon(Icons.person, size: 16),
                  );
                },
              )),
        ),
      ]),
    );
  }

  void _ajouter(BuildContext context) {
    final numero = TextEditingController();
    final libelle = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('compta_add_account'.tr),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: numero, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'compta_account_number'.tr)),
          TextField(controller: libelle, decoration: InputDecoration(labelText: 'compta_label'.tr)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              if (await c.creerCompte(numero.text.trim(), libelle.text.trim()) && ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Grand livre ─────────────────────────────
class _LedgerTab extends StatefulWidget {
  final LedgerController c;
  const _LedgerTab(this.c);

  @override
  State<_LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends State<_LedgerTab> {
  String? _compte;
  DateTimeRange? _periode;

  String? _fmt(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  Future<void> _charger() async {
    if (_compte == null) return;
    await widget.c.chargerGrandLivre(_compte!, dateDebut: _fmt(_periode?.start), dateFin: _fmt(_periode?.end));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: libelleCompte,
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                return c.comptes.where((x) => x['numero'].toString().startsWith(q) || x['libelle'].toString().toLowerCase().contains(q)).take(30);
              },
              onSelected: (o) {
                _compte = o['numero'].toString();
                _charger();
              },
              fieldViewBuilder: (context, controller, focus, _) => TextField(
                controller: controller,
                focusNode: focus,
                decoration: InputDecoration(labelText: 'compta_account'.tr, border: const OutlineInputBorder(), isDense: true),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final p = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: _periode);
              if (p != null) {
                setState(() => _periode = p);
                _charger();
              }
            },
          ),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final g = c.grandLivre.value;
          if (g == null) return Center(child: Text('compta_pick_account'.tr));
          final mouvements = List<Map<String, dynamic>>.from(g['mouvements'] as List);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${'compta_opening_balance'.tr} : ${formatFcfa(g['soldeDebut'] as num)}'),
                Text('${'compta_closing_balance'.tr} : ${formatFcfa(g['soldeFin'] as num)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(),
            Expanded(
              child: mouvements.isEmpty
                  ? Center(child: Text('compta_no_entries'.tr))
                  : ListView.builder(
                      itemCount: mouvements.length,
                      itemBuilder: (_, i) {
                        final m = mouvements[i];
                        return ListTile(
                          dense: true,
                          title: Text(m['libelle'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${_jour(m['date'])} · ${m['journal']} · ${m['numeroPiece'] ?? ''}${m['compteAuxiliaire'] != null ? ' · ${m['compteAuxiliaire']}' : ''}'),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(((m['debit'] as num) > 0) ? '+${formatFcfa(m['debit'] as num)}' : '-${formatFcfa(m['credit'] as num)}'),
                            Text(formatFcfa(m['solde'] as num), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                        );
                      },
                    ),
            ),
          ]);
        }),
      ),
    ]);
  }
}

// ───────────────────────────── Balance ─────────────────────────────
class _BalanceTab extends StatefulWidget {
  final LedgerController c;
  const _BalanceTab(this.c);

  @override
  State<_BalanceTab> createState() => _BalanceTabState();
}

class _BalanceTabState extends State<_BalanceTab> {
  DateTimeRange? _periode;

  String? _fmt(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  void _charger() => widget.c.chargerBalance(dateDebut: _fmt(_periode?.start), dateFin: _fmt(_periode?.end));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Text(_periode == null ? 'compta_whole_period'.tr : '${DateFormat('dd/MM/yyyy').format(_periode!.start)} → ${DateFormat('dd/MM/yyyy').format(_periode!.end)}')),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final p = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: _periode);
              if (p != null) {
                setState(() => _periode = p);
                _charger();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _charger),
        ]),
      ),
      Expanded(
        child: Obx(() {
          final b = c.balance.value;
          if (b == null) return const SizedBox.shrink();
          final lignes = List<Map<String, dynamic>>.from(b['lignes'] as List);
          final total = Map<String, dynamic>.from(b['total'] as Map);
          if (lignes.isEmpty) return Center(child: Text('compta_no_entries'.tr));
          return Column(children: [
            Expanded(
              child: ListView.builder(
                itemCount: lignes.length,
                itemBuilder: (_, i) {
                  final l = lignes[i];
                  return ListTile(
                    dense: true,
                    title: Text('${l['numero']} - ${l['libelle']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${'compta_debit'.tr} ${formatFcfa(l['debit'] as num)} · ${'compta_credit'.tr} ${formatFcfa(l['credit'] as num)}'),
                    trailing: Text(
                      (l['soldeDebiteur'] as num) > 0 ? 'D ${formatFcfa(l['soldeDebiteur'] as num)}' : 'C ${formatFcfa(l['soldeCrediteur'] as num)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: b['equilibree'] == true ? Colors.green.shade50 : Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${'compta_debit'.tr} ${formatFcfa(total['debit'] as num)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Icon(b['equilibree'] == true ? Icons.check_circle : Icons.error, color: b['equilibree'] == true ? Colors.green : Colors.red),
                Text('${'compta_credit'.tr} ${formatFcfa(total['credit'] as num)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ]);
        }),
      ),
    ]);
  }
}

// ───────────────────────────── Exercices et paramètres ─────────────────────────────
class _FiscalYearsTab extends StatelessWidget {
  final LedgerController c;
  const _FiscalYearsTab(this.c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        onPressed: () => _nouvelExercice(context),
        icon: const Icon(Icons.add),
        label: Text('compta_new_fiscal_year'.tr),
      ),
      body: Obx(() => ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('compta_settings'.tr, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: (c.parametres['regime'] ?? 'normal').toString(),
                    decoration: InputDecoration(labelText: 'compta_regime'.tr, border: const OutlineInputBorder(), isDense: true),
                    items: [
                      DropdownMenuItem(value: 'normal', child: Text('compta_regime_normal'.tr)),
                      DropdownMenuItem(value: 'smt', child: Text('compta_regime_smt'.tr)),
                    ],
                    onChanged: (v) => c.changerParametres({'regime': v}),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('compta_expert_mode'.tr),
                    value: c.modeExpert,
                    onChanged: (v) => c.changerParametres({'modeAffichage': v ? 'expert' : 'simple'}),
                  ),
                  if (!c.ouvertureFaite)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flag),
                      label: Text('compta_opening_start'.tr),
                      onPressed: () => showDialog(context: context, builder: (_) => const LedgerOpeningDialog()),
                    ),
                ]),
              ),
            ),
            _automatique(context),
            for (final ex in c.exercices) _exercice(context, ex),
          ])),
    );
  }

  Widget _automatique(BuildContext context) {
    final r = c.derniereGeneration.value;
    final erreurs = r == null ? <dynamic>[] : (r['erreurs'] as List? ?? []);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('compta_auto_title'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('compta_auto_help'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton.icon(
              icon: c.generationEnCours.value ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_fix_high),
              label: Text('compta_auto_run'.tr),
              onPressed: c.generationEnCours.value ? null : c.lancerGeneration,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.fact_check),
              label: Text('compta_controls'.tr),
              onPressed: () async {
                await c.chargerControles();
                if (context.mounted) _afficherControles(context);
              },
            ),
          ]),
          if (r != null) ...[
            const SizedBox(height: 8),
            Text('${'compta_auto_errors'.tr} : ${erreurs.length}', style: TextStyle(color: erreurs.isEmpty ? Colors.green : Colors.red)),
            for (final e in erreurs.take(5)) Text('• ${e['type']} #${e['id']} : ${e['message']}', style: const TextStyle(fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  void _afficherControles(BuildContext context) {
    final k = c.controles.value;
    if (k == null) return;
    final clients = List<Map<String, dynamic>>.from(k['clients'] as List);
    final fournisseurs = List<Map<String, dynamic>>.from(k['fournisseurs'] as List);
    final caisse = Map<String, dynamic>.from(k['caisse'] as Map);
    Widget ligne(String nom, Map<String, dynamic> x) => ListTile(
          dense: true,
          title: Text(nom),
          subtitle: Text('${'compta_controls_books'.tr} ${formatFcfa(x['comptabilite'] as num)} · ${'compta_controls_management'.tr} ${formatFcfa(x['gestion'] as num)}'),
          trailing: Text(formatFcfa(x['ecart'] as num), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('compta_controls'.tr),
        content: SizedBox(
          width: 460,
          child: ListView(shrinkWrap: true, children: [
            Text(k['coherent'] == true ? 'compta_controls_ok'.tr : 'compta_controls_ko'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: k['coherent'] == true ? Colors.green : Colors.orange)),
            const SizedBox(height: 8),
            if ((caisse['ecart'] as num) != 0) ligne('compta_controls_cash'.tr, caisse),
            for (final x in clients) ligne('${'compta_controls_customer'.tr} : ${x['nom']}', x),
            for (final x in fournisseurs) ligne('${'compta_controls_supplier'.tr} : ${x['nom']}', x),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('close'.tr))],
      ),
    );
  }

  Widget _exercice(BuildContext context, Map<String, dynamic> ex) {
    final periodes = List<Map<String, dynamic>>.from(ex['periodes'] as List);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ex['libelle'].toString(), style: Theme.of(context).textTheme.titleMedium),
          Text('${_jour(ex['dateDebut'])} → ${_jour(ex['dateFin'])} · ${ex['statut']}'),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in periodes)
              FilterChip(
                avatar: Icon(p['statut'] == 'verrouillee' ? Icons.lock : Icons.lock_open, size: 16),
                label: Text('${p['mois']}'),
                selected: p['statut'] == 'verrouillee',
                onSelected: ex['statut'] == 'ouvert' ? (v) => c.basculerPeriode(ex['id'] as int, p['mois'] as int, v) : null,
              ),
          ]),
        ]),
      ),
    );
  }

  void _nouvelExercice(BuildContext context) {
    final annee = DateTime.now().year;
    final libelle = TextEditingController(text: '${'compta_fiscal_year'.tr} $annee');
    final debut = TextEditingController(text: '$annee-01-01');
    final fin = TextEditingController(text: '$annee-12-31');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('compta_new_fiscal_year'.tr),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: libelle, decoration: InputDecoration(labelText: 'compta_label'.tr)),
          TextField(controller: debut, decoration: InputDecoration(labelText: 'compta_start_date'.tr, hintText: 'AAAA-MM-JJ')),
          TextField(controller: fin, decoration: InputDecoration(labelText: 'compta_end_date'.tr, hintText: 'AAAA-MM-JJ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              if (await c.creerExercice(libelle.text.trim(), debut.text.trim(), fin.text.trim()) && ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}

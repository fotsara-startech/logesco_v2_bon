import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../models/account.dart';
import '../services/account_api_service.dart';
import '../services/account_service.dart';
import '../../customers/models/customer.dart';
import '../../../core/routes/app_routes.dart';

// ─── Intervalles d'alerte ──────────────────────────────────────────────────

enum DebtInterval { recent, warning, urgent, critical }

extension DebtIntervalX on DebtInterval {
  String get label {
    switch (this) {
      case DebtInterval.recent:
        return '< 10 jours';
      case DebtInterval.warning:
        return '10 – 20 jours';
      case DebtInterval.urgent:
        return '20 – 30 jours';
      case DebtInterval.critical:
        return '> 30 jours';
    }
  }

  Color get color {
    switch (this) {
      case DebtInterval.recent:
        return Colors.blue;
      case DebtInterval.warning:
        return Colors.orange;
      case DebtInterval.urgent:
        return Colors.deepOrange;
      case DebtInterval.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case DebtInterval.recent:
        return Icons.info_outline;
      case DebtInterval.warning:
        return Icons.warning_amber_rounded;
      case DebtInterval.urgent:
        return Icons.warning_rounded;
      case DebtInterval.critical:
        return Icons.error_rounded;
    }
  }

  static DebtInterval fromDays(int days) {
    if (days < 10) return DebtInterval.recent;
    if (days < 20) return DebtInterval.warning;
    if (days <= 30) return DebtInterval.urgent;
    return DebtInterval.critical;
  }
}

// ─── Modèle enrichi ────────────────────────────────────────────────────────

class _EnrichedSale {
  final CompteClient compte;
  final UnpaidSale sale;
  final int anciennete;
  final DebtInterval interval;

  _EnrichedSale({required this.compte, required this.sale})
      : anciennete = DateTime.now().difference(sale.dateVente).inDays,
        interval = DebtIntervalX.fromDays(
          DateTime.now().difference(sale.dateVente).inDays,
        );
}

// ─── Page principale ───────────────────────────────────────────────────────

class DebtAlertsPage extends StatefulWidget {
  const DebtAlertsPage({super.key});

  @override
  State<DebtAlertsPage> createState() => _DebtAlertsPageState();
}

class _DebtAlertsPageState extends State<DebtAlertsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late AccountController _accountCtrl;
  late AccountApiService _apiService;

  final List<_EnrichedSale> _all = [];
  bool _loading = true;
  String? _error;
  DebtInterval? _filter; // null = tous

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {
          _filter = _tabs.index == 0 ? null : DebtInterval.values[_tabs.index - 1];
        });
      }
    });

    // Récupération robuste des services — sans instancier si absent (évite onInit prématuré)
    _accountCtrl = Get.isRegistered<AccountController>() ? Get.find<AccountController>() : Get.put(AccountController(), permanent: false);

    _apiService = Get.isRegistered<AccountService>() ? Get.find<AccountService>() as AccountApiService : AccountApiService();

    // Différer le chargement après le premier frame pour garantir l'Overlay monté
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Chargement ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _accountCtrl.loadComptesClients(refresh: true);

      // soldeActuel < 0 = dette (le backend utilise un solde négatif pour les dettes)
      // On prend aussi soldeActuel > 0 au cas où certains backends inversent la convention
      final comptes = _accountCtrl.comptesClients.where((c) => c.soldeActuel != 0).toList();

      final enriched = <_EnrichedSale>[];
      for (final c in comptes) {
        try {
          // Tentative 1 : endpoint unpaid-sales (montantRestant > 0 sur la table vente)
          List<UnpaidSale> sales = await _apiService.getUnpaidSales(c.clientId);

          // Fallback : si rien retourné, reconstruire depuis les transactions à crédit
          if (sales.isEmpty) {
            final transactions = await _apiService.getTransactionsClient(c.clientId);
            final creditTxs = transactions
                .where(
                  (t) => t.typeTransaction == 'debit' || t.typeTransactionDetail == 'vente_credit' || t.typeTransactionDetail == 'achat_credit' || (t.typeTransaction == 'achat' && t.venteId != null),
                )
                .toList();

            final seen = <int>{};
            for (final tx in creditTxs) {
              if (tx.venteId != null && !seen.contains(tx.venteId)) {
                seen.add(tx.venteId!);
                sales.add(UnpaidSale(
                  id: tx.venteId!,
                  reference: tx.venteReference ?? '#${tx.venteId}',
                  dateVente: tx.dateTransaction,
                  montantTotal: tx.montant,
                  montantPaye: 0,
                  montantRestant: tx.montant,
                  nombreArticles: 0,
                ));
              }
            }
          }

          for (final s in sales) {
            enriched.add(_EnrichedSale(compte: c, sale: s));
          }
        } catch (_) {
          // on continue pour les autres clients
        }
      }

      enriched.sort((a, b) => b.anciennete.compareTo(a.anciennete));

      setState(() {
        _all
          ..clear()
          ..addAll(enriched);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<_EnrichedSale> get _filtered => _filter == null ? _all : _all.where((d) => d.interval == _filter).toList();

  int _count(DebtInterval? iv) => iv == null ? _all.length : _all.where((d) => d.interval == iv).length;

  void _goToTransactions(CompteClient compte) {
    final customer = Customer(
      id: compte.clientId,
      nom: compte.client.nom,
      prenom: compte.client.prenom,
      telephone: compte.client.telephone,
      email: compte.client.email,
      dateCreation: DateTime.now(),
      dateModification: DateTime.now(),
    );
    Get.toNamed(AppRoutes.customerTransactions, arguments: customer);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Alertes dettes clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildTabStrip(),
                    _buildSummary(),
                    Expanded(
                      child: _filtered.isEmpty ? _buildEmpty() : _buildList(),
                    ),
                  ],
                ),
    );
  }

  // ── TabStrip horizontal scrollable ───────────────────────────────────────

  Widget _buildTabStrip() {
    const tabs = [null, ...DebtInterval.values];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final iv = tabs[i];
            final isActive = _filter == iv;
            final count = _count(iv);
            final color = iv?.color ?? const Color(0xFF1565C0);
            final label = iv == null ? 'Tous' : iv.label;
            return GestureDetector(
              onTap: () {
                _tabs.animateTo(i);
                setState(() => _filter = iv);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? color : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iv != null) ...[
                      Icon(iv.icon, size: 14, color: isActive ? Colors.white : color),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Barre de résumé ───────────────────────────────────────────────────────

  Widget _buildSummary() {
    final data = _filtered;
    final totalDu = data.fold<double>(0, (s, d) => s + d.sale.montantRestant);
    final clients = data.map((d) => d.compte.clientId).toSet().length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.receipt_long, size: 15, color: Colors.blue.shade600),
          const SizedBox(width: 4),
          Text('${data.length} vente${data.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Icon(Icons.people, size: 15, color: Colors.purple.shade600),
          const SizedBox(width: 4),
          Text('$clients client${clients > 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Total dû : ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            '${totalDu.toStringAsFixed(0)} FCFA',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // ── Liste groupée par client ───────────────────────────────────────────────

  Widget _buildList() {
    final byClient = <int, List<_EnrichedSale>>{};
    for (final d in _filtered) {
      byClient.putIfAbsent(d.compte.clientId, () => []).add(d);
    }
    final keys = byClient.keys.toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: keys.length,
        itemBuilder: (ctx, i) {
          final debts = byClient[keys[i]]!;
          return _ClientCard(
            compte: debts.first.compte,
            debts: debts,
            onGoToAccount: () => _goToTransactions(debts.first.compte),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              _filter == null ? 'Aucune dette en cours' : 'Aucune dette dans cet intervalle',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
}

// ─── Carte client ──────────────────────────────────────────────────────────

class _ClientCard extends StatefulWidget {
  final CompteClient compte;
  final List<_EnrichedSale> debts;
  final VoidCallback onGoToAccount;

  const _ClientCard({
    required this.compte,
    required this.debts,
    required this.onGoToAccount,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> {
  bool _expanded = true;

  DebtInterval get _worst => widget.debts.map((d) => d.interval).reduce((a, b) => a.index > b.index ? a : b);

  double get _totalDu => widget.debts.fold(0, (s, d) => s + d.sale.montantRestant);

  @override
  Widget build(BuildContext context) {
    final iv = _worst;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iv.color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // En-tête client
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: iv.color.withValues(alpha: 0.15),
                    child: Text(
                      widget.compte.client.nom[0].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: iv.color, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.compte.client.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (widget.compte.client.telephone != null) Text(widget.compte.client.telephone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  _Badge(iv: iv),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Sous-ligne résumé + bouton paiement
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${widget.debts.length} vente${widget.debts.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.payments_outlined, size: 13, color: Colors.red.shade400),
                const SizedBox(width: 4),
                Text(
                  '${_totalDu.toStringAsFixed(0)} FCFA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: widget.onGoToAccount,
                  icon: const Icon(Icons.payment, size: 15),
                  label: const Text('Paiement', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iv.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Détail des ventes impayées
          if (_expanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: widget.debts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _SaleRow(debt: widget.debts[i]),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Ligne vente impayée ───────────────────────────────────────────────────

class _SaleRow extends StatelessWidget {
  final _EnrichedSale debt;
  const _SaleRow({required this.debt});

  @override
  Widget build(BuildContext context) {
    final iv = debt.interval;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iv.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iv.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro vente + badge ancienneté
          Row(
            children: [
              Icon(Icons.receipt, size: 14, color: iv.color),
              const SizedBox(width: 6),
              Text('Vente #${debt.sale.reference}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              _Badge(iv: iv, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          // Infos en grille 2 colonnes
          Row(
            children: [
              _Cell(label: 'Date', value: debt.sale.dateVenteFormatted),
              const SizedBox(width: 16),
              _Cell(label: 'Ancienneté', value: '${debt.anciennete} jour${debt.anciennete > 1 ? 's' : ''}', valueColor: iv.color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Cell(label: 'Total', value: debt.sale.montantTotalFormatted),
              const SizedBox(width: 16),
              _Cell(label: 'Payé', value: debt.sale.montantPayeFormatted, valueColor: Colors.green.shade700),
              const SizedBox(width: 16),
              _Cell(label: 'Reste dû', value: debt.sale.montantRestantFormatted, valueColor: Colors.red, bold: true),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${debt.sale.nombreArticles} article${debt.sale.nombreArticles > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets utilitaires ───────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final DebtInterval iv;
  final bool compact;
  const _Badge({required this.iv, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: iv.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iv.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iv.icon, size: compact ? 11 : 13, color: iv.color),
          const SizedBox(width: 3),
          Text(
            iv.label,
            style: TextStyle(fontSize: compact ? 10 : 11, color: iv.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _Cell({required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

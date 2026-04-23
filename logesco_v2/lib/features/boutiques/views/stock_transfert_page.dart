import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/boutique_controller.dart';
import '../models/boutique_model.dart';
import '../models/stock_transfert_model.dart';
import '../services/boutique_service.dart';

class StockTransfertPage extends StatefulWidget {
  const StockTransfertPage({super.key});

  @override
  State<StockTransfertPage> createState() => _StockTransfertPageState();
}

class _StockTransfertPageState extends State<StockTransfertPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _controller = Get.find<BoutiqueController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.loadTransferts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferts de stock'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.swap_horiz), text: 'Nouveau transfert'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TransfertForm(controller: _controller),
          _TransfertHistory(controller: _controller),
        ],
      ),
    );
  }
}

// ─── Formulaire de transfert ─────────────────────────────────────────────────

class _TransfertForm extends StatefulWidget {
  final BoutiqueController controller;
  const _TransfertForm({required this.controller});

  @override
  State<_TransfertForm> createState() => _TransfertFormState();
}

class _TransfertFormState extends State<_TransfertForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Boutique? _source;
  Boutique? _destination;
  Map<String, dynamic>? _selectedProduit;
  List<Map<String, dynamic>> _stockSource = [];
  bool _loadingStock = false;

  @override
  void dispose() {
    _quantiteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStockSource(Boutique boutique) async {
    setState(() {
      _loadingStock = true;
      _stockSource = [];
      _selectedProduit = null;
    });
    try {
      final service = Get.find<BoutiqueService>();
      final data = await service.getBoutiqueStock(boutique.id);
      final stocks = data['stocks'] as List<dynamic>? ?? [];
      setState(() {
        _stockSource = stocks.map((s) => s as Map<String, dynamic>).where((s) => (s['quantiteDisponible'] as int? ?? 0) > 0).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement stock: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingStock = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_source == null || _destination == null || _selectedProduit == null) return;

    final produitId = _selectedProduit!['produitId'] as int? ?? (_selectedProduit!['produit'] as Map<String, dynamic>?)?['id'] as int?;
    if (produitId == null) return;

    final result = await widget.controller.createTransfert(
      sourceBoutiqueId: _source!.id,
      destBoutiqueId: _destination!.id,
      produitId: produitId,
      quantite: int.parse(_quantiteCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfert effectué avec succès'), backgroundColor: Colors.green),
      );
      _formKey.currentState!.reset();
      _quantiteCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _source = null;
        _destination = null;
        _selectedProduit = null;
        _stockSource = [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage.value.isNotEmpty ? widget.controller.errorMessage.value : 'Erreur lors du transfert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final boutiques = widget.controller.boutiques.where((b) => b.isActive).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boutique source
              _SectionTitle(title: 'Boutique source', icon: Icons.store),
              const SizedBox(height: 8),
              DropdownButtonFormField<Boutique>(
                value: _source,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner la boutique source',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(),
                ),
                items: boutiques.map((b) => DropdownMenuItem(value: b, child: Text(b.nom))).toList(),
                onChanged: (b) {
                  setState(() {
                    _source = b;
                    if (_destination?.id == b?.id) _destination = null;
                  });
                  if (b != null) _loadStockSource(b);
                },
                validator: (v) => v == null ? 'Requis' : null,
              ),

              const SizedBox(height: 20),

              // Boutique destination
              _SectionTitle(title: 'Boutique destination', icon: Icons.store_mall_directory),
              const SizedBox(height: 8),
              DropdownButtonFormField<Boutique>(
                value: _destination,
                decoration: const InputDecoration(
                  labelText: 'Sélectionner la boutique destination',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(),
                ),
                items: boutiques.where((b) => b.id != _source?.id).map((b) => DropdownMenuItem(value: b, child: Text(b.nom))).toList(),
                onChanged: (b) => setState(() => _destination = b),
                validator: (v) => v == null ? 'Requis' : null,
              ),

              const SizedBox(height: 20),

              // Produit
              _SectionTitle(title: 'Produit à transférer', icon: Icons.inventory_2),
              const SizedBox(height: 8),
              if (_loadingStock)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (_source == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Sélectionnez d\'abord la boutique source', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else if (_stockSource.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Aucun stock disponible dans cette boutique', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedProduit,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un produit',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  items: _stockSource.map((s) {
                    final produit = s['produit'] as Map<String, dynamic>?;
                    final nom = produit?['nom'] as String? ?? 'Produit #${s['produitId']}';
                    final dispo = s['quantiteDisponible'] as int? ?? 0;
                    return DropdownMenuItem(
                      value: s,
                      child: Text('$nom (dispo: $dispo)'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedProduit = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),

              const SizedBox(height: 20),

              // Quantité
              _SectionTitle(title: 'Quantité', icon: Icons.numbers),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantiteCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité à transférer',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Quantité invalide';
                  if (_selectedProduit != null) {
                    final dispo = _selectedProduit!['quantiteDisponible'] as int? ?? 0;
                    if (n > dispo) return 'Stock insuffisant (max: $dispo)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Bouton
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.controller.isTransferLoading.value ? null : _submit,
                      icon: widget.controller.isTransferLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.swap_horiz),
                      label: const Text('Effectuer le transfert', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Historique des transferts ───────────────────────────────────────────────

class _TransfertHistory extends StatelessWidget {
  final BoutiqueController controller;
  const _TransfertHistory({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isTransferLoading.value && controller.transferts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.transferts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucun transfert effectué', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.loadTransferts(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.transferts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _TransfertCard(transfert: controller.transferts[i]),
        ),
      );
    });
  }
}

class _TransfertCard extends StatelessWidget {
  final StockTransfert transfert;
  const _TransfertCard({required this.transfert});

  @override
  Widget build(BuildContext context) {
    final srcNom = transfert.sourceBoutique?['nom'] as String? ?? '#${transfert.sourceBoutiqueId}';
    final dstNom = transfert.destBoutique?['nom'] as String? ?? '#${transfert.destBoutiqueId}';
    final produitNom = transfert.produit?['nom'] as String? ?? 'Produit #${transfert.produitId}';
    final userNom = transfert.utilisateur?['nomUtilisateur'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(transfert.reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  '${transfert.dateTransfert.day}/${transfert.dateTransfert.month}/${transfert.dateTransfert.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BoutiqueChip(nom: srcNom, isSource: true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
                ),
                Expanded(
                  child: _BoutiqueChip(nom: dstNom, isSource: false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(produitNom, style: const TextStyle(fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${transfert.quantite} unités', style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (userNom.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(userNom, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
            if (transfert.notes != null && transfert.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(transfert.notes!, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoutiqueChip extends StatelessWidget {
  final String nom;
  final bool isSource;
  const _BoutiqueChip({required this.nom, required this.isSource});

  @override
  Widget build(BuildContext context) {
    final color = isSource ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSource ? Icons.upload : Icons.download, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(child: Text(nom, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }
}

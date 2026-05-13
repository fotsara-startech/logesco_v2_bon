import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';

/// Dialog pour filtrer par catégorie avec barre de recherche
class CategoryFilterDialog extends StatefulWidget {
  const CategoryFilterDialog({super.key});

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  late InventoryGetxController _controller;
  List<String> _filtered = [];
  String _selected = '';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<InventoryGetxController>();
    _selected = _controller.selectedCategory.value;
    _filtered = _controller.categories.toList();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _controller.categories.toList() : _controller.categories.where((c) => c.toLowerCase().contains(q)).toList();
    });
  }

  void _select(String value) {
    setState(() => _selected = value);
    _controller.updateSelectedCategory(value);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('stock_category_filter_title'.tr),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const Divider(height: 1),

            // Option "Toutes les catégories"
            ListTile(
              dense: true,
              title: Text('stock_category_all'.tr),
              leading: Radio<String>(
                value: '',
                groupValue: _selected,
                onChanged: (v) => _select(v ?? ''),
              ),
              onTap: () => _select(''),
            ),
            const Divider(height: 1),

            // Liste filtrée
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'stock_category_empty'.tr,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final cat = _filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(cat),
                          leading: Radio<String>(
                            value: cat,
                            groupValue: _selected,
                            onChanged: (v) => _select(v ?? ''),
                          ),
                          onTap: () => _select(cat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('stock_close'.tr),
        ),
      ],
    );
  }
}

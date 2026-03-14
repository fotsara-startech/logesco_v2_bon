import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/financial_movement_controller.dart';
import '../models/movement_category.dart';

/// Widget de filtres pour les mouvements financiers
class MovementFilters extends StatefulWidget {
  final FinancialMovementController controller;

  const MovementFilters({
    super.key,
    required this.controller,
  });

  @override
  State<MovementFilters> createState() => _MovementFiltersState();
}

class _MovementFiltersState extends State<MovementFilters> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();

    // Initialise les contrôleurs avec les valeurs actuelles
    _minAmountController = TextEditingController(
      text: widget.controller.minAmount.value?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: widget.controller.maxAmount.value?.toString() ?? '',
    );
    _selectedStartDate = widget.controller.startDate.value;
    _selectedEndDate = widget.controller.endDate.value;
    _selectedCategoryId = widget.controller.selectedCategoryId.value;
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Text(
                  'financial_movements_filters'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Bouton presets
                IconButton(
                  onPressed: _showPresets,
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'financial_movements_filter_presets'.tr,
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text('financial_movements_filter_reset'.tr),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Presets rapides
            _buildQuickPresets(),

            const SizedBox(height: 16),

            // Recherche avancée
            _buildAdvancedSearch(),

            const SizedBox(height: 16),

            // Filtres rapides par période
            _buildQuickPeriodFilters(),

            const SizedBox(height: 16),

            // Sélection de catégorie
            _buildCategoryFilter(),

            const SizedBox(height: 16),

            // Plage de dates personnalisée
            _buildDateRangeFilter(),

            const SizedBox(height: 16),

            // Plage de montants
            _buildAmountRangeFilter(),

            const SizedBox(height: 16),

            // Suggestions intelligentes
            _buildSmartSuggestions(),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveAsPreset,
                    child: Text('financial_movements_filter_save'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: Text('financial_movements_filter_apply'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPeriodFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'financial_movements_filter_period'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPeriodChip('financial_movements_filter_today'.tr, 'today'),
            _buildPeriodChip('financial_movements_filter_yesterday'.tr, 'yesterday'),
            _buildPeriodChip('financial_movements_filter_this_week'.tr, 'this_week'),
            _buildPeriodChip('financial_movements_filter_last_week'.tr, 'last_week'),
            _buildPeriodChip('financial_movements_filter_this_month'.tr, 'this_month'),
            _buildPeriodChip('financial_movements_filter_last_month'.tr, 'last_month'),
            _buildPeriodChip('financial_movements_filter_this_year'.tr, 'this_year'),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    return FilterChip(
      label: Text(label),
      selected: _isPeriodSelected(period),
      onSelected: (selected) {
        if (selected) {
          _selectPredefinedPeriod(period);
        } else {
          _clearDateRange();
        }
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'financial_movements_category'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text('common_all'.tr),
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                ),
                ...widget.controller.categories.map((category) => FilterChip(
                      label: Text(category.displayName),
                      selected: _selectedCategoryId == category.id,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? category.id : null;
                        });
                      },
                      avatar: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )),
              ],
            )),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'financial_movements_filter_date_range'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'financial_movements_filter_start_date'.tr,
                date: _selectedStartDate,
                onTap: () => _selectStartDate(),
                onClear: () => _selectedStartDate = null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'financial_movements_filter_end_date'.tr,
                date: _selectedEndDate,
                onTap: () => _selectEndDate(),
                onClear: () => _selectedEndDate = null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: date != null
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      onClear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? _formatDate(date) : 'financial_movements_filter_select'.tr,
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'financial_movements_filter_amount_range'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'financial_movements_filter_min_amount'.tr,
                  border: const OutlineInputBorder(),
                  suffixText: 'FCFA',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'financial_movements_filter_max_amount'.tr,
                  border: const OutlineInputBorder(),
                  suffixText: 'FCFA',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isPeriodSelected(String period) {
    final now = DateTime.now();
    DateTime? expectedStart;
    DateTime? expectedEnd;

    switch (period) {
      case 'today':
        expectedStart = DateTime(now.year, now.month, now.day);
        expectedEnd = now;
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        expectedStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
        expectedEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'this_week':
        expectedStart = now.subtract(Duration(days: now.weekday - 1));
        expectedStart = DateTime(expectedStart.year, expectedStart.month, expectedStart.day);
        expectedEnd = now;
        break;
      case 'this_month':
        expectedStart = DateTime(now.year, now.month, 1);
        expectedEnd = now;
        break;
      default:
        return false;
    }

    return _selectedStartDate != null && _selectedEndDate != null && _isSameDay(_selectedStartDate!, expectedStart) && _isSameDay(_selectedEndDate!, expectedEnd);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _selectPredefinedPeriod(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'today':
        setState(() {
          _selectedStartDate = DateTime(now.year, now.month, now.day);
          _selectedEndDate = now;
        });
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        setState(() {
          _selectedStartDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _selectedEndDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        });
        break;
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        setState(() {
          _selectedStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          _selectedEndDate = now;
        });
        break;
      case 'last_week':
        final lastWeekEnd = now.subtract(Duration(days: now.weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        setState(() {
          _selectedStartDate = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
          _selectedEndDate = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59);
        });
        break;
      case 'this_month':
        setState(() {
          _selectedStartDate = DateTime(now.year, now.month, 1);
          _selectedEndDate = now;
        });
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        setState(() {
          _selectedStartDate = lastMonth;
          _selectedEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        });
        break;
      case 'this_year':
        setState(() {
          _selectedStartDate = DateTime(now.year, 1, 1);
          _selectedEndDate = now;
        });
        break;
      case 'last_year':
        setState(() {
          _selectedStartDate = DateTime(now.year - 1, 1, 1);
          _selectedEndDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        });
        break;
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedStartDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedEndDate = date;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedCategoryId = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    // Parse les montants
    double? minAmount;
    double? maxAmount;

    if (_minAmountController.text.isNotEmpty) {
      minAmount = double.tryParse(_minAmountController.text);
    }

    if (_maxAmountController.text.isNotEmpty) {
      maxAmount = double.tryParse(_maxAmountController.text);
    }

    // Gère la recherche avancée
    if (_hasAdvancedSearch()) {
      widget.controller.advancedSearch(
        description: _advancedSearchDescription,
        reference: _advancedSearchReference,
        notes: _advancedSearchNotes,
        userName: _advancedSearchUser,
      );
    }

    // Applique les filtres
    widget.controller.applyAdvancedFilters(
      categoryId: _selectedCategoryId,
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );

    // Ferme le bottom sheet
    Navigator.of(context).pop();
  }

  bool _hasAdvancedSearch() {
    return (_advancedSearchDescription?.isNotEmpty ?? false) ||
        (_advancedSearchReference?.isNotEmpty ?? false) ||
        (_advancedSearchNotes?.isNotEmpty ?? false) ||
        (_advancedSearchUser?.isNotEmpty ?? false);
  }

  Color _getCategoryColor(MovementCategory category) {
    try {
      return Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildQuickPresets() {
    return Obx(() {
      final presets = widget.controller.defaultPresets;
      if (presets.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'financial_movements_filter_quick'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets
                .map((preset) => ActionChip(
                      label: Text(preset.name.tr),
                      onPressed: () => _applyPreset(preset),
                      backgroundColor: _isPresetActive(preset) ? Colors.blue.shade100 : null,
                    ))
                .toList(),
          ),
        ],
      );
    });
  }

  Widget _buildAdvancedSearch() {
    return ExpansionTile(
      title: Text(
        'financial_movements_filter_advanced'.tr,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'financial_movements_description'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                onChanged: (value) => _advancedSearchDescription = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'financial_movements_reference'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tag),
                ),
                onChanged: (value) => _advancedSearchReference = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'financial_movements_notes'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.note),
                ),
                onChanged: (value) => _advancedSearchNotes = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'users_username'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                onChanged: (value) => _advancedSearchUser = value,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSuggestions() {
    return Obx(() {
      final suggestions = widget.controller.filterSuggestions;
      if (suggestions.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'financial_movements_filter_suggestions'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestions.map((suggestion) => Card(
                child: ListTile(
                  leading: Icon(
                    suggestion['type'] == 'category' ? Icons.category : Icons.trending_up,
                    color: Colors.blue,
                  ),
                  title: Text(suggestion['title']),
                  subtitle: Text(suggestion['description']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    suggestion['action']();
                    Navigator.of(context).pop();
                  },
                ),
              )),
        ],
      );
    });
  }

  bool _isPresetActive(preset) {
    return widget.controller.currentMatchingPreset?.id == preset.id;
  }

  void _applyPreset(preset) async {
    await widget.controller.applyFilterPreset(preset);
    Navigator.of(context).pop();
  }

  void _showPresets() {
    showDialog(
      context: context,
      builder: (context) => _PresetManagerDialog(controller: widget.controller),
    );
  }

  void _saveAsPreset() {
    showDialog(
      context: context,
      builder: (context) => _SavePresetDialog(
        onSave: (name, description) async {
          await widget.controller.saveCurrentFiltersAsPreset(name, description: description);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Variables pour la recherche avancée
  String? _advancedSearchDescription;
  String? _advancedSearchReference;
  String? _advancedSearchNotes;
  String? _advancedSearchUser;
}

/// Dialog pour gérer les presets sauvegardés
class _PresetManagerDialog extends StatelessWidget {
  final FinancialMovementController controller;

  const _PresetManagerDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('financial_movements_filter_presets'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: Obx(() {
          final customPresets = controller.customPresets;

          if (customPresets.isEmpty) {
            return Text('financial_movements_filter_no_presets'.tr);
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: customPresets.length,
            itemBuilder: (context, index) {
              final preset = customPresets[index];
              return ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.filtersSummary),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await controller.applyFilterPreset(preset);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Ferme aussi le dialog des filtres
                      },
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'common_apply'.tr,
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(context, preset),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'common_delete'.tr,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common_close'.tr),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('financial_movements_filter_delete'.tr),
        content: Text('financial_movements_filter_delete_confirm'.tr.replaceAll('@name', preset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.deleteFilterPreset(preset.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common_delete'.tr),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour sauvegarder un nouveau preset
class _SavePresetDialog extends StatefulWidget {
  final Function(String name, String? description) onSave;

  const _SavePresetDialog({required this.onSave});

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('financial_movements_filter_save'.tr),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'financial_movements_filter_preset_name'.tr,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'financial_movements_filter_name_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'financial_movements_filter_description'.tr,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameController.text.trim(),
                _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
              );
            }
          },
          child: Text('common_save'.tr),
        ),
      ],
    );
  }
}

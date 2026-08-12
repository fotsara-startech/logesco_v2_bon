import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../core/services/database_service.dart';

class ExpenseFormPage extends StatefulWidget {
  final String? expenseId;

  const ExpenseFormPage({super.key, this.expenseId});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;

  ExpenseCategory _selectedCategory = ExpenseCategory.advertising;
  DateTime _expenseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _isEditMode = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _otherCategoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expense = await DatabaseService.instance.getExpense(widget.expenseId!);
      if (expense != null) {
        setState(() {
          _selectedCategory = expense.category;
          _otherCategoryController.text = expense.otherCategoryLabel ?? '';
          _amountController.text = expense.amount.toString();
          _expenseDate = expense.expenseDate;
          _notesController.text = expense.notes ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la dépense' : 'Nouvelle dépense'),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie de dépense',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ExpenseCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(expenseCategoryLabel(category)),
                      );
                    }).toList(),
                    onChanged: (category) {
                      setState(() => _selectedCategory = category!);
                    },
                  ),
                  if (_selectedCategory == ExpenseCategory.other) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otherCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Précisez la catégorie',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      validator: (value) {
                        if (_selectedCategory == ExpenseCategory.other && (value == null || value.trim().isEmpty)) {
                          return 'Précisez la catégorie de dépense';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant et date', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Montant',
                      prefixIcon: Icon(Icons.money_off),
                      suffixText: 'XAF',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Saisissez un montant';
                      if (double.tryParse(value) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date de la dépense'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_expenseDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectExpenseDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes additionnelles',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _saveExpense,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Mettre à jour' : 'Enregistrer la dépense'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final expense = Expense(
        id: widget.expenseId ?? const Uuid().v4(),
        category: _selectedCategory,
        otherCategoryLabel: _selectedCategory == ExpenseCategory.other ? _otherCategoryController.text.trim() : null,
        amount: double.parse(_amountController.text),
        expenseDate: _expenseDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await DatabaseService.instance.updateExpense(expense);
      } else {
        await DatabaseService.instance.insertExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Dépense mise à jour' : 'Dépense enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

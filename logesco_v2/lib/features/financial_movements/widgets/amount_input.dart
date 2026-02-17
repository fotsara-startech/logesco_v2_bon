import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de saisie de montant formaté pour les mouvements financiers
class AmountInput extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String currency;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const AmountInput({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.currency = 'FCFA',
    this.isRequired = false,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        _AmountInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: widget.labelText != null ? '${widget.labelText}${widget.isRequired ? ' *' : ''}' : null,
        hintText: widget.hintText,
        suffixText: widget.currency,
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      ),
      validator: widget.validator ?? (widget.isRequired ? _defaultValidator : null),
      onChanged: widget.onChanged,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le montant est obligatoire';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Veuillez entrer un montant valide';
    }
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    return null;
  }
}

/// Formateur pour les montants avec séparateurs de milliers
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permet seulement les chiffres et un point décimal
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Vérifie le format de base
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    // Limite à 2 décimales maximum
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length > 2)) {
        return oldValue;
      }
    }

    return newValue;
  }
}

/// Utilitaires pour le formatage des montants
class AmountFormatter {
  /// Formate un montant avec séparateurs de milliers
  static String formatAmount(double amount, {String currency = 'FCFA'}) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');

    // Ajoute les séparateurs de milliers
    final integerPart = parts[0];
    final decimalPart = parts[1];

    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ' ';
      }
      formattedInteger += integerPart[i];
    }

    // Supprime les zéros inutiles dans la partie décimale
    String finalDecimal = decimalPart;
    if (finalDecimal == '00') {
      return '$formattedInteger $currency';
    } else if (finalDecimal.endsWith('0')) {
      finalDecimal = finalDecimal.substring(0, 1);
    }

    return '$formattedInteger,$finalDecimal $currency';
  }

  /// Parse un montant depuis une chaîne formatée
  static double? parseAmount(String text) {
    if (text.isEmpty) return null;

    // Supprime les espaces et la devise
    String cleanText = text.replaceAll(' ', '').replaceAll('FCFA', '').replaceAll(',', '.').trim();

    return double.tryParse(cleanText);
  }

  /// Valide un montant
  static String? validateAmount(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Le montant est obligatoire' : null;
    }

    final amount = parseAmount(value);
    if (amount == null) {
      return 'Veuillez entrer un montant valide';
    }

    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }

    if (amount > 999999999) {
      return 'Le montant est trop élevé';
    }

    return null;
  }
}

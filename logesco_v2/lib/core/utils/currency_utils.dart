import 'package:intl/intl.dart';

/// Utilitaires pour la gestion des devises
class CurrencyUtils {
  /// Devise par défaut de l'application
  static const String defaultCurrency = 'FCFA';
  
  /// Symbole de la devise
  static const String currencySymbol = 'FCFA';
  
  /// Formateur de nombres pour les montants
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');
  
  /// Formate un montant en FCFA
  /// 
  /// [amount] - Le montant à formater
  /// [showSymbol] - Afficher le symbole de devise (par défaut: true)
  /// [decimals] - Nombre de décimales (par défaut: 0 pour FCFA)
  static String formatAmount(
    double amount, {
    bool showSymbol = true,
    int decimals = 0,
  }) {
    final formattedNumber = decimals > 0
        ? amount.toStringAsFixed(decimals)
        : _numberFormat.format(amount.round());
    
    return showSymbol 
        ? '$formattedNumber $currencySymbol'
        : formattedNumber;
  }
  
  /// Formate un montant avec séparateur de milliers
  /// 
  /// [amount] - Le montant à formater
  /// [showSymbol] - Afficher le symbole de devise (par défaut: true)
  static String formatAmountWithSeparator(
    double amount, {
    bool showSymbol = true,
  }) {
    final formattedNumber = _numberFormat.format(amount.round());
    return showSymbol 
        ? '$formattedNumber $currencySymbol'
        : formattedNumber;
  }
  
  /// Parse un montant depuis une chaîne
  /// 
  /// [amountString] - La chaîne contenant le montant
  /// Retourne le montant en double ou 0.0 si invalide
  static double parseAmount(String amountString) {
    // Nettoyer la chaîne (enlever espaces, symboles de devise, etc.)
    final cleanString = amountString
        .replaceAll(RegExp(r'[^\d,.-]'), '')
        .replaceAll(',', '');
    
    return double.tryParse(cleanString) ?? 0.0;
  }
  
  /// Valide qu'un montant est positif
  /// 
  /// [amount] - Le montant à valider
  /// Retourne true si le montant est valide (>= 0)
  static bool isValidAmount(double amount) {
    return amount >= 0 && amount.isFinite;
  }
  
  /// Formate un montant pour l'affichage dans les champs de saisie
  /// 
  /// [amount] - Le montant à formater
  /// Retourne une chaîne sans symbole de devise pour la saisie
  static String formatForInput(double amount) {
    return amount.toStringAsFixed(0);
  }
  
  /// Calcule la différence entre deux montants et la formate
  /// 
  /// [finalAmount] - Montant final
  /// [initialAmount] - Montant initial
  /// [showSign] - Afficher le signe + ou - (par défaut: true)
  static String formatDifference(
    double finalAmount, 
    double initialAmount, {
    bool showSign = true,
  }) {
    final difference = finalAmount - initialAmount;
    final sign = showSign 
        ? (difference >= 0 ? '+' : '')
        : '';
    
    return '$sign${formatAmount(difference.abs())}';
  }
  
  /// Retourne l'icône appropriée pour la devise
  static String get currencyIcon => '💰';
  
  /// Retourne le code de devise ISO (si applicable)
  static String get currencyCode => 'XOF'; // Code ISO pour le Franc CFA
}

/// Extension pour faciliter le formatage des montants
extension DoubleExtension on double {
  /// Formate ce montant en FCFA
  String toFCFA({bool showSymbol = true}) {
    return CurrencyUtils.formatAmount(this, showSymbol: showSymbol);
  }
  
  /// Formate ce montant avec séparateur de milliers
  String toFCFAWithSeparator({bool showSymbol = true}) {
    return CurrencyUtils.formatAmountWithSeparator(this, showSymbol: showSymbol);
  }
  
  /// Formate ce montant pour la saisie
  String toInputFormat() {
    return CurrencyUtils.formatForInput(this);
  }
}
/// Traductions pour les reçus/factures
class ReceiptTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'fr': {
      'invoice': 'FACTURE',
      'proformaInvoice': 'FACTURE PROFORMA',
      'reprint': 'RIMPRESSION',
      'saleNumber': 'N° Vente',
      'date': 'Date',
      'time': 'Heure',
      'customer': 'Client',
      'issuer': 'Émetteur',
      'paymentMethod': 'Mode paiement',
      'article': 'Article',
      'quantity': 'Qté',
      'unitPrice': 'P.U.',
      'total': 'Total',
      'reference': 'Réf',
      'subtotal': 'Sous-total',
      'discount': 'Remise',
      'totalAmount': 'TOTAL',
      'paid': 'Payé',
      'change': 'Monnaie',
      'remaining': 'Reste',
      'thankYou': 'Merci pour votre confiance !',
      'reprintedOn': 'Réimprimé le',
      'by': 'par',
      'phone': 'Tél',
      'email': 'Email',
      'nuiRccm': 'NUI RCCM',
      'location': 'Localisation',
      'address': 'Adresse',
    },
    'en': {
      'invoice': 'INVOICE',
      'proformaInvoice': 'PROFORMA INVOICE',
      'reprint': 'REPRINT',
      'saleNumber': 'Sale No',
      'date': 'Date',
      'time': 'Time',
      'customer': 'Customer',
      'issuer': 'Issuer',
      'paymentMethod': 'Payment Method',
      'article': 'Item',
      'quantity': 'Qty',
      'unitPrice': 'Unit Price',
      'total': 'Total',
      'reference': 'Ref',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'totalAmount': 'TOTAL',
      'paid': 'Paid',
      'change': 'Change',
      'remaining': 'Balance',
      'thankYou': 'Thank you for your trust!',
      'reprintedOn': 'Reprinted on',
      'by': 'by',
      'phone': 'Tel',
      'email': 'Email',
      'nuiRccm': 'NUI RCCM',
      'location': 'Location',
      'address': 'Address',
    },
    'es': {
      'invoice': 'FACTURA',
      'proformaInvoice': 'FACTURA PROFORMA',
      'reprint': 'REIMPRESIÓN',
      'saleNumber': 'N° Venta',
      'date': 'Fecha',
      'time': 'Hora',
      'customer': 'Cliente',
      'issuer': 'Emisor',
      'paymentMethod': 'Método de pago',
      'article': 'Artículo',
      'quantity': 'Cant',
      'unitPrice': 'P.U.',
      'total': 'Total',
      'reference': 'Ref',
      'subtotal': 'Subtotal',
      'discount': 'Descuento',
      'totalAmount': 'TOTAL',
      'paid': 'Pagado',
      'change': 'Cambio',
      'remaining': 'Saldo',
      'thankYou': '¡Gracias por su confianza!',
      'reprintedOn': 'Reimpreso el',
      'by': 'por',
      'phone': 'Tel',
      'email': 'Email',
      'nuiRccm': 'NUI RCCM',
      'location': 'Ubicación',
      'address': 'Dirección',
    },
  };

  /// Obtient une traduction pour une clé donnée
  static String get(String key, {String language = 'fr'}) {
    final languageMap = _translations[language] ?? _translations['fr']!;
    return languageMap[key] ?? key;
  }

  /// Vérifie si une langue est supportée
  static bool isLanguageSupported(String language) {
    return _translations.containsKey(language);
  }

  /// Obtient toutes les langues supportées
  static List<String> getSupportedLanguages() {
    return _translations.keys.toList();
  }
}

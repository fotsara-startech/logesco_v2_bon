/// Conversion d'un montant en toutes lettres (français), pour la mention
/// "Arrêtée la présente facture à la somme de ..." des factures imprimées
/// en format matriciel.
library amount_in_words;

const List<String> _unites = [
  '', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf',
  'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize',
  'dix-sept', 'dix-huit', 'dix-neuf',
];

const List<String> _dizaines = [
  '', '', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante', 'soixante-dix', 'quatre-vingt', 'quatre-vingt-dix',
];

/// Convertit un entier positif (0 à 999 999 999 999) en toutes lettres.
String numberToFrenchWords(int n) {
  if (n == 0) return 'zéro';
  if (n < 0) return 'moins ${numberToFrenchWords(-n)}';

  final milliards = n ~/ 1000000000;
  final millions = (n ~/ 1000000) % 1000;
  final milliers = (n ~/ 1000) % 1000;
  final unites = n % 1000;

  final parts = <String>[];

  if (milliards > 0) {
    parts.add('${_hundredsToWords(milliards, isFinalGroup: false)} ${milliards > 1 ? 'milliards' : 'milliard'}');
  }
  if (millions > 0) {
    parts.add('${_hundredsToWords(millions, isFinalGroup: false)} ${millions > 1 ? 'millions' : 'million'}');
  }
  if (milliers > 0) {
    // "mille" est invariable et on ne dit pas "un mille" mais juste "mille"
    parts.add(milliers == 1 ? 'mille' : '${_hundredsToWords(milliers, isFinalGroup: false)} mille');
  }
  if (unites > 0) {
    parts.add(_hundredsToWords(unites, isFinalGroup: true));
  }

  return parts.join(' ');
}

/// Convertit un nombre de 1 à 999 en toutes lettres.
///
/// [isFinalGroup] : "cent" et "quatre-vingts" ne prennent la marque du
/// pluriel ('s') que lorsqu'ils terminent le nombre — jamais lorsqu'ils
/// sont suivis de "mille"/"million(s)"/"milliard(s)"
/// (ex: "deux cents" mais "deux cent mille").
String _hundredsToWords(int n, {required bool isFinalGroup}) {
  if (n < 20) return _unites[n];

  if (n < 100) {
    final d = n ~/ 10;
    final u = n % 10;

    // 70-79 : soixante(-et-)onze..dix-neuf — "soixante-dix" seulement si u=0
    if (d == 7) {
      if (u == 0) return 'soixante-dix';
      if (u == 1) return 'soixante et onze';
      return 'soixante-${_unites[10 + u]}';
    }
    // 90-99 : quatre-vingt-onze..dix-neuf (jamais de "et") — "quatre-vingt-dix" si u=0
    if (d == 9) {
      if (u == 0) return 'quatre-vingt-dix';
      return 'quatre-vingt-${_unites[10 + u]}';
    }

    if (u == 0) {
      // quatre-vingts prend un 's' seul, jamais suivi d'une unité ou d'un groupe (mille/million...)
      return (d == 8 && isFinalGroup) ? '${_dizaines[d]}s' : _dizaines[d];
    }
    if (u == 1 && d != 8) {
      // vingt-et-un, trente-et-un... (pas "quatre-vingt-un" qui n'a pas de "et")
      return '${_dizaines[d]}-et-un';
    }
    return '${_dizaines[d]}-${_unites[u]}';
  }

  // 100-999
  final c = n ~/ 100;
  final reste = n % 100;
  final centaine = c == 1 ? 'cent' : '${_unites[c]} cent';
  if (reste == 0) {
    // "cent" prend un 's' au pluriel seulement s'il termine le nombre
    return (c > 1 && isFinalGroup) ? '${centaine}s' : centaine;
  }
  return '$centaine ${_hundredsToWords(reste, isFinalGroup: isFinalGroup)}';
}

/// Formate un montant en lettres pour une facture, ex:
/// "Trois cent vingt-cinq mille francs CFA"
String amountInWordsFcfa(num amount) {
  final rounded = amount.round();
  final words = numberToFrenchWords(rounded);
  final capitalized = words[0].toUpperCase() + words.substring(1);
  return '$capitalized francs CFA';
}

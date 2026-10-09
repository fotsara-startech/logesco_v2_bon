/// Rend un texte affichable avec les polices standard des PDF (Helvetica & co).
///
/// Ces polices ne dessinent que le jeu Latin-1 : tout autre caractère (tiret
/// long « — », guillemets typographiques, points de suspension « … »...)
/// apparaît comme un carré vide dans le document. On remplace donc ces
/// caractères par leur équivalent simple ; les lettres accentuées usuelles
/// (é, è, à, ç, ô...) font partie de Latin-1 et sont conservées.
String pdfSafeText(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    out.write(_replacement(rune));
  }
  return out.toString();
}

String _replacement(int rune) {
  // Contrôles C0 (hors tabulation / saut de ligne) et C1 : rien à dessiner
  if ((rune < 0x20 && rune != 0x0A && rune != 0x09) || (rune >= 0x7F && rune <= 0x9F)) return '';
  if (rune <= 0xFF) return String.fromCharCode(rune); // Latin-1 : conservé tel quel

  switch (rune) {
    case 0x2010: // ‐
    case 0x2011: // ‑
    case 0x2012: // ‒
    case 0x2013: // –
    case 0x2014: // —
    case 0x2015: // ―
    case 0x2212: // −
      return '-';
    case 0x2018: // ‘
    case 0x2019: // ’
    case 0x201A: // ‚
    case 0x201B: // ‛
    case 0x2032: // ′
      return "'";
    case 0x201C: // “
    case 0x201D: // ”
    case 0x201E: // „
    case 0x2033: // ″
      return '"';
    case 0x2026: // …
      return '...';
    case 0x2022: // •
    case 0x25CF: // ●
    case 0x00B7: // ·
      return '-';
    case 0x2192: // →
      return '->';
    case 0x2190: // ←
      return '<-';
    case 0x20AC: // €
      return 'EUR';
    case 0x2009: // espace fine
    case 0x202F: // espace fine insécable
    case 0x2007: // espace chiffre
    case 0x2002:
    case 0x2003:
      return ' ';
    case 0x0152: // Œ
      return 'OE';
    case 0x0153: // œ
      return 'oe';
    default:
      return '?';
  }
}

/// Applique [pdfSafeText] à tous les textes d'une structure JSON
/// (Map / List / String), sans toucher aux nombres, booléens ni null.
dynamic pdfSafeData(dynamic value) {
  if (value is String) return pdfSafeText(value);
  // Types précis conservés : les services de relevé font `as Map<String, dynamic>`
  if (value is Map) return <String, dynamic>{for (final e in value.entries) e.key.toString(): pdfSafeData(e.value)};
  if (value is List) return <dynamic>[for (final v in value) pdfSafeData(v)];
  return value;
}

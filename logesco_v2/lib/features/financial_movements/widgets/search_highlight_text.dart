import 'package:flutter/material.dart';

/// Widget pour afficher du texte avec mise en évidence des termes de recherche
class SearchHighlightText extends StatelessWidget {
  final String text;
  final String? searchQuery;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const SearchHighlightText({
    super.key,
    required this.text,
    this.searchQuery,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    // Nettoie la requête de recherche (enlève les préfixes comme "desc:")
    String cleanQuery = searchQuery!;
    if (searchQuery!.contains(':')) {
      final parts = searchQuery!.split(' ');
      final cleanParts = <String>[];
      for (final part in parts) {
        if (part.contains(':')) {
          final colonIndex = part.indexOf(':');
          if (colonIndex < part.length - 1) {
            cleanParts.add(part.substring(colonIndex + 1));
          }
        } else {
          cleanParts.add(part);
        }
      }
      cleanQuery = cleanParts.join(' ');
    }

    if (cleanQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final queryTerms = cleanQuery.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
    final textLower = text.toLowerCase();

    // Trouve toutes les positions des termes de recherche
    final highlights = <_HighlightRange>[];
    for (final term in queryTerms) {
      int startIndex = 0;
      while (true) {
        final index = textLower.indexOf(term, startIndex);
        if (index == -1) break;

        highlights.add(_HighlightRange(index, index + term.length));
        startIndex = index + 1;
      }
    }

    // Trie et fusionne les plages qui se chevauchent
    highlights.sort((a, b) => a.start.compareTo(b.start));
    final mergedHighlights = <_HighlightRange>[];
    for (final highlight in highlights) {
      if (mergedHighlights.isEmpty || mergedHighlights.last.end < highlight.start) {
        mergedHighlights.add(highlight);
      } else {
        mergedHighlights.last = _HighlightRange(
          mergedHighlights.last.start,
          highlight.end > mergedHighlights.last.end ? highlight.end : mergedHighlights.last.end,
        );
      }
    }

    if (mergedHighlights.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    // Construit le RichText avec les parties mises en évidence
    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final highlight in mergedHighlights) {
      // Ajoute le texte avant la mise en évidence
      if (currentIndex < highlight.start) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, highlight.start),
          style: style,
        ));
      }

      // Ajoute le texte mis en évidence
      spans.add(TextSpan(
        text: text.substring(highlight.start, highlight.end),
        style: (style ?? const TextStyle()).copyWith(
          backgroundColor: Colors.yellow.shade200,
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = highlight.end;
    }

    // Ajoute le texte restant
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}

/// Classe helper pour représenter une plage de mise en évidence
class _HighlightRange {
  final int start;
  final int end;

  _HighlightRange(this.start, this.end);
}

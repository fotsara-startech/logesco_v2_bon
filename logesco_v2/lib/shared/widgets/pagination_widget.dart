import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Modèle de pagination
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;
  final int from;
  final int to;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
    required this.from,
    required this.to,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }
}

/// Widget de pagination avec contrôles
class PaginationWidget extends StatelessWidget {
  final PaginationInfo paginationInfo;
  final Function(int page) onPageChanged;
  final bool showInfo;
  final bool showJumpToPage;

  const PaginationWidget({
    super.key,
    required this.paginationInfo,
    required this.onPageChanged,
    this.showInfo = true,
    this.showJumpToPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Get.theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showInfo) _buildPaginationInfo(),
          const SizedBox(height: 8),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPaginationInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Affichage ${paginationInfo.from} à ${paginationInfo.to} sur ${paginationInfo.total}',
          style: Get.textTheme.bodySmall?.copyWith(
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          'Page ${paginationInfo.page} sur ${paginationInfo.pages}',
          style: Get.textTheme.bodySmall?.copyWith(
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Première page
        IconButton(
          onPressed: paginationInfo.page > 1 ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
          tooltip: 'Première page',
        ),

        // Page précédente
        IconButton(
          onPressed: paginationInfo.hasPrev ? () => onPageChanged(paginationInfo.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Page précédente',
        ),

        // Pages numériques
        ..._buildPageNumbers(),

        // Page suivante
        IconButton(
          onPressed: paginationInfo.hasNext ? () => onPageChanged(paginationInfo.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Page suivante',
        ),

        // Dernière page
        IconButton(
          onPressed: paginationInfo.page < paginationInfo.pages ? () => onPageChanged(paginationInfo.pages) : null,
          icon: const Icon(Icons.last_page),
          tooltip: 'Dernière page',
        ),

        if (showJumpToPage) ...[
          const SizedBox(width: 16),
          _buildJumpToPage(),
        ],
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pages = [];
    final currentPage = paginationInfo.page;
    final totalPages = paginationInfo.pages;

    // Calculer la plage de pages à afficher
    int startPage = (currentPage - 2).clamp(1, totalPages);
    int endPage = (currentPage + 2).clamp(1, totalPages);

    // Ajuster si on est près du début ou de la fin
    if (endPage - startPage < 4) {
      if (startPage == 1) {
        endPage = (startPage + 4).clamp(1, totalPages);
      } else if (endPage == totalPages) {
        startPage = (endPage - 4).clamp(1, totalPages);
      }
    }

    // Ajouter "..." au début si nécessaire
    if (startPage > 1) {
      pages.add(_buildPageButton(1));
      if (startPage > 2) {
        pages.add(_buildEllipsis());
      }
    }

    // Ajouter les pages dans la plage
    for (int i = startPage; i <= endPage; i++) {
      pages.add(_buildPageButton(i));
    }

    // Ajouter "..." à la fin si nécessaire
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pages.add(_buildEllipsis());
      }
      pages.add(_buildPageButton(totalPages));
    }

    return pages;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == paginationInfo.page;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isCurrentPage ? Get.theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isCurrentPage ? null : () => onPageChanged(page),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              page.toString(),
              style: Get.textTheme.bodyMedium?.copyWith(
                color: isCurrentPage ? Get.theme.colorScheme.onPrimary : Get.theme.colorScheme.onSurface,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: Get.textTheme.bodyMedium?.copyWith(
          color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildJumpToPage() {
    final controller = TextEditingController();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Aller à:',
          style: Get.textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Get.textTheme.bodySmall,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              hintText: paginationInfo.page.toString(),
            ),
            onSubmitted: (value) {
              final page = int.tryParse(value);
              if (page != null && page >= 1 && page <= paginationInfo.pages) {
                onPageChanged(page);
                controller.clear();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Widget de pagination simple (précédent/suivant uniquement)
class SimplePaginationWidget extends StatelessWidget {
  final PaginationInfo paginationInfo;
  final Function(int page) onPageChanged;
  final String? previousText;
  final String? nextText;

  const SimplePaginationWidget({
    super.key,
    required this.paginationInfo,
    required this.onPageChanged,
    this.previousText,
    this.nextText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton précédent
          TextButton.icon(
            onPressed: paginationInfo.hasPrev ? () => onPageChanged(paginationInfo.page - 1) : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(previousText ?? 'Précédent'),
          ),

          // Info page courante
          Text(
            'Page ${paginationInfo.page} sur ${paginationInfo.pages}',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          // Bouton suivant
          TextButton.icon(
            onPressed: paginationInfo.hasNext ? () => onPageChanged(paginationInfo.page + 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(nextText ?? 'Suivant'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}

/// Contrôleur de pagination réutilisable
class PaginationController extends GetxController {
  final RxInt _currentPage = 1.obs;
  final RxInt _limit = 20.obs;
  final Rx<PaginationInfo?> _paginationInfo = Rx<PaginationInfo?>(null);
  final RxBool _isLoading = false.obs;

  int get currentPage => _currentPage.value;
  int get limit => _limit.value;
  PaginationInfo? get paginationInfo => _paginationInfo.value;
  bool get isLoading => _isLoading.value;

  /// Met à jour les informations de pagination
  void updatePaginationInfo(PaginationInfo info) {
    _paginationInfo.value = info;
    _currentPage.value = info.page;
  }

  /// Change de page
  void goToPage(int page) {
    if (page != _currentPage.value && page >= 1) {
      _currentPage.value = page;
      onPageChanged(page);
    }
  }

  /// Page suivante
  void nextPage() {
    if (_paginationInfo.value?.hasNext == true) {
      goToPage(_currentPage.value + 1);
    }
  }

  /// Page précédente
  void previousPage() {
    if (_paginationInfo.value?.hasPrev == true) {
      goToPage(_currentPage.value - 1);
    }
  }

  /// Change la limite par page
  void changeLimit(int newLimit) {
    if (newLimit != _limit.value && newLimit > 0) {
      _limit.value = newLimit;
      _currentPage.value = 1; // Retour à la première page
      onLimitChanged(newLimit);
    }
  }

  /// Remet à zéro la pagination
  void reset() {
    _currentPage.value = 1;
    _paginationInfo.value = null;
  }

  /// Callback appelé lors du changement de page
  void onPageChanged(int page) {
    // À implémenter dans les classes dérivées
  }

  /// Callback appelé lors du changement de limite
  void onLimitChanged(int limit) {
    // À implémenter dans les classes dérivées
  }

  /// Définit l'état de chargement
  void setLoading(bool loading) {
    _isLoading.value = loading;
  }
}

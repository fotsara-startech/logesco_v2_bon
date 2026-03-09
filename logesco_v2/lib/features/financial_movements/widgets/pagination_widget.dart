import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Types de pagination disponibles
enum PaginationType {
  infinite, // Pagination infinie (scroll)
  pages, // Pagination par pages
}

/// Widget de pagination flexible supportant les deux modes
class PaginationWidget extends StatelessWidget {
  final PaginationType type;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNext;
  final bool hasPrev;
  final bool isLoading;
  final VoidCallback? onNextPage;
  final VoidCallback? onPrevPage;
  final Function(int)? onGoToPage;
  final Function(int)? onChangePageSize;
  final Function(PaginationType)? onChangeType;
  final List<int> pageSizeOptions;

  const PaginationWidget({
    super.key,
    required this.type,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNext,
    required this.hasPrev,
    required this.isLoading,
    this.onNextPage,
    this.onPrevPage,
    this.onGoToPage,
    this.onChangePageSize,
    this.onChangeType,
    this.pageSizeOptions = const [10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    if (type == PaginationType.infinite) {
      return _buildInfinitePagination();
    } else {
      return _buildPagePagination();
    }
  }

  /// Pagination infinie (indicateur de chargement)
  Widget _buildInfinitePagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informations sur les éléments chargés
          _buildItemsInfo(),

          const SizedBox(height: 8),

          // Indicateur de chargement ou bouton "Charger plus"
          if (isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('financial_movements_pagination_loading'.tr),
              ],
            )
          else if (hasNext)
            ElevatedButton.icon(
              onPressed: onNextPage,
              icon: const Icon(Icons.expand_more),
              label: Text('financial_movements_pagination_load_more'.tr),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'financial_movements_pagination_all_loaded'.tr,
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Option pour passer en mode pages
          if (onChangeType != null)
            TextButton.icon(
              onPressed: () => onChangeType!(PaginationType.pages),
              icon: const Icon(Icons.view_list, size: 16),
              label: Text('financial_movements_pagination_switch_to_pages'.tr),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  /// Pagination par pages
  Widget _buildPagePagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Informations et contrôles de taille de page
          Row(
            children: [
              _buildItemsInfo(),
              const Spacer(),
              _buildPageSizeSelector(),
            ],
          ),

          const SizedBox(height: 12),

          // Contrôles de navigation
          Row(
            children: [
              // Bouton première page
              IconButton(
                onPressed: currentPage > 1 ? () => onGoToPage?.call(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'financial_movements_pagination_first_page'.tr,
              ),

              // Bouton page précédente
              IconButton(
                onPressed: hasPrev && !isLoading ? onPrevPage : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Page précédente',
              ),

              const SizedBox(width: 8),

              // Indicateur de pages
              Expanded(
                child: _buildPageIndicator(),
              ),

              const SizedBox(width: 8),

              // Bouton page suivante
              IconButton(
                onPressed: hasNext && !isLoading ? onNextPage : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
              ),

              // Bouton dernière page
              IconButton(
                onPressed: currentPage < totalPages ? () => onGoToPage?.call(totalPages) : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Dernière page',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Option pour passer en mode infini
          if (onChangeType != null)
            TextButton.icon(
              onPressed: () => onChangeType!(PaginationType.infinite),
              icon: const Icon(Icons.all_inclusive, size: 16),
              label: const Text('Passer en mode infini'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  /// Informations sur les éléments
  Widget _buildItemsInfo() {
    final startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final endItem = (currentPage * itemsPerPage).clamp(0, totalItems);

    return Text(
      '$startItem-$endItem sur $totalItems éléments',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    );
  }

  /// Sélecteur de taille de page
  Widget _buildPageSizeSelector() {
    if (onChangePageSize == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Éléments par page:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: itemsPerPage,
          underline: const SizedBox.shrink(),
          items: pageSizeOptions.map((size) {
            return DropdownMenuItem(
              value: size,
              child: Text(size.toString()),
            );
          }).toList(),
          onChanged: (newSize) {
            if (newSize != null) {
              onChangePageSize!(newSize);
            }
          },
        ),
      ],
    );
  }

  /// Indicateur de pages avec navigation rapide
  Widget _buildPageIndicator() {
    if (totalPages <= 1) {
      return Center(
        child: Text(
          'Page $currentPage sur $totalPages',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      );
    }

    // Pour un grand nombre de pages, affiche une version compacte
    if (totalPages > 7) {
      return _buildCompactPageIndicator();
    }

    // Pour un petit nombre de pages, affiche toutes les pages
    return _buildFullPageIndicator();
  }

  /// Indicateur de pages complet (pour peu de pages)
  Widget _buildFullPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final pageNumber = index + 1;
        final isCurrentPage = pageNumber == currentPage;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: isCurrentPage ? null : () => onGoToPage?.call(pageNumber),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentPage ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCurrentPage ? Colors.blue : Colors.grey.shade300,
                ),
              ),
              child: Text(
                pageNumber.toString(),
                style: TextStyle(
                  color: isCurrentPage ? Colors.white : Colors.black87,
                  fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Indicateur de pages compact (pour beaucoup de pages)
  Widget _buildCompactPageIndicator() {
    final pages = <Widget>[];

    // Première page
    pages.add(_buildPageButton(1));

    // Points de suspension si nécessaire
    if (currentPage > 4) {
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('...'),
      ));
    }

    // Pages autour de la page actuelle
    final startPage = (currentPage - 2).clamp(2, totalPages - 1);
    final endPage = (currentPage + 2).clamp(2, totalPages - 1);

    for (int i = startPage; i <= endPage; i++) {
      if (i != 1 && i != totalPages) {
        pages.add(_buildPageButton(i));
      }
    }

    // Points de suspension si nécessaire
    if (currentPage < totalPages - 3) {
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('...'),
      ));
    }

    // Dernière page
    if (totalPages > 1) {
      pages.add(_buildPageButton(totalPages));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pages,
    );
  }

  /// Bouton de page individuel
  Widget _buildPageButton(int pageNumber) {
    final isCurrentPage = pageNumber == currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isCurrentPage ? null : () => onGoToPage?.call(pageNumber),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrentPage ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.black87,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de sélection du mode de pagination
class PaginationModeSelector extends StatelessWidget {
  final PaginationType currentType;
  final Function(PaginationType) onChanged;

  const PaginationModeSelector({
    super.key,
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            type: PaginationType.infinite,
            icon: Icons.all_inclusive,
            label: 'Infini',
          ),
          _buildModeButton(
            type: PaginationType.pages,
            icon: Icons.view_list,
            label: 'Pages',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required PaginationType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentType == type;

    return InkWell(
      onTap: () => onChanged(type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

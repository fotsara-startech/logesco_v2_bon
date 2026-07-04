import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Construit l'URL complète d'une image produit
String buildProductImageUrl(String filename) {
  final serverUrl = AppConfig.currentBaseUrl.replaceAll('/api/v1', '');
  return '$serverUrl/uploads/products/$filename';
}

/// Miniature carrée d'un produit avec icône œil pour prévisualisation plein écran.
///
/// [imageUrl]  : nom du fichier (ex: "product-123.jpg"). Si null/vide, affiche un placeholder.
/// [size]      : taille du carré (défaut 48)
/// [showPreviewIcon] : affiche le bouton œil par-dessus la miniature
class ProductImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showPreviewIcon;
  final String productName;

  const ProductImageThumbnail({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.showPreviewIcon = true,
    this.productName = '',
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      return _placeholder(context);
    }

    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        buildProductImageUrl(imageUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
        loadingBuilder: (_, child, progress) => progress == null ? child : _loadingPlaceholder(context),
      ),
    );

    if (!showPreviewIcon) return thumb;

    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: Stack(
        children: [
          thumb,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.visibility, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.45,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _loadingPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullScreenImageDialog(
        imageUrl: imageUrl!,
        productName: productName,
      ),
    );
  }
}

/// Image produit compacte dans la page détail (hauteur fixe 180px, centrée)
class ProductDetailImage extends StatelessWidget {
  final String? imageUrl;
  final String productName;

  const ProductDetailImage({
    super.key,
    this.imageUrl,
    this.productName = '',
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _FullScreenImageDialog(
          imageUrl: imageUrl!,
          productName: productName,
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: Image.network(
              buildProductImageUrl(imageUrl!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog plein écran avec zoom et fermeture par tap
class _FullScreenImageDialog extends StatelessWidget {
  final String imageUrl;
  final String productName;

  const _FullScreenImageDialog({
    required this.imageUrl,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(productName, style: const TextStyle(color: Colors.white)),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              buildProductImageUrl(imageUrl),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

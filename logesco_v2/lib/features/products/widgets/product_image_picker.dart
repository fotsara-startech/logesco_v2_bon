import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/app_config.dart';

/// Widget permettant d'afficher et de modifier l'image d'un produit.
///
/// [imageUrl]    : nom du fichier image stocké sur le serveur (ex: "product-123.jpg")
/// [onImagePicked] : callback appelé avec le chemin local du fichier sélectionné
/// [onImageDeleted]: callback appelé quand l'utilisateur supprime l'image
class ProductImagePicker extends StatelessWidget {
  final String? imageUrl;
  final bool isLoading;
  final void Function(String filePath) onImagePicked;
  final VoidCallback? onImageDeleted;

  const ProductImagePicker({
    super.key,
    this.imageUrl,
    this.isLoading = false,
    required this.onImagePicked,
    this.onImageDeleted,
  });

  String get _serverImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    final serverUrl = AppConfig.currentBaseUrl.replaceAll('/api/v1', '');
    return '$serverUrl/uploads/products/$imageUrl';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
    if (result != null && result.files.single.path != null) {
      onImagePicked(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image du produit',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isLoading ? null : _pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          _serverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(context),
                        ),
                      )
                    : _placeholder(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: isLoading ? null : _pickImage,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(imageUrl != null ? 'Changer' : 'Ajouter une image'),
            ),
            if (imageUrl != null && onImageDeleted != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onImageDeleted,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyer pour ajouter une image',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/loading_state.dart';

/// Widget pour afficher les états de chargement
class LoadingStateWidget extends StatelessWidget {
  final Rx<LoadingState> loadingState;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool showProgressBar;
  final bool showLoadingMessage;
  final VoidCallback? onRetry;

  const LoadingStateWidget({
    super.key,
    required this.loadingState,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.showProgressBar = true,
    this.showLoadingMessage = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = loadingState.value;

      if (state.isError) {
        return errorWidget ?? _buildErrorWidget(context, state);
      }

      if (state.isLoading) {
        return loadingWidget ?? _buildLoadingWidget(context, state);
      }

      return child;
    });
  }

  Widget _buildLoadingWidget(BuildContext context, LoadingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicateur de chargement principal
          _buildLoadingIndicator(state),

          const SizedBox(height: 16),

          // Message de chargement
          if (showLoadingMessage && state.message != null)
            Text(
              state.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),

          // Barre de progrès
          if (showProgressBar && state.hasProgress) ...[
            const SizedBox(height: 16),
            _buildProgressBar(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(LoadingState state) {
    switch (state.type) {
      case LoadingStateType.exporting:
      case LoadingStateType.generating:
        return const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        );
      case LoadingStateType.creating:
        return const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        );
      case LoadingStateType.updating:
        return const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        );
      case LoadingStateType.deleting:
        return const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        );
      case LoadingStateType.refreshing:
        return const RefreshProgressIndicator(
          strokeWidth: 3,
        );
      default:
        return const CircularProgressIndicator(strokeWidth: 3);
    }
  }

  Widget _buildProgressBar(BuildContext context, LoadingState state) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(state.type),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.progressPercentage}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Color _getProgressColor(LoadingStateType type) {
    switch (type) {
      case LoadingStateType.exporting:
      case LoadingStateType.generating:
        return Colors.blue;
      case LoadingStateType.creating:
        return Colors.green;
      case LoadingStateType.updating:
        return Colors.orange;
      case LoadingStateType.deleting:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildErrorWidget(BuildContext context, LoadingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (state.message != null)
            Text(
              state.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget compact pour afficher l'état de chargement dans une barre
class LoadingStateBar extends StatelessWidget {
  final Rx<LoadingState> loadingState;
  final bool showOnlyWhenLoading;

  const LoadingStateBar({
    super.key,
    required this.loadingState,
    this.showOnlyWhenLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = loadingState.value;

      if (showOnlyWhenLoading && !state.isLoading) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(state),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (state.isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getIndicatorColor(state),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (state.isError) ...[
              Icon(
                Icons.error_outline,
                size: 16,
                color: Colors.red[600],
              ),
              const SizedBox(width: 12),
            ] else if (state.isSuccess) ...[
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Colors.green[600],
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                state.message ?? _getDefaultMessage(state),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getTextColor(state),
                    ),
              ),
            ),
            if (state.hasProgress) ...[
              const SizedBox(width: 12),
              Text(
                '${state.progressPercentage}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getTextColor(state),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Color _getBackgroundColor(LoadingState state) {
    if (state.isError) return Colors.red[50]!;
    if (state.isSuccess) return Colors.green[50]!;
    return Colors.blue[50]!;
  }

  Color _getIndicatorColor(LoadingState state) {
    switch (state.type) {
      case LoadingStateType.creating:
        return Colors.green;
      case LoadingStateType.updating:
        return Colors.orange;
      case LoadingStateType.deleting:
        return Colors.red;
      case LoadingStateType.exporting:
      case LoadingStateType.generating:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Color _getTextColor(LoadingState state) {
    if (state.isError) return Colors.red[700]!;
    if (state.isSuccess) return Colors.green[700]!;
    return Colors.blue[700]!;
  }

  String _getDefaultMessage(LoadingState state) {
    switch (state.type) {
      case LoadingStateType.loading:
        return 'Chargement...';
      case LoadingStateType.refreshing:
        return 'Actualisation...';
      case LoadingStateType.loadingMore:
        return 'Chargement de plus d\'éléments...';
      case LoadingStateType.creating:
        return 'Création en cours...';
      case LoadingStateType.updating:
        return 'Mise à jour en cours...';
      case LoadingStateType.deleting:
        return 'Suppression en cours...';
      case LoadingStateType.exporting:
        return 'Export en cours...';
      case LoadingStateType.generating:
        return 'Génération en cours...';
      case LoadingStateType.error:
        return 'Une erreur s\'est produite';
      case LoadingStateType.success:
        return 'Opération réussie';
      default:
        return '';
    }
  }
}

/// Widget pour afficher un indicateur de chargement flottant
class FloatingLoadingIndicator extends StatelessWidget {
  final Rx<LoadingState> loadingState;

  const FloatingLoadingIndicator({
    super.key,
    required this.loadingState,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = loadingState.value;

      if (!state.isLoading) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getIndicatorColor(state.type),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.message ?? 'Chargement...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (state.hasProgress) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${state.progressPercentage}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _getIndicatorColor(LoadingStateType type) {
    switch (type) {
      case LoadingStateType.creating:
        return Colors.green;
      case LoadingStateType.updating:
        return Colors.orange;
      case LoadingStateType.deleting:
        return Colors.red;
      case LoadingStateType.exporting:
      case LoadingStateType.generating:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}

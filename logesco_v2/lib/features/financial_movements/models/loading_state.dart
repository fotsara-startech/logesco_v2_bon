import 'package:get/get.dart';

/// Énumération des différents états de chargement
enum LoadingStateType {
  idle,
  loading,
  refreshing,
  loadingMore,
  creating,
  updating,
  deleting,
  exporting,
  generating,
  error,
  success,
}

/// Modèle pour gérer les états de chargement avec contexte
class LoadingState {
  final LoadingStateType type;
  final String? message;
  final String? operation;
  final double? progress;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  LoadingState({
    required this.type,
    this.message,
    this.operation,
    this.progress,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// État idle (au repos)
  static LoadingState get idle => LoadingState(type: LoadingStateType.idle);

  /// État de chargement initial
  static LoadingState loading({String? message, String? operation}) {
    return LoadingState(
      type: LoadingStateType.loading,
      message: message ?? 'Chargement en cours...',
      operation: operation,
    );
  }

  /// État de rafraîchissement
  static LoadingState refreshing({String? message, String? operation}) {
    return LoadingState(
      type: LoadingStateType.refreshing,
      message: message ?? 'Actualisation en cours...',
      operation: operation,
    );
  }

  /// État de chargement de plus d'éléments
  static LoadingState loadingMore({String? message, String? operation}) {
    return LoadingState(
      type: LoadingStateType.loadingMore,
      message: message ?? 'Chargement de plus d\'éléments...',
      operation: operation,
    );
  }

  /// État de création
  static LoadingState creating({String? message, String? operation}) {
    return LoadingState(
      type: LoadingStateType.creating,
      message: message ?? 'Création en cours...',
      operation: operation,
    );
  }

  /// État de mise à jour
  static LoadingState updating({String? message, String? operation}) {
    return LoadingState(
      type: LoadingStateType.updating,
      message: message ?? 'Mise à jour en cours...',
      operation: operation,
    );
  }

  /// État de suppression
  static LoadingState deleting({String? message, String? operation}) {
    return LoadingState(
      type: LoadingStateType.deleting,
      message: message ?? 'Suppression en cours...',
      operation: operation,
    );
  }

  /// État d'export
  static LoadingState exporting({String? message, String? operation, double? progress}) {
    return LoadingState(
      type: LoadingStateType.exporting,
      message: message ?? 'Export en cours...',
      operation: operation,
      progress: progress,
    );
  }

  /// État de génération
  static LoadingState generating({String? message, String? operation, double? progress}) {
    return LoadingState(
      type: LoadingStateType.generating,
      message: message ?? 'Génération en cours...',
      operation: operation,
      progress: progress,
    );
  }

  /// État d'erreur
  static LoadingState error({String? message, String? operation, Map<String, dynamic>? metadata}) {
    return LoadingState(
      type: LoadingStateType.error,
      message: message ?? 'Une erreur s\'est produite',
      operation: operation,
      metadata: metadata,
    );
  }

  /// État de succès
  static LoadingState success({String? message, String? operation, Map<String, dynamic>? metadata}) {
    return LoadingState(
      type: LoadingStateType.success,
      message: message ?? 'Opération réussie',
      operation: operation,
      metadata: metadata,
    );
  }

  /// Vérifie si l'état est en cours de chargement
  bool get isLoading => [
        LoadingStateType.loading,
        LoadingStateType.refreshing,
        LoadingStateType.loadingMore,
        LoadingStateType.creating,
        LoadingStateType.updating,
        LoadingStateType.deleting,
        LoadingStateType.exporting,
        LoadingStateType.generating,
      ].contains(type);

  /// Vérifie si l'état est une erreur
  bool get isError => type == LoadingStateType.error;

  /// Vérifie si l'état est un succès
  bool get isSuccess => type == LoadingStateType.success;

  /// Vérifie si l'état est idle
  bool get isIdle => type == LoadingStateType.idle;

  /// Vérifie si l'opération a un progrès
  bool get hasProgress => progress != null;

  /// Obtient le pourcentage de progrès (0-100)
  int get progressPercentage => ((progress ?? 0) * 100).round();

  /// Copie l'état avec de nouvelles valeurs
  LoadingState copyWith({
    LoadingStateType? type,
    String? message,
    String? operation,
    double? progress,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LoadingState(
      type: type ?? this.type,
      message: message ?? this.message,
      operation: operation ?? this.operation,
      progress: progress ?? this.progress,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'LoadingState(type: $type, message: $message, operation: $operation, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadingState && other.type == type && other.message == message && other.operation == operation && other.progress == progress;
  }

  @override
  int get hashCode {
    return type.hashCode ^ message.hashCode ^ operation.hashCode ^ progress.hashCode;
  }
}

/// Mixin pour gérer les états de chargement dans les contrôleurs
mixin LoadingStateMixin {
  final Rx<LoadingState> _loadingState = LoadingState.idle.obs;

  /// État de chargement observable
  Rx<LoadingState> get loadingState => _loadingState;

  /// État de chargement actuel
  LoadingState get currentLoadingState => _loadingState.value;

  /// Définit l'état de chargement
  void setLoadingState(LoadingState state) {
    _loadingState.value = state;
  }

  /// Définit l'état idle
  void setIdle() {
    setLoadingState(LoadingState.idle);
  }

  /// Définit l'état de chargement
  void setLoading({String? message, String? operation}) {
    setLoadingState(LoadingState.loading(message: message, operation: operation));
  }

  /// Définit l'état de rafraîchissement
  void setRefreshing({String? message, String? operation}) {
    setLoadingState(LoadingState.refreshing(message: message, operation: operation));
  }

  /// Définit l'état de chargement de plus d'éléments
  void setLoadingMore({String? message, String? operation}) {
    setLoadingState(LoadingState.loadingMore(message: message, operation: operation));
  }

  /// Définit l'état de création
  void setCreating({String? message, String? operation}) {
    setLoadingState(LoadingState.creating(message: message, operation: operation));
  }

  /// Définit l'état de mise à jour
  void setUpdating({String? message, String? operation}) {
    setLoadingState(LoadingState.updating(message: message, operation: operation));
  }

  /// Définit l'état de suppression
  void setDeleting({String? message, String? operation}) {
    setLoadingState(LoadingState.deleting(message: message, operation: operation));
  }

  /// Définit l'état d'export
  void setExporting({String? message, String? operation, double? progress}) {
    setLoadingState(LoadingState.exporting(message: message, operation: operation, progress: progress));
  }

  /// Définit l'état de génération
  void setGenerating({String? message, String? operation, double? progress}) {
    setLoadingState(LoadingState.generating(message: message, operation: operation, progress: progress));
  }

  /// Définit l'état d'erreur
  void setError({String? message, String? operation, Map<String, dynamic>? metadata}) {
    setLoadingState(LoadingState.error(message: message, operation: operation, metadata: metadata));
  }

  /// Définit l'état de succès
  void setSuccess({String? message, String? operation, Map<String, dynamic>? metadata}) {
    setLoadingState(LoadingState.success(message: message, operation: operation, metadata: metadata));
  }

  /// Met à jour le progrès de l'opération en cours
  void updateProgress(double progress, {String? message}) {
    if (currentLoadingState.isLoading) {
      setLoadingState(currentLoadingState.copyWith(
        progress: progress,
        message: message,
      ));
    }
  }

  /// Vérifie si une opération spécifique est en cours
  bool isOperationInProgress(String operation) {
    return currentLoadingState.isLoading && currentLoadingState.operation == operation;
  }

  /// Exécute une opération avec gestion automatique de l'état
  Future<T> executeWithLoadingState<T>(
    Future<T> Function() operation, {
    required LoadingState loadingState,
    String? successMessage,
    String? errorMessage,
    bool autoResetAfterSuccess = true,
    Duration? successDuration,
  }) async {
    try {
      setLoadingState(loadingState);

      final result = await operation();

      if (successMessage != null) {
        setSuccess(
          message: successMessage,
          operation: loadingState.operation,
        );

        if (autoResetAfterSuccess) {
          Future.delayed(successDuration ?? const Duration(seconds: 2), () {
            if (currentLoadingState.isSuccess) {
              setIdle();
            }
          });
        }
      } else if (autoResetAfterSuccess) {
        setIdle();
      }

      return result;
    } catch (e) {
      setError(
        message: errorMessage ?? 'Une erreur s\'est produite: ${e.toString()}',
        operation: loadingState.operation,
        metadata: {'error': e.toString()},
      );
      rethrow;
    }
  }
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'local_config.dart';
import 'cloud_config.dart';

enum DeploymentEnvironment {
  local,
  cloud,
}

class EnvironmentConfig {
  static DeploymentEnvironment get currentEnvironment {
    // Detect environment based on platform and configuration
    if (kIsWeb) {
      return DeploymentEnvironment.cloud;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Check if local API is available
      return DeploymentEnvironment.local;
    }

    // Default to cloud for mobile or unknown platforms
    return DeploymentEnvironment.cloud;
  }

  static bool get isLocal => currentEnvironment == DeploymentEnvironment.local;
  static bool get isCloud => currentEnvironment == DeploymentEnvironment.cloud;

  // API Configuration
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.apiBaseUrl;
      case DeploymentEnvironment.cloud:
        return CloudConfig.apiBaseUrl;
    }
  }

  static String get apiHealthUrl {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.apiHealthUrl;
      case DeploymentEnvironment.cloud:
        return CloudConfig.apiHealthUrl;
    }
  }

  // Timeout Configuration
  static Duration get connectionTimeout {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.connectionTimeout;
      case DeploymentEnvironment.cloud:
        return CloudConfig.connectionTimeout;
    }
  }

  static Duration get receiveTimeout {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.receiveTimeout;
      case DeploymentEnvironment.cloud:
        return CloudConfig.receiveTimeout;
    }
  }

  // Feature Flags
  static bool get enableOfflineMode {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.enableOfflineMode;
      case DeploymentEnvironment.cloud:
        return CloudConfig.enableOfflineMode;
    }
  }

  static bool get enableCaching {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return true; // Always enable for local
      case DeploymentEnvironment.cloud:
        return CloudConfig.enableCaching;
    }
  }

  // Storage Configuration
  static String get storagePrefix {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.localStoragePrefix;
      case DeploymentEnvironment.cloud:
        return CloudConfig.cloudStoragePrefix;
    }
  }

  // Retry Configuration
  static int get maxRetryAttempts {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.maxRetryAttempts;
      case DeploymentEnvironment.cloud:
        return CloudConfig.maxRetryAttempts;
    }
  }

  static Duration get retryDelay {
    switch (currentEnvironment) {
      case DeploymentEnvironment.local:
        return LocalConfig.retryDelay;
      case DeploymentEnvironment.cloud:
        return CloudConfig.retryDelay;
    }
  }

  // Debug Information
  static Map<String, dynamic> get debugInfo {
    return {
      'environment': currentEnvironment.toString(),
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'apiBaseUrl': apiBaseUrl,
      'enableOfflineMode': enableOfflineMode,
      'enableCaching': enableCaching,
    };
  }
}

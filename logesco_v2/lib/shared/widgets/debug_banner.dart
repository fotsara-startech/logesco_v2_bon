import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

/// Bannière de debug pour indiquer le mode de développement
class DebugBanner extends StatelessWidget {
  final Widget child;

  const DebugBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDevelopmentMode) {
      return child;
    }

    return Banner(
      message: 'MODE TEST',
      location: BannerLocation.topEnd,
      color: Colors.orange,
      child: child,
    );
  }
}

/// Widget d'information sur le mode de développement
class DevModeInfo extends StatelessWidget {
  const DevModeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDevelopmentMode) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mode Développement',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Authentification bypassée\n'
            '• Données simulées (pas de backend requis)\n'
            '• Toutes les fonctionnalités sont testables',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cash_session_controller.dart';
import '../../../core/utils/currency_utils.dart';

/// Widget indicateur de session de caisse pour la barre d'application
class CashSessionIndicator extends StatelessWidget {
  const CashSessionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final CashSessionController controller = Get.find<CashSessionController>();

    return Obx(() {
      final session = controller.activeSession.value;

      if (session == null) {
        return _buildNoSessionIndicator(controller);
      }

      return _buildActiveSessionIndicator(session, controller);
    });
  }

  Widget _buildNoSessionIndicator(CashSessionController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: controller.showConnectToCashRegisterDialog,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                size: 16,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Aucune caisse',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionIndicator(session, CashSessionController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => Get.toNamed('/cash-session'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.nomCaisse,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (controller.canViewBalance)
                    Text(
                      CurrencyUtils.formatAmount(session.soldeAttendu ?? session.soldeOuverture),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher les détails de la session dans un drawer ou menu
class CashSessionDrawerHeader extends StatelessWidget {
  const CashSessionDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final CashSessionController controller = Get.find<CashSessionController>();

    return Obx(() {
      final session = controller.activeSession.value;

      return DrawerHeader(
        decoration: BoxDecoration(
          color: session != null ? Colors.green.shade600 : Colors.grey.shade600,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  session != null ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session de Caisse',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (session != null) ...[
              Text(
                'Caisse: ${session.nomCaisse}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Solde ouverture: ${CurrencyUtils.formatAmount(session.soldeOuverture)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              if (controller.canViewBalance) ...[
                const SizedBox(height: 4),
                Text(
                  'Solde actuel: ${CurrencyUtils.formatAmount(session.soldeAttendu ?? session.soldeOuverture)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final difference = (session.soldeAttendu ?? session.soldeOuverture) - session.soldeOuverture;
                    return Text(
                      'Différence: ${difference >= 0 ? '+' : ''}${CurrencyUtils.formatAmount(difference.abs())}',
                      style: TextStyle(
                        color: difference >= 0 ? Colors.lightGreen.shade200 : Colors.red.shade200,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Durée: ${session.formattedDuration}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const Text(
                'Aucune session active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Connectez-vous à une caisse',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// Widget bouton flottant pour actions rapides de session
class CashSessionFAB extends StatelessWidget {
  const CashSessionFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final CashSessionController controller = Get.find<CashSessionController>();

    return Obx(() {
      final session = controller.activeSession.value;

      if (session == null) {
        return FloatingActionButton.extended(
          onPressed: controller.showConnectToCashRegisterDialog,
          icon: const Icon(Icons.login),
          label: const Text('Connecter caisse'),
          backgroundColor: Colors.blue,
        );
      }

      return FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/sales'),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Nouvelle vente'),
        backgroundColor: Colors.green,
      );
    });
  }
}

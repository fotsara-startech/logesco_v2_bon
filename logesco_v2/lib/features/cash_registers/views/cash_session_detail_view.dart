import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cash_session_controller.dart';
import '../widgets/cash_balance_display.dart';

/// Vue détaillée de la session de caisse
class CashSessionDetailView extends StatelessWidget {
  const CashSessionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CashSessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session de Caisse'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          Obx(() {
            final session = controller.activeSession.value;
            if (session != null) {
              return IconButton(
                onPressed: controller.confirmDisconnectFromCashRegister,
                icon: const Icon(Icons.logout),
                tooltip: 'Clôturer la session',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadActiveSession();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affichage principal du solde
              const CashBalanceDisplay(
                showDetails: true,
                isCompact: false,
              ),

              const SizedBox(height: 16),

              // Actions rapides
              const CashQuickActions(),

              const SizedBox(height: 16),

              // Statistiques de la session
              Obx(() {
                final session = controller.activeSession.value;
                if (session != null) {
                  return _buildSessionStats(session);
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 16),

              // Liste des transactions (à implémenter)
              const CashTransactionsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        final session = controller.activeSession.value;
        if (session != null) {
          return FloatingActionButton.extended(
            onPressed: () => Get.toNamed('/sales'),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Nouvelle Vente'),
            backgroundColor: Colors.green,
          );
        }
        return FloatingActionButton.extended(
          onPressed: controller.showConnectToCashRegisterDialog,
          icon: const Icon(Icons.login),
          label: const Text('Se Connecter'),
          backgroundColor: Colors.blue,
        );
      }),
    );
  }

  Widget _buildSessionStats(session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques de la session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Ventes réalisées',
                    '0', // TODO: Implémenter le comptage des ventes
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Solde actuel',
                    (session.soldeAttendu ?? session.soldeOuverture).toStringAsFixed(0) + ' FCFA',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Heure d\'ouverture',
                    _formatTime(session.dateOuverture),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Durée active',
                    session.formattedDuration,
                    Icons.timer,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

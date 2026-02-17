import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cash_session_controller.dart';
import '../models/cash_session_model.dart';
import '../widgets/cash_balance_display.dart';
import '../../../core/utils/currency_utils.dart';
import '../../auth/controllers/auth_controller.dart';

/// Vue pour la gestion des sessions de caisse
class CashSessionView extends StatelessWidget {
  const CashSessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final CashSessionController controller = Get.find<CashSessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session de Caisse'),
        actions: [
          // Bouton pour voir l'historique (Admin uniquement)
          Obx(() {
            final authController = Get.find<AuthController>();
            final isAdmin = authController.currentUser.value?.role.isAdmin ?? false;

            if (isAdmin) {
              return IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Historique des sessions',
                onPressed: () => Get.toNamed('/cash-session/history'),
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.loadActiveSession();
              controller.loadAvailableCashRegisters();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affichage du solde de caisse en temps réel
              const CashBalanceDisplay(
                showDetails: true,
                isCompact: false,
              ),
              const SizedBox(height: 16),

              // Actions rapides
              const CashQuickActions(),
              const SizedBox(height: 24),

              // Statut de la session (détails supplémentaires)
              _buildSessionStatus(controller),
              const SizedBox(height: 24),

              // Historique des sessions
              if (controller.sessionHistory.isNotEmpty) ...[
                _buildSessionHistory(controller),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSessionStatus(CashSessionController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  controller.activeSession.value != null ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: controller.activeSession.value != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statut de la session',
                  style: Theme.of(Get.context!).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.activeSession.value != null) ...[
              _buildActiveSessionInfo(controller.activeSession.value!),
            ] else ...[
              _buildNoActiveSessionInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionInfo(CashSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'SESSION ACTIVE',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Caisse',
                session.nomCaisse,
                Icons.point_of_sale,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Utilisateur',
                session.nomUtilisateur,
                Icons.person,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Solde d\'ouverture',
                CurrencyUtils.formatAmount(session.soldeOuverture),
                Icons.attach_money,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Durée',
                session.formattedDuration,
                Icons.access_time,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          'Ouvert le',
          _formatDateTime(session.dateOuverture),
          Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildNoActiveSessionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'AUCUNE SESSION ACTIVE',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vous devez vous connecter à une caisse pour pouvoir effectuer des ventes.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMainActions(CashSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(Get.context!).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        if (controller.activeSession.value == null) ...[
          // Bouton pour se connecter à une caisse
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.showConnectToCashRegisterDialog,
              icon: const Icon(Icons.login),
              label: const Text('Se connecter à une caisse'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ] else ...[
          // Boutons pour session active
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.confirmDisconnectFromCashRegister,
                  icon: const Icon(Icons.logout),
                  label: const Text('Clôturer la session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Naviguer vers les ventes
                    Get.toNamed('/sales');
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Faire une vente'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),

        // Bouton pour voir les caisses disponibles
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              controller.loadAvailableCashRegisters();
              _showAvailableCashRegisters(controller);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Voir les caisses disponibles'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHistory(CashSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historique des sessions',
              style: Theme.of(Get.context!).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => controller.loadSessionHistory(),
              child: const Text('Actualiser'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.sessionHistory.length,
          itemBuilder: (context, index) {
            final session = controller.sessionHistory[index];
            return _buildSessionHistoryCard(session);
          },
        ),
      ],
    );
  }

  Widget _buildSessionHistoryCard(CashSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.isOpen ? Colors.green.shade100 : Colors.grey.shade100,
          child: Icon(
            session.isOpen ? Icons.lock_open : Icons.lock,
            color: session.isOpen ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
        title: Text(session.nomCaisse),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatDateTime(session.dateOuverture)} - ${session.formattedDuration}'),
            if (session.soldeFermeture != null) Text('Différence: ${CurrencyUtils.formatDifference(session.soldeFermeture ?? 0, session.soldeOuverture)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: session.isOpen ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            session.status,
            style: TextStyle(
              fontSize: 12,
              color: session.isOpen ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  void _showAvailableCashRegisters(CashSessionController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Caisses disponibles'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (controller.availableCashRegisters.isEmpty) {
              return const Text('Aucune caisse disponible pour le moment.');
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: controller.availableCashRegisters.length,
              itemBuilder: (context, index) {
                final cashRegister = controller.availableCashRegisters[index];
                return ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: Text(cashRegister['nom'] ?? 'Caisse'),
                  subtitle: Text('Solde: ${CurrencyUtils.formatAmount(cashRegister['soldeActuel']?.toDouble() ?? 0.0)}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

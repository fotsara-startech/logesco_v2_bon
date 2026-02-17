import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cash_session_controller.dart';
import '../../../core/utils/currency_utils.dart';

/// Widget d'affichage du solde de caisse en temps réel
class CashBalanceDisplay extends StatelessWidget {
  final bool showDetails;
  final bool isCompact;

  const CashBalanceDisplay({
    super.key,
    this.showDetails = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final CashSessionController controller = Get.find<CashSessionController>();

    return Obx(() {
      final session = controller.activeSession.value;

      if (session == null) {
        return _buildNoSessionCard();
      }

      if (isCompact) {
        return _buildCompactDisplay(session);
      }

      return _buildDetailedDisplay(session);
    });
  }

  Widget _buildNoSessionCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red.shade600,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune session de caisse active',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Get.find<CashSessionController>().showConnectToCashRegisterDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Se connecter à une caisse'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDisplay(session) {
    final soldeActuel = session.soldeAttendu ?? session.soldeOuverture;
    final difference = soldeActuel - session.soldeOuverture;
    final differenceColor = difference >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.nomCaisse,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                CurrencyUtils.formatAmount(soldeActuel),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          if (difference != 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: differenceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${difference >= 0 ? '+' : ''}${CurrencyUtils.formatAmount(difference.abs())}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: differenceColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedDisplay(session) {
    final soldeActuel = session.soldeAttendu ?? session.soldeOuverture;
    final difference = soldeActuel - session.soldeOuverture;
    final differenceColor = difference >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom de la caisse
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.nomCaisse,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Solde actuel (principal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'SOLDE ACTUEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyUtils.formatAmount(soldeActuel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (showDetails) ...[
              const SizedBox(height: 16),

              // Détails de la session
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Solde d\'ouverture',
                      CurrencyUtils.formatAmount(session.soldeOuverture),
                      Icons.login,
                      Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard(
                      'Différence',
                      '${difference >= 0 ? '+' : ''}${CurrencyUtils.formatAmount(difference.abs())}',
                      difference >= 0 ? Icons.trending_up : Icons.trending_down,
                      differenceColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Durée',
                      session.formattedDuration,
                      Icons.access_time,
                      Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard(
                      'Utilisateur',
                      session.nomUtilisateur,
                      Icons.person,
                      Colors.purple.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
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
                  label,
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
}

/// Widget pour afficher les transactions récentes de la caisse
class CashTransactionsList extends StatelessWidget {
  const CashTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions récentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Implémenter la liste des transactions
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Fonctionnalité à venir',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget bouton pour actions rapides de caisse
class CashQuickActions extends StatelessWidget {
  const CashQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CashSessionController>();

    return Obx(() {
      final session = controller.activeSession.value;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (session == null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.showConnectToCashRegisterDialog,
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter à une caisse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed('/sales'),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Nouvelle vente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.confirmDisconnectFromCashRegister,
                        icon: const Icon(Icons.logout),
                        label: const Text('Clôturer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

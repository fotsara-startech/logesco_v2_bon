import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/cash_session_controller.dart';
import '../models/cash_session_model.dart';

/// Page d'historique des sessions de caisse (Admin uniquement)
class CashSessionHistoryView extends StatelessWidget {
  const CashSessionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CashSessionController());
    final RxBool showStatistics = true.obs;

    // Charger l'historique au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadSessionHistory();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des sessions'),
        elevation: 0,
        actions: [
          Obx(() => IconButton(
                icon: Icon(showStatistics.value ? Icons.visibility_off : Icons.visibility),
                onPressed: () => showStatistics.value = !showStatistics.value,
                tooltip: showStatistics.value ? 'Masquer les statistiques' : 'Afficher les statistiques',
              )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadSessionHistory(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres de période
          _buildPeriodFilters(controller),

          const Divider(height: 1),

          // Statistiques (affichables/masquables)
          Obx(() {
            if (showStatistics.value && controller.sessionHistory.isNotEmpty) {
              return _buildStatistics(controller);
            }
            return const SizedBox.shrink();
          }),

          Obx(() {
            if (showStatistics.value && controller.sessionHistory.isNotEmpty) {
              return const Divider(height: 1);
            }
            return const SizedBox.shrink();
          }),

          // Liste des sessions
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.sessionHistory.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.sessionHistory.length,
                itemBuilder: (context, index) {
                  final session = controller.sessionHistory[index];
                  return _buildSessionCard(session);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilters(CashSessionController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Période',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Bouton pour ouvrir le sélecteur de dates personnalisées
              TextButton.icon(
                onPressed: () => _showDateRangePicker(controller),
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Dates personnalisées'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SessionPeriodFilter.values.where((f) => f != SessionPeriodFilter.custom).map((filter) {
                  final isSelected = controller.periodFilter.value == filter;
                  return FilterChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      controller.setPeriodFilter(filter);
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[700],
                  );
                }).toList(),
              )),

          // Afficher la période personnalisée si sélectionnée
          Obx(() {
            if (controller.periodFilter.value == SessionPeriodFilter.custom && controller.customStartDate.value != null && controller.customEndDate.value != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Du ${DateFormat('dd/MM/yyyy').format(controller.customStartDate.value!)} '
                        'au ${DateFormat('dd/MM/yyyy').format(controller.customEndDate.value!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: Colors.blue[700]),
                        onPressed: () => controller.setPeriodFilter(SessionPeriodFilter.all),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(CashSessionController controller) async {
    DateTime? startDate = controller.customStartDate.value;
    DateTime? endDate = controller.customEndDate.value;

    await Get.dialog(
      AlertDialog(
        title: const Text('Sélectionner une période'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date de début
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date de début',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : 'Non définie',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Date de fin
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date de fin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : 'Non définie',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (startDate != null && endDate != null) {
                controller.setCustomPeriod(startDate, endDate);
                Get.back();
              } else {
                Get.snackbar(
                  'Erreur',
                  'Veuillez sélectionner les deux dates',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade100,
                  colorText: Colors.red.shade800,
                );
              }
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(CashSessionController controller) {
    final sessions = controller.sessionHistory.where((s) => s.isClosed).toList();

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculer les statistiques
    double totalSoldeOuverture = 0;
    double totalSoldeFermeture = 0;
    double totalEcartPositif = 0;
    double totalEcartNegatif = 0;
    int nombreEcartsPositifs = 0;
    int nombreEcartsNegatifs = 0;

    for (final session in sessions) {
      totalSoldeOuverture += session.soldeOuverture;
      totalSoldeFermeture += session.soldeFermeture ?? 0;

      final ecart = session.ecart ?? 0;
      if (ecart > 0) {
        totalEcartPositif += ecart;
        nombreEcartsPositifs++;
      } else if (ecart < 0) {
        totalEcartNegatif += ecart;
        nombreEcartsNegatifs++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length} session(s)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Ouverture',
                  '${totalSoldeOuverture.toStringAsFixed(0)} F',
                  Icons.login,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Fermeture',
                  '${totalSoldeFermeture.toStringAsFixed(0)} F',
                  Icons.logout,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Écarts Positifs',
                  '${totalEcartPositif > 0 ? '+' : ''}${totalEcartPositif.toStringAsFixed(0)} F',
                  Icons.trending_up,
                  Colors.green,
                  subtitle: '$nombreEcartsPositifs session(s)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Écarts Négatifs',
                  '${totalEcartNegatif.toStringAsFixed(0)} F',
                  Icons.trending_down,
                  Colors.red,
                  subtitle: '$nombreEcartsNegatifs session(s)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => _buildStatCard(
                'Mouvements Financiers',
                '${controller.totalMovementsAmount.value.toStringAsFixed(0)} F',
                Icons.account_balance_wallet,
                Colors.purple,
                subtitle: 'Dépenses de la période',
                fullWidth: true,
              )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? subtitle, bool fullWidth = false}) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );

    return fullWidth ? card : Expanded(child: card);
  }

  Widget _buildSessionCard(CashSession session) {
    final ecart = session.ecart ?? 0.0;
    final isPositive = ecart >= 0;
    final isClosed = session.isClosed;

    // LOG DE DEBUG
    print('📊 Affichage session ${session.id}:');
    print('   ecart brut: ${session.ecart}');
    print('   ecart calculé: $ecart');
    print('   isPositive: $isPositive');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.point_of_sale,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.nomCaisse,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          session.nomUtilisateur,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.grey[200] : Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isClosed ? 'Fermée' : 'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isClosed ? Colors.grey[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Informations
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Ouverture',
                      '${session.soldeOuverture.toStringAsFixed(0)} F',
                      Icons.login,
                    ),
                  ),
                  if (isClosed) ...[
                    Expanded(
                      child: _buildInfoColumn(
                        'Fermeture',
                        '${session.soldeFermeture?.toStringAsFixed(0) ?? '0'} F',
                        Icons.logout,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Écart',
                        '${isPositive ? '+' : ''}${ecart.toStringAsFixed(0)} F',
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Date et durée
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(session.dateOuverture),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    session.formattedDuration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildInfoColumn(String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune session trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de changer la période',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(CashSession session) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700]),
            const SizedBox(width: 12),
            const Text('Détails de la session'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Caisse', session.nomCaisse),
              _buildDetailRow('Utilisateur', session.nomUtilisateur),
              const Divider(height: 24),
              _buildDetailRow('Ouverture', DateFormat('dd/MM/yyyy HH:mm').format(session.dateOuverture)),
              if (session.dateFermeture != null) _buildDetailRow('Fermeture', DateFormat('dd/MM/yyyy HH:mm').format(session.dateFermeture!)),
              _buildDetailRow('Durée', session.formattedDuration),
              const Divider(height: 24),
              _buildDetailRow('Solde ouverture', '${session.soldeOuverture.toStringAsFixed(0)} FCFA'),
              if (session.soldeAttendu != null) _buildDetailRow('Solde attendu', '${session.soldeAttendu!.toStringAsFixed(0)} FCFA'),
              if (session.soldeFermeture != null) _buildDetailRow('Solde déclaré', '${session.soldeFermeture!.toStringAsFixed(0)} FCFA'),
              if (session.ecart != null) ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (session.ecart! >= 0) ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (session.ecart! >= 0) ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Écart:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (session.ecart! >= 0) ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      Text(
                        '${session.ecart! >= 0 ? '+' : ''}${session.ecart!.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: (session.ecart! >= 0) ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/cash_session_model.dart';
import '../services/cash_session_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../financial_movements/services/financial_movement_service.dart';

/// Contrôleur pour la gestion des sessions de caisse
class CashSessionController extends GetxController {
  // Session active
  final Rx<CashSession?> activeSession = Rx<CashSession?>(null);

  // Historique des sessions
  final RxList<CashSession> sessionHistory = <CashSession>[].obs;

  // Caisses disponibles
  final RxList<dynamic> availableCashRegisters = <dynamic>[].obs;

  // État de chargement
  final RxBool isLoading = false.obs;
  final RxBool isConnecting = false.obs;
  final RxBool isDisconnecting = false.obs;

  // Filtre de période
  final Rx<SessionPeriodFilter> periodFilter = SessionPeriodFilter.all.obs;
  final Rx<DateTime?> customStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> customEndDate = Rx<DateTime?>(null);

  // Statistiques des mouvements financiers
  final RxDouble totalMovementsAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveSession();
  }

  /// Charger la session active
  Future<void> loadActiveSession() async {
    try {
      isLoading.value = true;
      final session = await CashSessionService.getActiveSession();
      activeSession.value = session;
    } catch (e) {
      print('Erreur lors du chargement de la session active: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger les caisses disponibles
  Future<void> loadAvailableCashRegisters() async {
    try {
      final cashRegisters = await CashSessionService.getAvailableCashRegisters();
      availableCashRegisters.assignAll(cashRegisters);
    } catch (e) {
      print('Erreur lors du chargement des caisses disponibles: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les caisses disponibles: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Se connecter à une caisse
  Future<bool> connectToCashRegister(int cashRegisterId, double soldeOuverture) async {
    try {
      isConnecting.value = true;
      final session = await CashSessionService.connectToCashRegister(cashRegisterId, soldeOuverture);
      activeSession.value = session;

      Get.snackbar(
        'Succès',
        'Connexion à la caisse réussie',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de se connecter à la caisse: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  /// Se déconnecter de la caisse (clôturer la session)
  Future<bool> disconnectFromCashRegister(double soldeFermeture) async {
    try {
      isDisconnecting.value = true;

      print('═══════════════════════════════════════════════════════════');
      print('🔍 FLUTTER - DÉBUT CLÔTURE DE CAISSE');
      print('═══════════════════════════════════════════════════════════');
      print('📤 Envoi au backend: soldeFermeture = $soldeFermeture FCFA');

      final session = await CashSessionService.disconnectFromCashRegister(soldeFermeture);

      print('📥 Réponse reçue du backend:');
      print('   Session ID: ${session.id}');
      print('   soldeOuverture: ${session.soldeOuverture}');
      print('   soldeAttendu: ${session.soldeAttendu}');
      print('   soldeFermeture: ${session.soldeFermeture}');
      print('   ecart: ${session.ecart}');
      print('   Type ecart: ${session.ecart.runtimeType}');
      print('═══════════════════════════════════════════════════════════');

      // Afficher le résumé de la session
      _showSessionSummary(session);

      activeSession.value = null;

      // Rafraîchir l'historique pour afficher la session clôturée
      print('🔄 Rafraîchissement de l\'historique...');
      await loadSessionHistory();

      return true;
    } catch (e) {
      print('❌ ERREUR Flutter: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de clôturer la session: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isDisconnecting.value = false;
    }
  }

  /// Afficher le résumé de la session après clôture
  void _showSessionSummary(CashSession session) {
    final ecart = session.ecart ?? 0.0;
    final isPositive = ecart >= 0;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isPositive ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Session clôturée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caisse: ${session.nomCaisse}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Solde d\'ouverture', '${session.soldeOuverture.toStringAsFixed(0)} FCFA'),
            _buildSummaryRow('Solde attendu', '${session.soldeAttendu?.toStringAsFixed(0) ?? '0'} FCFA'),
            _buildSummaryRow('Solde déclaré', '${session.soldeFermeture?.toStringAsFixed(0) ?? '0'} FCFA'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPositive ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Écart:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${ecart.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPositive) ...[
              const SizedBox(height: 12),
              Text(
                'Un écart négatif indique un manque dans la caisse.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Durée: ${session.formattedDuration}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Charger l'historique des sessions
  Future<void> loadSessionHistory() async {
    try {
      isLoading.value = true;

      DateTime? startDate;
      DateTime? endDate;

      if (periodFilter.value != SessionPeriodFilter.all) {
        if (periodFilter.value == SessionPeriodFilter.custom) {
          startDate = customStartDate.value;
          endDate = customEndDate.value;
          // Ajuster la date de fin pour inclure toute la journée
          if (endDate != null) {
            endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
          }
        } else {
          final range = periodFilter.value.getDateRange();
          startDate = range?.start;
          endDate = range?.end;
        }
      }

      print('🔍 Chargement historique avec filtres:');
      print('   Filtre: ${periodFilter.value.label}');
      print('   Date début: $startDate');
      print('   Date fin: $endDate');

      final sessions = await CashSessionService.getSessionHistory(
        startDate: startDate,
        endDate: endDate,
      );

      print('   Sessions reçues: ${sessions.length}');

      // Filtrer côté client pour s'assurer que les dates sont correctes
      List<CashSession> filteredSessions = sessions;

      if (startDate != null && endDate != null) {
        filteredSessions = sessions.where((session) {
          final sessionDate = session.dateFermeture ?? session.dateOuverture;
          final isInRange = sessionDate.isAfter(startDate!) && sessionDate.isBefore(endDate!);
          print('   Session ${session.id}: ${sessionDate} - Dans la plage: $isInRange');
          return isInRange;
        }).toList();
        print('   Sessions filtrées: ${filteredSessions.length}');
      }

      sessionHistory.assignAll(filteredSessions);

      // Calculer le total des mouvements financiers pour la période
      await _calculateFinancialMovementsTotal(startDate, endDate);
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'historique: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Changer le filtre de période
  void setPeriodFilter(SessionPeriodFilter filter) {
    periodFilter.value = filter;
    loadSessionHistory();
  }

  /// Définir une période personnalisée
  void setCustomPeriod(DateTime? start, DateTime? end) {
    customStartDate.value = start;
    customEndDate.value = end;
    if (start != null && end != null) {
      periodFilter.value = SessionPeriodFilter.custom;
      loadSessionHistory();
    }
  }

  /// Calculer le total des mouvements financiers pour une période
  Future<void> _calculateFinancialMovementsTotal(DateTime? startDate, DateTime? endDate) async {
    try {
      // Appeler le service des mouvements financiers pour obtenir les statistiques
      final financialMovementService = Get.find<FinancialMovementService>();

      final statistics = await financialMovementService.getStatistics(
        startDate: startDate,
        endDate: endDate,
        forceRefresh: false,
      );

      totalMovementsAmount.value = statistics.totalAmount;

      print('📊 Calcul mouvements financiers:');
      print('   Date début: $startDate');
      print('   Date fin: $endDate');
      print('   Total: ${totalMovementsAmount.value} FCFA');
    } catch (e) {
      print('❌ Erreur calcul mouvements: $e');
      totalMovementsAmount.value = 0.0;
    }
  }

  /// Vérifier si l'utilisateur a une session active
  bool get hasActiveSession => activeSession.value != null;

  /// Obtenir le solde actuel de la caisse (pour admin uniquement)
  double? get currentCashBalance {
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;

      if (currentUser != null && currentUser.role.isAdmin && activeSession.value != null) {
        return activeSession.value!.soldeAttendu;
      }
      return null;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification du rôle admin: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur peut voir le solde
  bool get canViewBalance {
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      return currentUser?.role.isAdmin ?? false;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification du rôle admin: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur peut effectuer des ventes (session active requise)
  bool get canMakeSales {
    return hasActiveSession;
  }

  /// Ajouter un montant au solde actuel de la caisse (lors d'une vente)
  void addToCurrentBalance(double amount) {
    if (activeSession.value != null) {
      // Mettre à jour le solde attendu localement
      final currentBalance = activeSession.value!.soldeAttendu ?? activeSession.value!.soldeOuverture;
      activeSession.value = activeSession.value!.copyWith(
        soldeAttendu: currentBalance + amount,
      );
      print('💰 Solde caisse mis à jour localement: +${amount.toStringAsFixed(0)} FCFA');
    }
  }

  /// Afficher le dialog de confirmation avant de clôturer la session
  Future<void> confirmDisconnectFromCashRegister() async {
    if (activeSession.value == null) {
      Get.snackbar(
        'Erreur',
        'Aucune session active',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    // Importer le dialog de clôture
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Text('Clôturer la session'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Êtes-vous sûr de vouloir clôturer cette session de caisse ?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Informations importantes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Vous devrez compter l\'argent dans la caisse\n'
                        '• L\'écart sera calculé automatiquement\n'
                        '• Cette action est irréversible',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                ),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      // Ouvrir le dialog de clôture
      _showCloseCashSessionDialog();
    }
  }

  /// Afficher le dialog de clôture de session
  void _showCloseCashSessionDialog() {
    // Import dynamique pour éviter les dépendances circulaires
    Get.dialog(
      _buildCloseCashSessionDialog(),
      barrierDismissible: false,
    );
  }

  /// Construire le dialog de clôture (version simplifiée inline)
  Widget _buildCloseCashSessionDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    double soldeFermeture = 0.0;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Row(
                      children: [
                        Icon(Icons.lock_clock, size: 28, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        const Text(
                          'Clôture de caisse',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Contenu
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Informations de session
                            if (activeSession.value != null) ...[
                              Card(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeSession.value!.nomCaisse,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Ouverture: ${activeSession.value!.soldeOuverture.toStringAsFixed(0)} FCFA'),
                                      Text('Durée: ${activeSession.value!.formattedDuration}'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Saisie montant
                            const Text(
                              'Montant en caisse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: amountController,
                              decoration: InputDecoration(
                                labelText: 'Montant total',
                                hintText: 'Entrez le montant compté',
                                suffixText: 'FCFA',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  soldeFermeture = double.tryParse(value) ?? 0.0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez saisir le montant';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Obx(() => ElevatedButton(
                                onPressed: isDisconnecting.value
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          final success = await disconnectFromCashRegister(soldeFermeture);
                                          if (success) {
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                ),
                                child: isDisconnecting.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Clôturer'),
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Afficher le dialog de connexion à une caisse
  Future<void> showConnectToCashRegisterDialog() async {
    // Charger les caisses disponibles
    await loadAvailableCashRegisters();

    if (availableCashRegisters.isEmpty) {
      Get.snackbar(
        'Information',
        'Aucune caisse disponible pour le moment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    // Afficher le dialog de sélection
    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: const Text('Se connecter à une caisse'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sélectionnez une caisse et saisissez le solde d\'ouverture'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableCashRegisters.length,
                  itemBuilder: (context, index) {
                    final cashRegister = availableCashRegisters[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.point_of_sale),
                        title: Text(cashRegister['nom'] ?? 'Caisse'),
                        subtitle: Text('ID: ${cashRegister['id']}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Get.back(result: cashRegister);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Demander le solde d'ouverture
      final soldeController = TextEditingController();
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Solde d\'ouverture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Caisse: ${result['nom']}'),
              const SizedBox(height: 16),
              TextField(
                controller: soldeController,
                decoration: const InputDecoration(
                  labelText: 'Solde d\'ouverture',
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final solde = double.tryParse(soldeController.text) ?? 0.0;
        await connectToCashRegister(result['id'] as int, solde);
      }
    }
  }
}

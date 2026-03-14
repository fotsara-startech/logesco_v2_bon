import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/cash_session_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Dialog pour clôturer une session de caisse
/// La caissière ne voit PAS le montant attendu, elle saisit uniquement ce qu'elle a
class CloseCashSessionDialog extends StatefulWidget {
  const CloseCashSessionDialog({super.key});

  @override
  State<CloseCashSessionDialog> createState() => _CloseCashSessionDialogState();
}

class _CloseCashSessionDialogState extends State<CloseCashSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  double _soldeFermeture = 0.0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<CashSessionController>();
    final authController = Get.find<AuthController>();
    final session = sessionController.activeSession.value;

    if (session == null) {
      return AlertDialog(
        title: Text('error'.tr),
        content: Text('cash_session_no_active_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      );
    }

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Icon(Icons.lock_clock, size: 28, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Text(
                      'cash_session_close_title'.tr,
                      style: const TextStyle(
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
                        // Informations de la session
                        _buildSessionInfo(session),

                        const SizedBox(height: 24),

                        // Saisie du montant en caisse
                        _buildAmountField(),

                        const SizedBox(height: 16),

                        // Avertissement pour admin (affiche le montant attendu)
                        if (authController.currentUser.value?.role.isAdmin ?? false) _buildAdminInfo(session),

                        const SizedBox(height: 16),

                        // Instructions
                        _buildInstructions(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Obx(() => ElevatedButton.icon(
                            onPressed: sessionController.isDisconnecting.value ? null : _closeCashSession,
                            icon: sessionController.isDisconnecting.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(sessionController.isDisconnecting.value ? 'cash_session_closing'.tr : 'cash_session_close_button'.tr),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo(session) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.point_of_sale, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  session.nomCaisse,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('cash_session_opening_balance'.tr, '${session.soldeOuverture.toStringAsFixed(0)} FCFA'),
            _buildInfoRow('cash_session_duration'.tr, session.formattedDuration),
            _buildInfoRow('users_username'.tr, session.nomUtilisateur),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cash_session_amount_in_register'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'cash_session_count_money_hint'.tr,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'cash_session_total_amount'.tr,
            hintText: 'cash_session_enter_amount_hint'.tr,
            suffixText: 'FCFA',
            suffixStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (value) {
            setState(() {
              _soldeFermeture = double.tryParse(value) ?? 0.0;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'cash_session_amount_required'.tr;
            }
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) {
              return 'cash_session_invalid_amount'.tr;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdminInfo(session) {
    final soldeAttendu = session.soldeAttendu ?? 0.0;
    final ecartPrevisionnel = _soldeFermeture - soldeAttendu;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'cash_session_admin_info'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('cash_session_expected_balance'.tr, '${soldeAttendu.toStringAsFixed(0)} FCFA'),
          if (_soldeFermeture > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ecartPrevisionnel >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'cash_session_variance'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ecartPrevisionnel >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    '${ecartPrevisionnel >= 0 ? '+' : ''}${ecartPrevisionnel.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ecartPrevisionnel >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'info'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'cash_session_instructions'.tr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeCashSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionController = Get.find<CashSessionController>();

    // Confirmation
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text('cash_session_confirm_close'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('cash_session_confirm_close_message'.tr),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'cash_session_declared_amount'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_soldeFermeture.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'cash_session_irreversible'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                ),
                child: Text('confirm'.tr),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await sessionController.disconnectFromCashRegister(_soldeFermeture);

    if (success) {
      Navigator.of(context).pop(); // Close the dialog
    }
  }
}

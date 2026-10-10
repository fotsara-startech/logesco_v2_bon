import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/decisions_service.dart';
import '../views/decision_center_page.dart';

/// Bannière « Décisions à prendre » : visible seulement s'il existe des cas où l'application ne
/// peut pas trancher seule (stock incohérent, réception peut-être en double...). Invisible sinon.
class DecisionsAlert extends StatefulWidget {
  /// Marges autour de la bannière (selon l'écran qui l'accueille)
  final EdgeInsetsGeometry margin;

  /// Pour les tests : service de remplacement
  final DecisionsService? service;

  const DecisionsAlert({super.key, this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 0), this.service});

  @override
  State<DecisionsAlert> createState() => _DecisionsAlertState();
}

class _DecisionsAlertState extends State<DecisionsAlert> {
  late final DecisionsService _service = widget.service ?? DecisionsService();
  List<DecisionCase> _cases = const [];
  int _conflits = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.fetchAll();
    if (mounted && data != null) {
      setState(() {
        _cases = data.cases;
        _conflits = data.conflits.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cases.isEmpty && _conflits == 0) return const SizedBox.shrink();
    final unites = _cases.fold<int>(0, (s, c) => s + c.unitesVenduesSansSortie);

    return Padding(
      padding: widget.margin,
      child: Material(
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.orange.shade300)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            await Get.to(() => DecisionCenterPage(service: widget.service));
            _load(); // des cas ont pu être traités
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.rule, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _conflits == 0 ? '${_cases.length} décision(s) à prendre sur le stock' : '${_cases.length + _conflits} décision(s) à prendre',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (_conflits > 0)
                        Text("$_conflits conflit(s) de synchronisation bloquent l'envoi de données", style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                      if (unites > 0)
                        Text("$unites unité(s) vendues n'ont jamais diminué le stock", style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

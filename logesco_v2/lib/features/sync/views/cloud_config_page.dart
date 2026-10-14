import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/backend_service.dart' if (dart.library.html) '../../../core/services/backend_service_stub.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../controllers/sync_controller.dart';
import '../services/cloud_config_service.dart';

/// Connexion au cloud (base Neon) : le lien se saisit ici, au lieu de modifier le fichier .env à la main.
///
/// Réservée aux administrateurs, et seulement sur le poste qui héberge le serveur (le serveur doit redémarrer pour
/// utiliser le nouveau lien ; ni en mode client réseau, ni sur le web).
///
/// Le lien contient le mot de passe de la base : il est masqué à la saisie, jamais réaffiché, et le serveur n'en
/// renvoie que l'adresse, la base et l'utilisateur.
class CloudConfigPage extends StatefulWidget {
  const CloudConfigPage({super.key});

  /// L'écran n'a de sens que sur le poste qui héberge le serveur, pour un administrateur
  static bool get disponible {
    if (kIsWeb || AppConfig.isClientMode) return false;
    try {
      return Get.find<PermissionService>().isAdmin;
    } catch (_) {
      return false;
    }
  }

  @override
  State<CloudConfigPage> createState() => _CloudConfigPageState();
}

class _CloudConfigPageState extends State<CloudConfigPage> {
  final CloudConfigService _service = CloudConfigService();
  final TextEditingController _lien = TextEditingController();

  CloudConfig? _config;
  String? _erreurLecture;
  CloudTestResult? _test;
  String? _erreurSaisie;
  bool _masque = true;
  bool _occupe = false;
  String _etape = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _lien.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final c = await _service.lire();
      if (mounted) {
        setState(() {
          _config = c;
          _erreurLecture = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erreurLecture = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _messageErreur(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _coller() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final texte = (data?.text ?? '').trim();
    if (texte.isEmpty) return;
    setState(() {
      _lien.text = texte;
      _test = null;
      _erreurSaisie = null;
    });
  }

  Future<void> _tester() async {
    final probleme = verifierLienNeon(_lien.text);
    if (probleme != null) {
      setState(() => _erreurSaisie = probleme);
      return;
    }
    setState(() {
      _erreurSaisie = null;
      _test = null;
      _occupe = true;
      _etape = 'Test de la connexion...';
    });
    try {
      final r = await _service.tester(_lien.text.trim());
      if (mounted) setState(() => _test = r);
    } catch (e) {
      if (mounted) setState(() => _erreurSaisie = _messageErreur(e));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _enregistrer() async {
    final probleme = verifierLienNeon(_lien.text);
    if (probleme != null) {
      setState(() => _erreurSaisie = probleme);
      return;
    }
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer et redémarrer le serveur ?'),
        content: const Text(
          "Le lien sera enregistré, puis le serveur de LOGESCO redémarrera pour utiliser le cloud. "
          "Cela prend environ une minute : les autres postes du réseau perdront la connexion un instant.\n\n"
          "Faites-le en dehors des heures de vente si possible.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer et redémarrer')),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() {
      _occupe = true;
      _erreurSaisie = null;
      _etape = 'Vérification et enregistrement du lien...';
    });
    try {
      await _service.enregistrer(_lien.text.trim());
      // Le mot de passe n'a plus de raison de rester à l'écran
      _lien.clear();
      if (mounted) setState(() => _etape = 'Redémarrage du serveur...');
      final backend = BackendService();
      final relance = await backend.restart();
      final pret = relance && await backend.waitUntilReady(maxSeconds: 90);
      if (!pret) {
        if (mounted) {
          setState(() => _erreurSaisie = "Le lien est enregistré, mais le serveur n'a pas redémarré. Fermez puis rouvrez LOGESCO : il utilisera le cloud au prochain démarrage.");
        }
        return;
      }
      if (mounted) setState(() => _etape = 'Connexion au cloud...');
      await _charger();
      if (Get.isRegistered<SyncController>()) await Get.find<SyncController>().refresh();
      if (mounted) setState(() => _test = null);
      SnackbarHelper.success('Connecté au cloud. La synchronisation démarre.');
    } catch (e) {
      if (mounted) setState(() => _erreurSaisie = _messageErreur(e));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  // ── Affichage ─────────────────────────────────────────────────────────────────────────────────────

  Widget _carteEtat() {
    final c = _config;
    if (_erreurLecture != null) {
      return Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Text(_erreurLecture!)));
    }
    if (c == null) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chargement...')));

    final Color fond = c.active ? Colors.green.shade50 : Colors.blueGrey.shade50;
    return Card(
      color: fond,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(c.active ? Icons.cloud_done : Icons.computer, color: c.active ? Colors.green.shade700 : Colors.blueGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.active ? 'Connecté au cloud (Neon)' : 'Mode 100 % local : pas de cloud', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ]),
            if (c.active && c.infoActive != null) ...[
              const SizedBox(height: 6),
              Text('Serveur : ${c.infoActive!.hote}', style: const TextStyle(fontSize: 12)),
              Text('Base : ${c.infoActive!.base}', style: const TextStyle(fontSize: 12)),
            ],
            if (!c.active)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  "Vos données restent sur cet ordinateur. Pour synchroniser plusieurs postes ou sauvegarder dans le cloud, saisissez le lien de votre base Neon ci-dessous.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (c.redemarrageNecessaire) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  Icon(Icons.restart_alt, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Un lien est enregistré mais le serveur n'en tient pas encore compte : fermez puis rouvrez LOGESCO pour l'activer.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultatTest(CloudTestResult t) {
    final ok = t.ok && t.schemaPret;
    final couleur = ok ? Colors.green : (t.ok ? Colors.orange : Colors.red);
    final lignes = <Widget>[
      Row(children: [
        Icon(ok ? Icons.check_circle : (t.ok ? Icons.warning_amber_rounded : Icons.error_outline), color: couleur.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(t.message, style: TextStyle(fontWeight: FontWeight.w600, color: couleur.shade900))),
      ]),
    ];
    if (t.ok && t.info != null) {
      lignes.add(Padding(padding: const EdgeInsets.only(top: 6), child: Text('Serveur : ${t.info!.hote} · Base : ${t.info!.base}', style: const TextStyle(fontSize: 12))));
    }
    if (t.ok && !t.schemaPret) {
      lignes.add(Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          "Il manque : ${t.tablesManquantes.join(', ')}. Demandez à votre prestataire d'installer le schéma LOGESCO dans cette base, puis recommencez.",
          style: const TextStyle(fontSize: 12),
        ),
      ));
    }
    if (ok && t.donnees != null) {
      final d = t.donnees!;
      lignes.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          t.cloudDejaRempli
              ? "Ce cloud contient déjà des données (${d['produits']} produit(s), ${d['clients']} client(s), ${d['ventes']} vente(s)). "
                  "Les données déjà présentes sur cet ordinateur ne seront PAS envoyées par-dessus : celles du cloud sont conservées."
              : "Ce cloud est vide : les données de cet ordinateur lui seront envoyées automatiquement.",
          style: const TextStyle(fontSize: 12),
        ),
      ));
    }
    return Card(color: couleur.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lignes)));
  }

  @override
  Widget build(BuildContext context) {
    if (!CloudConfigPage.disponible) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connexion au cloud')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text("Cet écran est réservé à l'administrateur, sur l'ordinateur qui héberge le serveur LOGESCO.", textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final peutEnregistrer = !_occupe && _test != null && _test!.ok && _test!.schemaPret;

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion au cloud (Neon)')),
      body: AbsorbPointer(
        absorbing: _occupe,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _carteEtat(),
            const SizedBox(height: 16),
            Text(_config?.active == true ? 'Changer de base cloud' : 'Connecter une base cloud', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              "Dans la console Neon, ouvrez votre projet, cliquez sur « Connect » et copiez la « Connection string ». Elle commence par postgresql://",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lien,
              obscureText: _masque,
              enableSuggestions: false,
              autocorrect: false,
              maxLines: 1,
              onChanged: (_) => setState(() {
                _test = null;
                _erreurSaisie = null;
              }),
              decoration: InputDecoration(
                labelText: 'Lien de connexion Neon',
                hintText: 'postgresql://utilisateur:motdepasse@...neon.tech/base',
                border: const OutlineInputBorder(),
                errorText: _erreurSaisie,
                errorMaxLines: 4,
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'Coller', icon: const Icon(Icons.content_paste), onPressed: _coller),
                  IconButton(
                    tooltip: _masque ? 'Afficher' : 'Masquer',
                    icon: Icon(_masque ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _masque = !_masque),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 4),
            Text("Ce lien contient le mot de passe de votre base : ne le partagez avec personne.", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _occupe ? null : _tester,
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Tester la connexion'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: peutEnregistrer ? _enregistrer : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer et redémarrer'),
                ),
              ),
            ]),
            if (_test == null && !_occupe)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("Testez d'abord la connexion : l'enregistrement n'est possible que si elle réussit.", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ),
            if (_occupe) ...[
              const SizedBox(height: 16),
              Row(children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(child: Text(_etape)),
              ]),
            ],
            if (_test != null) ...[
              const SizedBox(height: 16),
              _resultatTest(_test!),
            ],
          ],
        ),
      ),
    );
  }
}

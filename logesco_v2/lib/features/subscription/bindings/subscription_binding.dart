import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../controllers/subscription_controller.dart';
import '../services/interfaces/i_subscription_manager.dart';
import '../services/interfaces/i_license_service.dart';
import '../services/interfaces/i_device_service.dart';

import '../services/implementations/subscription_manager.dart';
import '../services/implementations/license_service.dart';
import '../services/implementations/device_service.dart';
import '../services/implementations/crypto_service.dart';

/// Binding pour l'injection de dépendances des services d'abonnement
class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    // Services de base
    Get.lazyPut<FlutterSecureStorage>(() => const FlutterSecureStorage(), fenix: true);

    // Services d'infrastructure
    Get.lazyPut<CryptoService>(() => CryptoService(), fenix: true);
    Get.lazyPut<IDeviceService>(() => DeviceService(), fenix: true);
    Get.lazyPut<ILicenseService>(
        () => LicenseService(
              cryptoService: Get.find<CryptoService>(),
              deviceService: Get.find<IDeviceService>(),
            ),
        fenix: true);

    // Gestionnaire principal d'abonnements
    Get.lazyPut<ISubscriptionManager>(
        () => SubscriptionManager(
              licenseService: Get.find<ILicenseService>(),
              deviceService: Get.find<IDeviceService>(),
              cryptoService: Get.find<CryptoService>(),
              secureStorage: Get.find<FlutterSecureStorage>(),
            ),
        fenix: true);

    // Contrôleur d'abonnement
    Get.lazyPut<SubscriptionController>(
        () => SubscriptionController(
              subscriptionManager: Get.find<ISubscriptionManager>(),
            ),
        fenix: true);
  }
}

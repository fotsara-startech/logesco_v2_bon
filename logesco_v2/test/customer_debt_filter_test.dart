import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/customers/controllers/customer_controller.dart';
import 'package:logesco_v2/features/customers/models/customer.dart';
import 'package:logesco_v2/features/customers/services/customer_service.dart';

Customer _c(int id, double solde) => Customer(
      id: id,
      nom: 'C$id',
      solde: solde,
      dateCreation: DateTime(2026),
      dateModification: DateTime(2026),
    );

/// Simule un ANCIEN serveur : ignore le paramètre `dette` et renvoie tout.
class _OldServer implements CustomerService {
  final all = [_c(1, -4000), _c(2, 0), _c(3, 500), _c(4, -100)];

  @override
  Future<List<Customer>> getCustomers({String? search, int page = 1, int limit = 20, String? dette}) async => page == 1 ? all : [];

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('filtre dette / sans dette appliqué même si le serveur ignore le paramètre', () async {
    Get.put<CustomerService>(_OldServer());
    final c = CustomerController();
    await c.loadCustomers(refresh: true);
    expect(c.customers.map((e) => e.id), [1, 2, 3, 4]);

    c.setDebtFilter('debt');
    await Future.delayed(const Duration(milliseconds: 100));
    expect(c.customers.map((e) => e.id), [1, 4]);

    c.setDebtFilter('nodebt');
    await Future.delayed(const Duration(milliseconds: 100));
    expect(c.customers.map((e) => e.id), [2, 3]);

    c.resetDebtFilter();
    await Future.delayed(const Duration(milliseconds: 100));
    expect(c.customers.map((e) => e.id), [1, 2, 3, 4]);
  });
}

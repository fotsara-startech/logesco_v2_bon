import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/sync/services/sync_status_service.dart';

SyncStatus _status({int pending = 3, DateTime? oldest}) => SyncStatus.fromJson({
      'mode': 'offline-fallback',
      'cloudEnabled': true,
      'cloudAvailable': false,
      'pendingCount': pending,
      'pendingByTable': {'ventes': pending},
      'failedCount': 0,
      'oldestPendingAt': oldest?.toUtc().toIso8601String(),
    });

void main() {
  test('alerte à partir de 24 h d\'attente', () {
    final now = DateTime.now();
    expect(_status(oldest: now.subtract(const Duration(hours: 2))).isStale, false);
    expect(_status(oldest: now.subtract(const Duration(hours: 23, minutes: 50))).isStale, false);
    expect(_status(oldest: now.subtract(const Duration(hours: 25))).isStale, true);
  });

  test('pas d\'alerte sans opération en attente, ni sans date', () {
    final vieux = DateTime.now().subtract(const Duration(days: 5));
    expect(_status(pending: 0, oldest: vieux).isStale, false);
    expect(_status(pending: 3, oldest: null).isStale, false);
  });

  test('libellé d\'ancienneté', () {
    final now = DateTime.now();
    expect(_status(oldest: now.subtract(const Duration(hours: 30))).pendingAgeLabel, '30 heures');
    expect(_status(oldest: now.subtract(const Duration(days: 4, hours: 2))).pendingAgeLabel, '4 jours');
  });
}

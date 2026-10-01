import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 229 keeps Driver GPS upload and sync health production wired', () {
    final sync = File(
      'lib/features/location/data/driver_location_sync_repository.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/features/background_location/data/driver_background_location_controller.dart',
    ).readAsStringSync();
    final models = File(
      'lib/features/background_location/domain/driver_background_location_models.dart',
    ).readAsStringSync();

    expect(sync, contains("'/v1/driver/location'"));
    expect(sync, contains("'latitude': fix.coordinates.latitude"));
    expect(sync, contains("'timestamp': fix.capturedAt.toUtc().toIso8601String()"));
    expect(controller, contains('_syncServerFix(fix, generation)'));
    expect(controller, contains('await locationSyncRepository.sync(fix)'));
    expect(models, contains('lastServerSyncAt'));
    expect(models, contains('serverSyncError'));
  });
}

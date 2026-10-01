import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 228 exposes whether background GPS reached GETIN', () {
    final controller = File(
      'lib/features/background_location/data/driver_background_location_controller.dart',
    ).readAsStringSync();
    final models = File(
      'lib/features/background_location/domain/driver_background_location_models.dart',
    ).readAsStringSync();

    expect(controller, contains('_syncServerFix(fix, generation)'));
    expect(controller, contains('await locationSyncRepository.sync(fix)'));
    expect(controller, contains('lastServerSyncAt: DateTime.now()'));
    expect(controller, contains('latest position did not reach GETIN'));
    expect(models, contains('final DateTime? lastServerSyncAt'));
    expect(models, contains('final String? serverSyncError'));
    expect(models, contains('clearServerSyncError'));
  });
}

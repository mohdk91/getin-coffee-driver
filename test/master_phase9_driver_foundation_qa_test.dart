import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Master Phase 9 production Driver repositories are wired', () {
    final files = <String>[
      'lib/core/data/driver_api_context.dart',
      'lib/core/storage/driver_token_store.dart',
      'lib/features/auth/data/driver_auth_repository.dart',
      'lib/features/registration/data/driver_registration_repository.dart',
      'lib/features/profile/data/driver_profile_repository.dart',
      'lib/features/verification/data/driver_verification_repository.dart',
      'lib/features/documents/data/driver_documents_repository.dart',
      'lib/features/vehicle/data/driver_vehicle_repository.dart',
      'lib/features/security/data/driver_sessions_repository.dart',
      'lib/features/security/data/driver_security_repository.dart'
    ];
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(
          source.contains('ApiDriver') ||
              source.contains('DriverApiContext') ||
              source.contains('DriverTokenStore') ||
              source.contains('DriverSessionsRepository'),
          isTrue,
          reason: path);
    }
  });
}

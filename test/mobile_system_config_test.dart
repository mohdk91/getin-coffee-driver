import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/system/mobile_system_config.dart';

void main() {
  test('driver parses shared Laravel system config contract', () {
    final config = MobileSystemConfig.fromApiEnvelope(<String, dynamic>{
      'data': <String, dynamic>{
        'api_version': 'v1',
        'mobile_apps': <String, dynamic>{
          'ios': <String, dynamic>{
            'minimum_version': '1.0.0',
            'latest_version': '1.0.0',
          },
          'android': <String, dynamic>{
            'minimum_version': '1.0.0',
            'latest_version': '1.1.0',
          },
          'force_update_enabled': false,
          'maintenance': <String, dynamic>{
            'enabled': true,
            'message': 'Maintenance',
          },
        },
        'client': <String, dynamic>{'platform': 'android'},
        'languages': <String, dynamic>{
          'default': 'en',
          'supported': <String>['en', 'ar'],
        },
      },
    });

    expect(config.maintenance.enabled, isTrue);
    expect(config.maintenance.message, 'Maintenance');
    expect(config.android.latestVersion, '1.1.0');
  });
}

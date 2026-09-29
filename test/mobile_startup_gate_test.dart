import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/system/app_runtime_info.dart';
import 'package:getin_driver/core/system/mobile_system_config.dart';
import 'package:getin_driver/core/system/mobile_system_config_repository.dart';
import 'package:getin_driver/core/widgets/mobile_startup_gate.dart';

class _Runtime implements AppRuntimeInfoProvider {
  const _Runtime();
  @override
  Future<AppRuntimeInfo> load() async => const AppRuntimeInfo(
        platform: 'android',
        version: '1.0.0',
        buildNumber: '1',
      );
}

class _Loader implements MobileSystemConfigLoader {
  final bool updateRequired;
  const _Loader(this.updateRequired);

  @override
  Future<MobileSystemConfig> fetch(
      {required String platform, required String version}) async {
    return MobileSystemConfig.fromApiEnvelope(<String, dynamic>{
      'data': <String, dynamic>{
        'mobile_apps': <String, dynamic>{
          'ios': <String, dynamic>{},
          'android': <String, dynamic>{},
          'maintenance': <String, dynamic>{'enabled': false},
        },
        'client': <String, dynamic>{
          'platform': platform,
          'version': version,
          'update_required': updateRequired,
          'latest_version': '2.0.0',
        },
        'languages': <String, dynamic>{
          'supported': <String>['en']
        },
      },
    });
  }
}

void main() {
  const appConfig = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://example.test/api',
  );

  testWidgets('startup gate blocks clients requiring an update',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MobileStartupGate(
          appConfig: appConfig,
          loader: _Loader(true),
          runtimeInfoProvider: _Runtime(),
          child: Text('APP READY'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('APP READY'), findsNothing);
  });

  testWidgets('startup gate releases compatible clients', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MobileStartupGate(
          appConfig: appConfig,
          loader: _Loader(false),
          runtimeInfoProvider: _Runtime(),
          child: Text('APP READY'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APP READY'), findsOneWidget);
  });
}

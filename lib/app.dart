import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/system/mobile_system_config_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mobile_startup_gate.dart';
import 'features/splash/driver_splash_screen.dart';
import 'features/splash/driver_video_splash.dart';

class GetinDriverApp extends StatelessWidget {
  final AppConfig config;

  const GetinDriverApp({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Getin Driver',
      theme: AppTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
      home: MobileStartupGate(
        appConfig: config,
        appKind: MobileAppKind.driver,
        loader: config.isApiConfigured
            ? MobileSystemConfigRepository(ApiClient(config))
            : null,
        loadingChild: const DriverVideoSplash(),
        minimumLoadingDuration: const Duration(milliseconds: 3050),
        child: DriverSplashScreen(config: config),
      ),
    );
  }
}

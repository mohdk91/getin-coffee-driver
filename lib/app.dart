import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/driver_splash_screen.dart';

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
      home: DriverSplashScreen(config: config),
    );
  }
}

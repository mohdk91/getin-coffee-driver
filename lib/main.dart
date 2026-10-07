import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/push/driver_push_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  // Paint the Driver splash immediately. Firebase/push initialization is
  // deliberately best-effort and must never delay the first Flutter frame.
  runApp(GetinDriverApp(config: config));
  unawaited(DriverPushService.instance.initialize(config));
}

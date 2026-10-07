import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_config.dart';
import '../data/driver_api_context.dart';
import '../device/driver_device_registrar.dart';
import 'driver_push_coordinator.dart';
import 'driver_push_models.dart';

@pragma('vm:entry-point')
Future<void> getinDriverFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

class DriverPushService {
  DriverPushService._();

  static final DriverPushService instance = DriverPushService._();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  AppConfig? _config;
  bool _initialized = false;

  Future<void> initialize(AppConfig config) async {
    if (_initialized || !config.isApiConfigured) return;
    _config = config;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        getinDriverFirebaseMessagingBackgroundHandler,
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        (message) => _publish(message, DriverPushOrigin.foreground),
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _publish(message, DriverPushOrigin.backgroundTap),
      );
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => unawaited(_registerRefreshedToken(token)),
      );

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _publish(initialMessage, DriverPushOrigin.terminatedTap);
      }

      _initialized = true;
    } catch (_) {
      // Firebase startup must never prevent the Driver App from launching.
      // The release gate verifies that native Firebase configuration exists.
    }
  }

  void _publish(RemoteMessage message, DriverPushOrigin origin) {
    DriverPushCoordinator.instance.publish(
      DriverPushIntent.fromData(
        origin: origin,
        data: message.data,
        title: message.notification?.title,
        body: message.notification?.body,
      ),
    );
  }

  Future<void> _registerRefreshedToken(String token) async {
    final config = _config;
    final normalized = token.trim();
    if (config == null || normalized.isEmpty || !config.isApiConfigured) {
      return;
    }

    await DriverDeviceRegistrar(DriverApiContext.create(config))
        .registerBestEffort(
      pushToken: normalized,
      requestPushPermission: false,
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _config = null;
    _initialized = false;
  }
}

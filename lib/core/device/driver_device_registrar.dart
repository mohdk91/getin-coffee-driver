import 'dart:io';
import 'dart:math';

import 'package:package_info_plus/package_info_plus.dart';

import '../data/driver_api_context.dart';
import '../push/driver_push_token_provider.dart';
import '../storage/secure_store.dart';

class DriverDeviceRegistrar {
  final DriverApiContext context;
  final DriverPushTokenProvider pushTokenProvider;

  DriverDeviceRegistrar(
    this.context, {
    DriverPushTokenProvider? pushTokenProvider,
  }) : pushTokenProvider =
            pushTokenProvider ?? FirebaseDriverPushTokenProvider();

  Future<bool> registerBestEffort({
    String? pushToken,
    bool requestPushPermission = true,
  }) async {
    try {
      final payload = await _basePayload();
      final resolvedPushToken = pushToken?.trim().isNotEmpty == true
          ? pushToken!.trim()
          : await pushTokenProvider.currentToken(
              requestPermission: requestPushPermission,
            );
      if (resolvedPushToken != null && resolvedPushToken.isNotEmpty) {
        payload['push_token'] = resolvedPushToken;
      }

      await context.apiClient.putJson(
        '/v1/driver/device',
        authenticated: true,
        body: payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearPushTokenBestEffort() async {
    var serverCleared = false;
    try {
      final payload = await _basePayload();
      payload['push_token'] = null;
      await context.apiClient.putJson(
        '/v1/driver/device',
        authenticated: true,
        body: payload,
      );
      serverCleared = true;
    } catch (_) {
      serverCleared = false;
    }

    await pushTokenProvider.deleteToken();
    return serverCleared;
  }

  Future<Map<String, Object?>> _basePayload() async {
    var deviceId =
        await context.secureStore.read(SecureStoreKeys.driverDeviceId);
    if (deviceId == null || deviceId.length < 8) {
      final random = Random.secure();
      deviceId = List<int>.generate(16, (_) => random.nextInt(256))
          .map((value) => value.toRadixString(16).padLeft(2, '0'))
          .join();
      await context.secureStore.write(SecureStoreKeys.driverDeviceId, deviceId);
    }

    final package = await PackageInfo.fromPlatform();
    return <String, Object?>{
      'device_id': deviceId,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'device_name': '${Platform.operatingSystem} device',
      'app_version': package.version,
      'os_version': Platform.operatingSystemVersion,
    };
  }
}

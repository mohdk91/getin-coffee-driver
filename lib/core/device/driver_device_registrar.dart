import 'dart:io';
import 'dart:math';

import 'package:package_info_plus/package_info_plus.dart';

import '../data/driver_api_context.dart';
import '../storage/secure_store.dart';

class DriverDeviceRegistrar {
  final DriverApiContext context;
  const DriverDeviceRegistrar(this.context);

  Future<bool> registerBestEffort() async {
    try {
      var deviceId =
          await context.secureStore.read(SecureStoreKeys.driverDeviceId);
      if (deviceId == null || deviceId.length < 8) {
        final random = Random.secure();
        deviceId = List<int>.generate(16, (_) => random.nextInt(256))
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join();
        await context.secureStore
            .write(SecureStoreKeys.driverDeviceId, deviceId);
      }
      final package = await PackageInfo.fromPlatform();
      await context.apiClient.putJson(
        '/v1/driver/device',
        authenticated: true,
        body: <String, Object?>{
          'device_id': deviceId,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'device_name': '${Platform.operatingSystem} device',
          'app_version': package.version,
          'os_version': Platform.operatingSystemVersion,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

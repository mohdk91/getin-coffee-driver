import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppRuntimeInfo {
  final String platform;
  final String version;
  final String buildNumber;

  const AppRuntimeInfo({
    required this.platform,
    required this.version,
    required this.buildNumber,
  });
}

abstract class AppRuntimeInfoProvider {
  Future<AppRuntimeInfo> load();
}

class PackageAppRuntimeInfoProvider implements AppRuntimeInfoProvider {
  const PackageAppRuntimeInfoProvider();

  @override
  Future<AppRuntimeInfo> load() async {
    final package = await PackageInfo.fromPlatform();
    return AppRuntimeInfo(
      platform: _platformName(defaultTargetPlatform),
      version: package.version,
      buildNumber: package.buildNumber,
    );
  }

  static String _platformName(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };
  }
}

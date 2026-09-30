import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../system/mobile_system_config.dart';

class MobileSystemConfigCache {
  static const _keyPrefix = 'getin.mobile_system_config';

  final Duration maxAge;

  const MobileSystemConfigCache({
    this.maxAge = const Duration(hours: 6),
  });

  Future<void> write(
    MobileSystemConfig config, {
    required String platform,
    required String version,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _clientKey(platform, version);
    await preferences.setString(
      '$key.payload',
      jsonEncode(<String, dynamic>{'data': config.toJson()}),
    );
    await preferences.setString(
      '$key.cached_at',
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<MobileSystemConfig?> readFresh({
    required String platform,
    required String version,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _clientKey(platform, version);
    final raw = preferences.getString('$key.payload');
    final cachedAtRaw = preferences.getString('$key.cached_at');

    if (raw == null || cachedAtRaw == null) return null;

    final cachedAt = DateTime.tryParse(cachedAtRaw)?.toUtc();
    if (cachedAt == null) return null;

    final age = DateTime.now().toUtc().difference(cachedAt);
    if (age.isNegative || age > maxAge) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return MobileSystemConfig.fromApiEnvelope(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear({
    required String platform,
    required String version,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _clientKey(platform, version);
    await preferences.remove('$key.payload');
    await preferences.remove('$key.cached_at');
  }

  String _clientKey(String platform, String version) {
    final safePlatform =
        platform.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final safeVersion =
        version.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return '$_keyPrefix.$safePlatform.$safeVersion';
  }
}

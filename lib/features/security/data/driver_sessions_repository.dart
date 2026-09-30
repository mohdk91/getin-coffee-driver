import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_security_models.dart';

class DriverSessionsRepository {
  final DriverApiContext context;
  const DriverSessionsRepository(this.context);
  Future<List<DriverActiveSession>> load() async {
    final items = DriverApiContext.dataList(await context.apiClient
        .getJson('/v1/driver/sessions', authenticated: true));
    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final device = item['device'] is Map
          ? Map<String, dynamic>.from(item['device'] as Map)
          : const <String, dynamic>{};
      return DriverActiveSession(
          id: item['id']?.toString() ?? '',
          deviceName: device['device_name']?.toString() ??
              item['name']?.toString() ??
              'Driver session',
          platform: device['platform']?.toString() ?? 'GETIN Driver',
          locationLabel: '',
          lastActiveAt:
              DateTime.tryParse(item['last_active_at']?.toString() ?? '') ??
                  DateTime.now(),
          isCurrent: item['is_current'] == true);
    }).toList(growable: false);
  }

  Future<void> revoke(String sessionId) => context.apiClient
      .deleteJson('/v1/driver/sessions/$sessionId', authenticated: true)
      .then((_) {});
  Future<void> revokeCurrent() => context.apiClient
      .deleteJson('/v1/driver/sessions/current', authenticated: true)
      .then((_) {});
  Future<void> revokeAll() => context.apiClient
      .deleteJson('/v1/driver/sessions', authenticated: true)
      .then((_) {});
  Future<String?> safeError(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

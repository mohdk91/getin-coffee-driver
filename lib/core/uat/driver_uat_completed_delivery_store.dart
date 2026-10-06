import 'dart:convert';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

class DriverUatCompletedDeliveryRecord {
  final String orderNumber;
  final String pickupBranch;
  final String destinationArea;
  final DateTime completedAt;
  final int bagCount;
  final double driverEarning;
  final String currencyCode;

  const DriverUatCompletedDeliveryRecord({
    required this.orderNumber,
    required this.pickupBranch,
    required this.destinationArea,
    required this.completedAt,
    required this.bagCount,
    required this.driverEarning,
    required this.currencyCode,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'order_number': orderNumber,
        'pickup_branch': pickupBranch,
        'destination_area': destinationArea,
        'completed_at': completedAt.toIso8601String(),
        'bag_count': bagCount,
        'driver_earning': driverEarning,
        'currency_code': currencyCode,
      };

  static DriverUatCompletedDeliveryRecord? fromJson(
    Map<String, dynamic> json,
  ) {
    final orderNumber = json['order_number']?.toString().trim() ?? '';
    final pickupBranch = json['pickup_branch']?.toString().trim() ?? '';
    final destinationArea = json['destination_area']?.toString().trim() ?? '';
    final completedAt =
        DateTime.tryParse(json['completed_at']?.toString() ?? '');
    if (orderNumber.isEmpty ||
        pickupBranch.isEmpty ||
        destinationArea.isEmpty ||
        completedAt == null) {
      return null;
    }

    final currency = json['currency_code']?.toString().trim() ?? '';
    return DriverUatCompletedDeliveryRecord(
      orderNumber: orderNumber,
      pickupBranch: pickupBranch,
      destinationArea: destinationArea,
      completedAt: completedAt,
      bagCount: int.tryParse(json['bag_count']?.toString() ?? '') ?? 0,
      driverEarning:
          double.tryParse(json['driver_earning']?.toString() ?? '') ?? 0,
      currencyCode: currency.isEmpty ? 'EGP' : currency,
    );
  }
}

abstract interface class DriverUatCompletedDeliveryStore {
  Future<List<DriverUatCompletedDeliveryRecord>> load();

  Future<void> upsert(DriverUatCompletedDeliveryRecord record);

  Future<void> clear();
}

class SharedPreferencesDriverUatCompletedDeliveryStore
    implements DriverUatCompletedDeliveryStore {
  static const String storageKey = 'getin_driver_uat_completed_deliveries_v1';
  static const int _maxRecords = 50;

  final bool forcePersistenceInTests;

  const SharedPreferencesDriverUatCompletedDeliveryStore({
    this.forcePersistenceInTests = false,
  });

  bool get _skipPlatformPersistenceForFlutterTest =>
      !forcePersistenceInTests &&
      Platform.environment.containsKey('FLUTTER_TEST');

  Future<SharedPreferences?> _preferences() async {
    // flutter test runs on a VM without the real SharedPreferences plugin.
    // Starting the plugin there can leave a platform-channel Future or timeout
    // Timer pending, which prevents pumpAndSettle() from completing. Older UAT
    // tests are not testing persistence, so skip the platform plugin entirely
    // in that environment. Task 252 persistence tests explicitly opt in after
    // installing SharedPreferences mock values.
    if (_skipPlatformPersistenceForFlutterTest) {
      return null;
    }

    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DriverUatCompletedDeliveryRecord>> load() async {
    final preferences = await _preferences();
    if (preferences == null) {
      return const <DriverUatCompletedDeliveryRecord>[];
    }

    try {
      final raw = preferences.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <DriverUatCompletedDeliveryRecord>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <DriverUatCompletedDeliveryRecord>[];
      }
      final records = <DriverUatCompletedDeliveryRecord>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final record = DriverUatCompletedDeliveryRecord.fromJson(
          Map<String, dynamic>.from(entry),
        );
        if (record != null) {
          records.add(record);
        }
      }
      records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return List<DriverUatCompletedDeliveryRecord>.unmodifiable(records);
    } catch (_) {
      return const <DriverUatCompletedDeliveryRecord>[];
    }
  }

  @override
  Future<void> upsert(DriverUatCompletedDeliveryRecord record) async {
    final preferences = await _preferences();
    if (preferences == null) {
      return;
    }

    try {
      final raw = preferences.getString(storageKey);
      final records = <DriverUatCompletedDeliveryRecord>[];
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is! Map) continue;
            final existing = DriverUatCompletedDeliveryRecord.fromJson(
              Map<String, dynamic>.from(entry),
            );
            if (existing != null) {
              records.add(existing);
            }
          }
        }
      }

      records
        ..removeWhere(
          (item) => item.orderNumber.toUpperCase() ==
              record.orderNumber.toUpperCase(),
        )
        ..add(record)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      if (records.length > _maxRecords) {
        records.removeRange(_maxRecords, records.length);
      }

      await preferences.setString(
        storageKey,
        jsonEncode(records.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // Local UAT history is diagnostic convenience, never an authoritative
      // delivery mutation. If device persistence is unavailable, completion
      // must remain safe and the production boundary must not be affected.
    }
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferences();
    if (preferences == null) {
      return;
    }

    try {
      await preferences.remove(storageKey);
    } catch (_) {
      // Same resilience rule as load/upsert: unavailable local demo storage
      // must not break the Driver app or older UAT tests.
    }
  }
}

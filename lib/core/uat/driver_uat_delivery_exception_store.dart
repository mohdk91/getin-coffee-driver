import 'dart:convert';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/delivery_exceptions/domain/driver_delivery_exception_models.dart';

abstract interface class DriverUatDeliveryExceptionStore {
  Future<DriverDeliveryExceptionReceipt?> load(String orderNumber);

  Future<void> upsert(DriverDeliveryExceptionReceipt receipt);

  Future<void> clear(String orderNumber);

  Future<void> clearAll();
}

class MemoryDriverUatDeliveryExceptionStore
    implements DriverUatDeliveryExceptionStore {
  final Map<String, DriverDeliveryExceptionReceipt> _receipts =
      <String, DriverDeliveryExceptionReceipt>{};

  String _key(String orderNumber) => orderNumber.trim().toUpperCase();

  @override
  Future<DriverDeliveryExceptionReceipt?> load(String orderNumber) async {
    return _receipts[_key(orderNumber)];
  }

  @override
  Future<void> upsert(DriverDeliveryExceptionReceipt receipt) async {
    _receipts[_key(receipt.orderNumber)] = receipt;
  }

  @override
  Future<void> clear(String orderNumber) async {
    _receipts.remove(_key(orderNumber));
  }

  @override
  Future<void> clearAll() async {
    _receipts.clear();
  }
}

class SharedPreferencesDriverUatDeliveryExceptionStore
    implements DriverUatDeliveryExceptionStore {
  static const String storageKey = 'getin_driver_uat_delivery_exceptions_v1';

  final bool forcePersistenceInTests;
  final MemoryDriverUatDeliveryExceptionStore _memory;

  SharedPreferencesDriverUatDeliveryExceptionStore({
    this.forcePersistenceInTests = false,
    MemoryDriverUatDeliveryExceptionStore? memory,
  }) : _memory = memory ?? MemoryDriverUatDeliveryExceptionStore();

  bool get _skipPlatformPersistenceForFlutterTest =>
      !forcePersistenceInTests &&
      Platform.environment.containsKey('FLUTTER_TEST');

  String _key(String orderNumber) => orderNumber.trim().toUpperCase();

  Future<SharedPreferences?> _preferences() async {
    if (_skipPlatformPersistenceForFlutterTest) {
      return null;
    }
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, DriverDeliveryExceptionReceipt>> _loadPersisted() async {
    final preferences = await _preferences();
    if (preferences == null) {
      return <String, DriverDeliveryExceptionReceipt>{};
    }

    try {
      final raw = preferences.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return <String, DriverDeliveryExceptionReceipt>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, DriverDeliveryExceptionReceipt>{};
      }

      final result = <String, DriverDeliveryExceptionReceipt>{};
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final receipt = _receiptFromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (receipt == null) continue;
        result[_key(receipt.orderNumber)] = receipt;
      }
      return result;
    } catch (_) {
      return <String, DriverDeliveryExceptionReceipt>{};
    }
  }

  Future<void> _persist(
    Map<String, DriverDeliveryExceptionReceipt> receipts,
  ) async {
    final preferences = await _preferences();
    if (preferences == null) return;
    try {
      await preferences.setString(
        storageKey,
        jsonEncode(
          receipts.map(
            (key, value) => MapEntry<String, Object?>(key, _receiptToJson(value)),
          ),
        ),
      );
    } catch (_) {
      // UAT-only storage is diagnostic convenience. Persistence failure must
      // never change production delivery behavior or block the current UI.
    }
  }

  @override
  Future<DriverDeliveryExceptionReceipt?> load(String orderNumber) async {
    final key = _key(orderNumber);
    final inMemory = await _memory.load(key);
    if (inMemory != null) {
      return inMemory;
    }

    final persisted = await _loadPersisted();
    final receipt = persisted[key];
    if (receipt != null) {
      await _memory.upsert(receipt);
    }
    return receipt;
  }

  @override
  Future<void> upsert(DriverDeliveryExceptionReceipt receipt) async {
    final normalizedReceipt = DriverDeliveryExceptionReceipt(
      auditId: receipt.auditId,
      orderNumber: _key(receipt.orderNumber),
      driverReference: receipt.driverReference,
      reason: receipt.reason,
      note: receipt.note,
      reportedAt: receipt.reportedAt,
      latitude: receipt.latitude,
      longitude: receipt.longitude,
      recommendedOrderState: receipt.recommendedOrderState,
      serverAcknowledged: receipt.serverAcknowledged,
      isDemo: receipt.isDemo,
    );

    await _memory.upsert(normalizedReceipt);
    final persisted = Map<String, DriverDeliveryExceptionReceipt>.from(
      await _loadPersisted(),
    );
    persisted[_key(normalizedReceipt.orderNumber)] = normalizedReceipt;
    await _persist(persisted);
  }

  @override
  Future<void> clear(String orderNumber) async {
    final key = _key(orderNumber);
    await _memory.clear(key);
    final persisted = Map<String, DriverDeliveryExceptionReceipt>.from(
      await _loadPersisted(),
    );
    if (persisted.remove(key) != null) {
      await _persist(persisted);
    }
  }

  @override
  Future<void> clearAll() async {
    await _memory.clearAll();
    final preferences = await _preferences();
    if (preferences == null) return;
    try {
      await preferences.remove(storageKey);
    } catch (_) {
      // Same safety rule: UAT reset is best effort only.
    }
  }

  static Map<String, Object?> _receiptToJson(
    DriverDeliveryExceptionReceipt receipt,
  ) => <String, Object?>{
        'audit_id': receipt.auditId,
        'order_number': receipt.orderNumber,
        'driver_reference': receipt.driverReference,
        'reason': receipt.reason.name,
        'note': receipt.note,
        'reported_at': receipt.reportedAt.toIso8601String(),
        'latitude': receipt.latitude,
        'longitude': receipt.longitude,
        'recommended_order_state': receipt.recommendedOrderState,
        'server_acknowledged': receipt.serverAcknowledged,
        'is_demo': receipt.isDemo,
      };

  static DriverDeliveryExceptionReceipt? _receiptFromJson(
    Map<String, dynamic> json,
  ) {
    final orderNumber = json['order_number']?.toString().trim() ?? '';
    final auditId = json['audit_id']?.toString().trim() ?? '';
    final driverReference = json['driver_reference']?.toString().trim() ?? '';
    final reasonName = json['reason']?.toString().trim() ?? '';
    final reportedAt =
        DateTime.tryParse(json['reported_at']?.toString() ?? '');
    final reason = DriverDeliveryExceptionReason.values.where(
      (candidate) => candidate.name == reasonName,
    );

    if (orderNumber.isEmpty ||
        auditId.isEmpty ||
        driverReference.isEmpty ||
        reportedAt == null ||
        reason.isEmpty) {
      return null;
    }

    return DriverDeliveryExceptionReceipt(
      auditId: auditId,
      orderNumber: orderNumber.toUpperCase(),
      driverReference: driverReference,
      reason: reason.first,
      note: json['note']?.toString() ?? '',
      reportedAt: reportedAt,
      latitude: _doubleOrNull(json['latitude']),
      longitude: _doubleOrNull(json['longitude']),
      recommendedOrderState:
          json['recommended_order_state']?.toString() ??
              reason.first.recommendedOrderState,
      serverAcknowledged: json['server_acknowledged'] == true,
      isDemo: json['is_demo'] != false,
    );
  }

  static double? _doubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

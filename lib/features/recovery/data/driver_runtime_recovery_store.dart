import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../active_delivery/domain/driver_delivery_state_machine.dart';
import '../../home/domain/driver_home_models.dart';

class DriverRuntimeRecoverySnapshot {
  final DriverActiveDeliverySummary? activeDelivery;
  final String? completedOrderNumber;
  final DateTime? lastSuccessfulSyncAt;

  const DriverRuntimeRecoverySnapshot({
    this.activeDelivery,
    this.completedOrderNumber,
    this.lastSuccessfulSyncAt,
  });

  static const empty = DriverRuntimeRecoverySnapshot();
}

abstract interface class DriverRuntimeRecoveryStore {
  Future<DriverRuntimeRecoverySnapshot> load();

  Future<void> save(DriverRuntimeRecoverySnapshot snapshot);
}

class SharedPreferencesDriverRuntimeRecoveryStore
    implements DriverRuntimeRecoveryStore {
  static const String _storageKey = 'driver.runtime.recovery.v1';

  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<DriverRuntimeRecoverySnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return DriverRuntimeRecoverySnapshot.empty;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return DriverRuntimeRecoverySnapshot.empty;
      }

      return DriverRuntimeRecoverySnapshot(
        activeDelivery: _decodeActiveDelivery(decoded['activeDelivery']),
        completedOrderNumber: _stringOrNull(decoded['completedOrderNumber']),
        lastSuccessfulSyncAt: _dateTimeOrNull(decoded['lastSuccessfulSyncAt']),
      );
    } catch (_) {
      return DriverRuntimeRecoverySnapshot.empty;
    }
  }

  @override
  Future<void> save(DriverRuntimeRecoverySnapshot snapshot) {
    _writeQueue = _writeQueue.then((_) => _saveNow(snapshot));
    return _writeQueue;
  }

  Future<void> _saveNow(DriverRuntimeRecoverySnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'activeDelivery': _encodeActiveDelivery(snapshot.activeDelivery),
        'completedOrderNumber': snapshot.completedOrderNumber,
        'lastSuccessfulSyncAt':
            snapshot.lastSuccessfulSyncAt?.toIso8601String(),
      }),
    );
  }

  static Map<String, Object?>? _encodeActiveDelivery(
    DriverActiveDeliverySummary? delivery,
  ) {
    if (delivery == null) return null;
    return <String, Object?>{
      'orderNumber': delivery.orderNumber,
      'status': delivery.status,
      'pickupBranch': delivery.pickupBranch,
      'destinationArea': delivery.destinationArea,
      'etaMinutes': delivery.etaMinutes,
      'state': delivery.resolvedState.wireValue,
    };
  }

  static DriverActiveDeliverySummary? _decodeActiveDelivery(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    final orderNumber = _stringOrNull(value['orderNumber']);
    final status = _stringOrNull(value['status']);
    final pickupBranch = _stringOrNull(value['pickupBranch']);
    final destinationArea = _stringOrNull(value['destinationArea']);
    final etaMinutes = value['etaMinutes'];

    if (orderNumber == null ||
        status == null ||
        pickupBranch == null ||
        destinationArea == null ||
        etaMinutes is! num) {
      return null;
    }

    final stateValue = _stringOrNull(value['state']);
    final state = stateValue == null
        ? driverDeliveryStateFromStatus(status)
        : DriverDeliveryState.values.firstWhere(
            (candidate) => candidate.wireValue == stateValue,
            orElse: () => driverDeliveryStateFromStatus(status),
          );

    return DriverActiveDeliverySummary(
      orderNumber: orderNumber,
      status: status,
      pickupBranch: pickupBranch,
      destinationArea: destinationArea,
      etaMinutes: etaMinutes.toInt(),
      state: state,
    );
  }

  static String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    final raw = _stringOrNull(value);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}

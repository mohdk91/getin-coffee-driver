import 'dart:convert';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

class DriverUatPinLockoutState {
  final int failedAttempts;
  final DateTime? lockedAt;

  const DriverUatPinLockoutState({
    required this.failedAttempts,
    this.lockedAt,
  });

  bool isLocked(int maxAttempts) => failedAttempts >= maxAttempts;

  Map<String, Object?> toJson() => <String, Object?>{
        'failed_attempts': failedAttempts,
        'locked_at': lockedAt?.toIso8601String(),
      };

  static DriverUatPinLockoutState fromJson(Map<String, dynamic> json) {
    return DriverUatPinLockoutState(
      failedAttempts:
          int.tryParse(json['failed_attempts']?.toString() ?? '') ?? 0,
      lockedAt: DateTime.tryParse(json['locked_at']?.toString() ?? ''),
    );
  }
}

abstract interface class DriverUatPinLockoutStore {
  Future<DriverUatPinLockoutState> load(String orderNumber);

  Future<DriverUatPinLockoutState> recordFailure({
    required String orderNumber,
    required int maxAttempts,
  });

  Future<void> clear(String orderNumber);

  Future<void> clearAll();
}

class MemoryDriverUatPinLockoutStore implements DriverUatPinLockoutStore {
  final Map<String, DriverUatPinLockoutState> _states =
      <String, DriverUatPinLockoutState>{};

  String _key(String orderNumber) => orderNumber.trim().toUpperCase();

  @override
  Future<DriverUatPinLockoutState> load(String orderNumber) async {
    return _states[_key(orderNumber)] ??
        const DriverUatPinLockoutState(failedAttempts: 0);
  }

  @override
  Future<DriverUatPinLockoutState> recordFailure({
    required String orderNumber,
    required int maxAttempts,
  }) async {
    final key = _key(orderNumber);
    final current = await load(key);
    final failedAttempts = current.failedAttempts + 1;
    final next = DriverUatPinLockoutState(
      failedAttempts: failedAttempts,
      lockedAt: failedAttempts >= maxAttempts
          ? (current.lockedAt ?? DateTime.now())
          : current.lockedAt,
    );
    _states[key] = next;
    return next;
  }

  @override
  Future<void> clear(String orderNumber) async {
    _states.remove(_key(orderNumber));
  }

  @override
  Future<void> clearAll() async {
    _states.clear();
  }
}

class SharedPreferencesDriverUatPinLockoutStore
    implements DriverUatPinLockoutStore {
  static const String storageKey = 'getin_driver_uat_pin_lockouts_v1';

  final bool forcePersistenceInTests;
  final MemoryDriverUatPinLockoutStore _memory;

  SharedPreferencesDriverUatPinLockoutStore({
    this.forcePersistenceInTests = false,
    MemoryDriverUatPinLockoutStore? memory,
  }) : _memory = memory ?? MemoryDriverUatPinLockoutStore();

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

  Future<Map<String, DriverUatPinLockoutState>> _loadPersisted() async {
    final preferences = await _preferences();
    if (preferences == null) {
      return <String, DriverUatPinLockoutState>{};
    }

    try {
      final raw = preferences.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return <String, DriverUatPinLockoutState>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, DriverUatPinLockoutState>{};
      }
      final result = <String, DriverUatPinLockoutState>{};
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        result[entry.key.toString().toUpperCase()] =
            DriverUatPinLockoutState.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
      return result;
    } catch (_) {
      return <String, DriverUatPinLockoutState>{};
    }
  }

  Future<void> _persist(
    Map<String, DriverUatPinLockoutState> states,
  ) async {
    final preferences = await _preferences();
    if (preferences == null) return;

    try {
      await preferences.setString(
        storageKey,
        jsonEncode(
          states.map(
            (key, value) => MapEntry<String, Object?>(key, value.toJson()),
          ),
        ),
      );
    } catch (_) {
      // UAT-only persistence must never block a delivery workflow. The
      // repository still keeps an in-memory lockout for the current process.
    }
  }

  @override
  Future<DriverUatPinLockoutState> load(String orderNumber) async {
    final key = _key(orderNumber);
    final memoryState = await _memory.load(key);
    final persisted = await _loadPersisted();
    final persistedState = persisted[key];
    if (persistedState == null ||
        memoryState.failedAttempts >= persistedState.failedAttempts) {
      return memoryState;
    }

    for (var i = memoryState.failedAttempts;
        i < persistedState.failedAttempts;
        i++) {
      await _memory.recordFailure(orderNumber: key, maxAttempts: 3);
    }
    return persistedState;
  }

  @override
  Future<DriverUatPinLockoutState> recordFailure({
    required String orderNumber,
    required int maxAttempts,
  }) async {
    final key = _key(orderNumber);
    final current = await load(key);
    final failedAttempts = current.failedAttempts + 1;
    final next = DriverUatPinLockoutState(
      failedAttempts: failedAttempts,
      lockedAt: failedAttempts >= maxAttempts
          ? (current.lockedAt ?? DateTime.now())
          : current.lockedAt,
    );

    await _memory.recordFailure(orderNumber: key, maxAttempts: maxAttempts);
    final persisted = Map<String, DriverUatPinLockoutState>.from(
      await _loadPersisted(),
    );
    persisted[key] = next;
    await _persist(persisted);
    return next;
  }

  @override
  Future<void> clear(String orderNumber) async {
    final key = _key(orderNumber);
    await _memory.clear(key);
    final persisted = Map<String, DriverUatPinLockoutState>.from(
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
      // UAT reset remains best-effort and must never touch production state.
    }
  }
}

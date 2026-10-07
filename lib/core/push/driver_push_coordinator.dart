import 'dart:async';

import 'driver_push_models.dart';

class DriverPushCoordinator {
  DriverPushCoordinator._();

  static final DriverPushCoordinator instance = DriverPushCoordinator._();

  final StreamController<DriverPushIntent> _controller =
      StreamController<DriverPushIntent>.broadcast();
  final List<DriverPushIntent> _pending = <DriverPushIntent>[];

  Stream<DriverPushIntent> get stream => _controller.stream;

  void publish(DriverPushIntent intent) {
    if (_controller.hasListener) {
      _controller.add(intent);
      return;
    }
    _pending.add(intent);
  }

  List<DriverPushIntent> takePending() {
    if (_pending.isEmpty) return const <DriverPushIntent>[];
    final result = List<DriverPushIntent>.unmodifiable(_pending);
    _pending.clear();
    return result;
  }

  void resetForTest() {
    _pending.clear();
  }
}

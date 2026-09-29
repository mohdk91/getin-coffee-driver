class DriverNavigationPushGuard {
  final Set<String> _inFlight = <String>{};

  bool isInFlight(String key) => _inFlight.contains(key);

  Future<bool> run(String key, Future<void> Function() operation) async {
    if (!_inFlight.add(key)) return false;
    try {
      await operation();
      return true;
    } finally {
      _inFlight.remove(key);
    }
  }
}

class ApiRetryPolicy {
  final int maxAttempts;
  final Duration baseDelay;
  final Set<int> retryableStatusCodes;

  const ApiRetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 350),
    this.retryableStatusCodes = const <int>{408, 429, 500, 502, 503, 504},
  }) : assert(maxAttempts >= 1);

  bool shouldRetryStatus(int statusCode) {
    return retryableStatusCodes.contains(statusCode);
  }

  Duration delayBeforeAttempt(int nextAttempt) {
    if (baseDelay == Duration.zero) return Duration.zero;
    final multiplier = nextAttempt <= 2 ? 1 : nextAttempt - 1;
    return Duration(
      milliseconds: baseDelay.inMilliseconds * multiplier,
    );
  }
}

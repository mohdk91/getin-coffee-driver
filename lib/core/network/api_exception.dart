enum ApiFailureKind {
  offline,
  timeout,
  authentication,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  invalidResponse,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;
  final Object? cause;
  final ApiFailureKind kind;
  final Duration? retryAfter;
  final String? requestId;

  const ApiException(
    this.message, {
    this.statusCode,
    this.errors = const <String, dynamic>{},
    this.cause,
    this.kind = ApiFailureKind.unknown,
    this.retryAfter,
    this.requestId,
  });

  bool get isAuthenticationFailure =>
      kind == ApiFailureKind.authentication || statusCode == 401;

  bool get isValidationFailure =>
      kind == ApiFailureKind.validation || statusCode == 422;

  bool get isOffline => kind == ApiFailureKind.offline;

  bool get isTimeout => kind == ApiFailureKind.timeout;

  bool get isRateLimited => kind == ApiFailureKind.rateLimited;

  bool get isRetryable => const <ApiFailureKind>{
        ApiFailureKind.offline,
        ApiFailureKind.timeout,
        ApiFailureKind.rateLimited,
        ApiFailureKind.server,
      }.contains(kind);

  String? get supportReference {
    final value = requestId?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    final reference = supportReference == null ? '' : ' [${supportReference!}]';
    return 'ApiException$code$reference: $message';
  }
}

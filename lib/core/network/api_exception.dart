class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;
  final Object? cause;

  const ApiException(
    this.message, {
    this.statusCode,
    this.errors = const <String, dynamic>{},
    this.cause,
  });

  bool get isAuthenticationFailure => statusCode == 401;

  bool get isValidationFailure => statusCode == 422;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiException$code: $message';
  }
}

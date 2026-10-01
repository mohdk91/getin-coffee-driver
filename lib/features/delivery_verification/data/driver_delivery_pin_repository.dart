import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_delivery_pin_models.dart';

abstract interface class DriverDeliveryPinRepository {
  DriverDeliveryPinDataSource get source;

  Future<DriverDeliveryPinLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  });

  Future<DriverDeliveryPinVerificationResult> verifyPin({
    required int? apiOrderId,
    required DriverDeliveryPinChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String code,
  });
}

class DriverDeliveryPinRepositoryFactory {
  DriverDeliveryPinRepositoryFactory._();

  static DriverDeliveryPinRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return DemoDriverDeliveryPinRepository();
    }
    return ApiDriverDeliveryPinRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverDeliveryPinRepository implements DriverDeliveryPinRepository {
  final DriverApiContext context;
  const ApiDriverDeliveryPinRepository(this.context);

  @override
  DriverDeliveryPinDataSource get source => DriverDeliveryPinDataSource.api;

  @override
  Future<DriverDeliveryPinLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    if (apiOrderId == null) {
      return const DriverDeliveryPinLoadResult.failure(
        'The active delivery is missing its Laravel order identifier.',
      );
    }
    return DriverDeliveryPinLoadResult.success(
      DriverDeliveryPinChallenge(
        orderNumber: orderNumber,
        customerReference: 'server-customer',
        assignedDriverReference: 'server-authenticated-driver',
        codeLength: 6,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<DriverDeliveryPinVerificationResult> verifyPin({
    required int? apiOrderId,
    required DriverDeliveryPinChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String code,
  }) async {
    if (apiOrderId == null) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.unavailable,
        message: 'The active delivery is missing its Laravel order identifier.',
      );
    }
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/verify-delivery',
        authenticated: true,
        body: <String, Object?>{'method': 'pin', 'pin': code.trim()},
        headers: <String, String>{
          'Idempotency-Key': 'driver-pin-verify-$apiOrderId-${code.trim()}',
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final verifiedAt =
          DateTime.tryParse(data['verified_at']?.toString() ?? '') ??
              DateTime.now();
      return DriverDeliveryPinVerificationResult.success(
        value: DriverDeliveryPinReceipt(
          auditId: data['id']?.toString() ?? 'verify-$apiOrderId',
          orderNumber: orderNumber,
          customerReference: customerReference,
          assignedDriverReference: assignedDriverReference,
          verifiedAt: verifiedAt,
          verificationType: 'pin',
          serverAcknowledged: true,
          isDemo: false,
        ),
        message: envelope['message']?.toString() ??
            'Delivery PIN verified by Getin.',
      );
    } on ApiException catch (error) {
      return DriverDeliveryPinVerificationResult.failure(
        reason: error.statusCode == 429
            ? DriverDeliveryPinFailureReason.tooManyAttempts
            : DriverDeliveryPinFailureReason.invalidCode,
        message: error.message,
      );
    } on FormatException catch (error) {
      return DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.unavailable,
        message: error.message,
      );
    }
  }
}

class DemoDriverDeliveryPinRepository implements DriverDeliveryPinRepository {
  static const String demoCode = '4821';
  final Set<String> _usedOrderNumbers = <String>{};
  final Map<String, DateTime> _usedAt = <String, DateTime>{};
  final Map<String, int> _failedAttempts = <String, int>{};
  static const int maxAttempts = 3;

  @override
  DriverDeliveryPinDataSource get source => DriverDeliveryPinDataSource.demo;

  @override
  Future<DriverDeliveryPinLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final normalized = orderNumber.trim().toUpperCase();
    return DriverDeliveryPinLoadResult.success(
      DriverDeliveryPinChallenge(
        orderNumber: normalized,
        customerReference: 'DEMO-CUSTOMER-$normalized',
        assignedDriverReference: 'DEMO-DRIVER-001',
        codeLength: 4,
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
        usedAt: _usedAt[normalized],
      ),
    );
  }

  @override
  Future<DriverDeliveryPinVerificationResult> verifyPin({
    required int? apiOrderId,
    required DriverDeliveryPinChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final normalizedOrder = orderNumber.trim().toUpperCase();
    final normalizedCode = code.trim();
    if (_usedOrderNumbers.contains(normalizedOrder) || challenge.isUsed) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.alreadyUsed,
        message: 'This delivery code has already been used.',
      );
    }
    final failedAttempts = _failedAttempts[normalizedOrder] ?? 0;
    if (normalizedCode != demoCode) {
      _failedAttempts[normalizedOrder] = failedAttempts + 1;
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.invalidCode,
        message: 'Invalid demo delivery code.',
      );
    }
    final verifiedAt = DateTime.now();
    _usedOrderNumbers.add(normalizedOrder);
    _usedAt[normalizedOrder] = verifiedAt;
    return DriverDeliveryPinVerificationResult.success(
      value: DriverDeliveryPinReceipt(
        auditId:
            'DEMO-PIN-$normalizedOrder-${verifiedAt.millisecondsSinceEpoch}',
        orderNumber: normalizedOrder,
        customerReference: challenge.customerReference,
        assignedDriverReference: challenge.assignedDriverReference,
        verifiedAt: verifiedAt,
        verificationType: 'pin',
        serverAcknowledged: false,
        isDemo: true,
      ),
      message: 'Delivery Verified locally in demo mode.',
    );
  }
}

class UnavailableDriverDeliveryPinRepository
    implements DriverDeliveryPinRepository {
  const UnavailableDriverDeliveryPinRepository();
  @override
  DriverDeliveryPinDataSource get source => DriverDeliveryPinDataSource.api;
  @override
  Future<DriverDeliveryPinLoadResult> loadChallenge(
          {required int? apiOrderId, required String orderNumber}) async =>
      const DriverDeliveryPinLoadResult.failure(
          'Delivery PIN verification is unavailable.');
  @override
  Future<DriverDeliveryPinVerificationResult> verifyPin(
          {required int? apiOrderId,
          required DriverDeliveryPinChallenge challenge,
          required String orderNumber,
          required String customerReference,
          required String assignedDriverReference,
          required String code}) async =>
      const DriverDeliveryPinVerificationResult.failure(
          reason: DriverDeliveryPinFailureReason.unavailable,
          message: 'Could not confirm with Getin.');
}

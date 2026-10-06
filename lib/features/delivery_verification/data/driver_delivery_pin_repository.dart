import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/uat/driver_uat_pin_lockout_store.dart';
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
    if (config.allowsDemo) {
      return DemoDriverDeliveryPinRepository();
    }
    return ApiDriverDeliveryPinRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverDeliveryPinRepository implements DriverDeliveryPinRepository {
  final DriverApiContext context;
  final Set<int> _rateLimitedOrderIds = <int>{};

  ApiDriverDeliveryPinRepository(this.context);

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
    final rateLimited = _rateLimitedOrderIds.contains(apiOrderId);
    return DriverDeliveryPinLoadResult.success(
      DriverDeliveryPinChallenge(
        orderNumber: orderNumber,
        customerReference: 'server-customer',
        assignedDriverReference: 'server-authenticated-driver',
        codeLength: 6,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        failedAttempts: rateLimited ? 3 : 0,
        maxAttempts: 3,
        lockedAt: rateLimited ? DateTime.now() : null,
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
    if (_rateLimitedOrderIds.contains(apiOrderId)) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.tooManyAttempts,
        message:
            'Too many unsuccessful verification attempts. Delivery remains locked. Contact Getin Support before trying again.',
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
      if (error.statusCode == 429) {
        _rateLimitedOrderIds.add(apiOrderId);
      }
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
  static const int maxAttempts = 3;

  final Set<String> _usedOrderNumbers = <String>{};
  final Map<String, DateTime> _usedAt = <String, DateTime>{};
  final DriverUatPinLockoutStore lockoutStore;

  DemoDriverDeliveryPinRepository({
    DriverUatPinLockoutStore? lockoutStore,
  }) : lockoutStore =
            lockoutStore ?? SharedPreferencesDriverUatPinLockoutStore();

  @override
  DriverDeliveryPinDataSource get source => DriverDeliveryPinDataSource.demo;

  @override
  Future<DriverDeliveryPinLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final normalized = orderNumber.trim().toUpperCase();
    final usedAt = _usedAt[normalized];
    final lockout = await lockoutStore.load(normalized);

    return DriverDeliveryPinLoadResult.success(
      DriverDeliveryPinChallenge(
        orderNumber: normalized,
        customerReference: 'DEMO-CUSTOMER-$normalized',
        assignedDriverReference: 'DEMO-DRIVER-001',
        codeLength: 4,
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
        usedAt: usedAt,
        failedAttempts: lockout.failedAttempts,
        maxAttempts: maxAttempts,
        lockedAt: lockout.lockedAt,
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

    if (normalizedOrder != challenge.orderNumber) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.wrongOrder,
        message:
            'The delivery code could not be verified for this order. No delivery state changed.',
      );
    }

    if (customerReference != challenge.customerReference) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.wrongCustomer,
        message:
            'The delivery code could not be verified for this customer. No delivery state changed.',
      );
    }

    if (assignedDriverReference != challenge.assignedDriverReference) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.wrongDriver,
        message:
            'The delivery code is not assigned to this driver. No delivery state changed.',
      );
    }

    if (_usedOrderNumbers.contains(normalizedOrder) || challenge.isUsed) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.alreadyUsed,
        message:
            'This delivery code has already been used. No delivery state changed.',
      );
    }

    if (challenge.isExpired) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.expired,
        message: 'This delivery code has expired. No delivery state changed.',
      );
    }

    final lockout = await lockoutStore.load(normalizedOrder);
    if (lockout.isLocked(maxAttempts)) {
      return const DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.tooManyAttempts,
        message:
            'Too many unsuccessful verification attempts. Delivery remains locked. Contact Getin Support before trying again.',
      );
    }

    if (normalizedCode != demoCode) {
      final next = await lockoutStore.recordFailure(
        orderNumber: normalizedOrder,
        maxAttempts: maxAttempts,
      );
      if (next.isLocked(maxAttempts)) {
        return const DriverDeliveryPinVerificationResult.failure(
          reason: DriverDeliveryPinFailureReason.tooManyAttempts,
          message:
              'Too many unsuccessful verification attempts. Delivery remains locked. Contact Getin Support before trying again.',
        );
      }
      final remaining = maxAttempts - next.failedAttempts;
      return DriverDeliveryPinVerificationResult.failure(
        reason: DriverDeliveryPinFailureReason.invalidCode,
        message:
            'Invalid delivery code. Check the code with the customer and retry. $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
      );
    }

    final verifiedAt = DateTime.now();
    await lockoutStore.clear(normalizedOrder);
    _usedOrderNumbers.add(normalizedOrder);
    _usedAt[normalizedOrder] = verifiedAt;

    final receipt = DriverDeliveryPinReceipt(
      auditId: 'DEMO-PIN-$normalizedOrder-${verifiedAt.millisecondsSinceEpoch}',
      orderNumber: normalizedOrder,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      verifiedAt: verifiedAt,
      verificationType: 'pin',
      serverAcknowledged: false,
      isDemo: true,
    );

    return DriverDeliveryPinVerificationResult.success(
      value: receipt,
      message:
          'Delivery Verified. Demo PIN verification succeeded locally; Laravel has not acknowledged delivery completion.',
    );
  }
}

class UnavailableDriverDeliveryPinRepository
    implements DriverDeliveryPinRepository {
  const UnavailableDriverDeliveryPinRepository();

  @override
  DriverDeliveryPinDataSource get source => DriverDeliveryPinDataSource.api;

  @override
  Future<DriverDeliveryPinLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    return const DriverDeliveryPinLoadResult.failure(
      'Delivery PIN verification is not connected to Laravel yet. Getin will not invent a customer code, expiry, customer reference, or assigned-driver verification in production.',
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
    return const DriverDeliveryPinVerificationResult.failure(
      reason: DriverDeliveryPinFailureReason.unavailable,
      message:
          'Could not confirm with Getin. The order status has not changed. Retry after the Laravel verification service is connected.',
    );
  }
}

import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_delivery_pin_models.dart';
import '../domain/driver_delivery_qr_models.dart';

abstract interface class DriverDeliveryQrRepository {
  DriverDeliveryQrDataSource get source;

  Future<DriverDeliveryQrLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  });

  Future<DriverDeliveryQrVerificationResult> verifyQr({
    required int? apiOrderId,
    required DriverDeliveryQrChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String qrPayload,
  });
}

class DriverDeliveryQrRepositoryFactory {
  DriverDeliveryQrRepositoryFactory._();

  static DriverDeliveryQrRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return DemoDriverDeliveryQrRepository();
    }
    return ApiDriverDeliveryQrRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverDeliveryQrRepository implements DriverDeliveryQrRepository {
  final DriverApiContext context;
  const ApiDriverDeliveryQrRepository(this.context);

  @override
  DriverDeliveryQrDataSource get source => DriverDeliveryQrDataSource.api;

  @override
  Future<DriverDeliveryQrLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    if (apiOrderId == null) {
      return const DriverDeliveryQrLoadResult.failure(
        'The active delivery is missing its Laravel order identifier.',
      );
    }
    return DriverDeliveryQrLoadResult.success(
      DriverDeliveryQrChallenge(
        orderNumber: orderNumber,
        customerReference: 'server-customer',
        assignedDriverReference: 'server-authenticated-driver',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<DriverDeliveryQrVerificationResult> verifyQr({
    required int? apiOrderId,
    required DriverDeliveryQrChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String qrPayload,
  }) async {
    final token = qrPayload.trim();
    if (apiOrderId == null || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(token)) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.invalidQr,
        message:
            'The scanned customer QR does not contain a valid Getin delivery token.',
      );
    }
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/verify-delivery',
        authenticated: true,
        body: <String, Object?>{'method': 'qr', 'token': token},
        headers: <String, String>{
          'Idempotency-Key': 'driver-qr-verify-$apiOrderId-$token',
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final verifiedAt =
          DateTime.tryParse(data['verified_at']?.toString() ?? '') ??
              DateTime.now();
      return DriverDeliveryQrVerificationResult.success(
        value: DriverDeliveryPinReceipt(
          auditId: data['id']?.toString() ?? 'verify-$apiOrderId',
          orderNumber: orderNumber,
          customerReference: customerReference,
          assignedDriverReference: assignedDriverReference,
          verifiedAt: verifiedAt,
          verificationType: 'qr',
          serverAcknowledged: true,
          isDemo: false,
        ),
        message:
            envelope['message']?.toString() ?? 'Customer QR verified by Getin.',
      );
    } on ApiException catch (error) {
      return DriverDeliveryQrVerificationResult.failure(
        reason: error.statusCode == 429
            ? DriverDeliveryQrFailureReason.tooManyAttempts
            : DriverDeliveryQrFailureReason.invalidQr,
        message: error.message,
      );
    } on FormatException catch (error) {
      return DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.unavailable,
        message: error.message,
      );
    }
  }
}

class DemoDriverDeliveryQrRepository implements DriverDeliveryQrRepository {
  static const String demoPayload = 'GETIN-DEMO-CUSTOMER-QR';
  final Set<String> _usedOrderNumbers = <String>{};
  final Map<String, DateTime> _usedAt = <String, DateTime>{};
  final Map<String, DriverDeliveryPinReceipt> _verifiedReceipts =
      <String, DriverDeliveryPinReceipt>{};
  final Map<String, int> _failedAttempts = <String, int>{};
  static const int maxAttempts = 3;

  @override
  DriverDeliveryQrDataSource get source => DriverDeliveryQrDataSource.demo;

  @override
  Future<DriverDeliveryQrLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final normalized = orderNumber.trim().toUpperCase();
    return DriverDeliveryQrLoadResult.success(
      DriverDeliveryQrChallenge(
        orderNumber: normalized,
        customerReference: 'DEMO-CUSTOMER-$normalized',
        assignedDriverReference: 'DEMO-DRIVER-001',
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
        usedAt: _usedAt[normalized],
      ),
      verifiedReceipt: _verifiedReceipts[normalized],
    );
  }

  @override
  Future<DriverDeliveryQrVerificationResult> verifyQr({
    required int? apiOrderId,
    required DriverDeliveryQrChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String qrPayload,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));

    final normalizedOrder = orderNumber.trim().toUpperCase();
    if (normalizedOrder != challenge.orderNumber) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.wrongOrder,
        message:
            'The customer QR could not be verified for this order. No delivery state changed.',
      );
    }
    if (customerReference != challenge.customerReference) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.wrongCustomer,
        message:
            'The customer QR could not be verified for this customer. No delivery state changed.',
      );
    }
    if (assignedDriverReference != challenge.assignedDriverReference) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.wrongDriver,
        message:
            'The customer QR is not assigned to this driver. No delivery state changed.',
      );
    }

    final existingReceipt = _verifiedReceipts[normalizedOrder];
    if (existingReceipt != null && qrPayload.trim() == demoPayload) {
      return DriverDeliveryQrVerificationResult.success(
        value: existingReceipt,
        message:
            'Delivery Verified. This customer QR was already verified for the same demo order, so the prior verification receipt was restored.',
      );
    }

    if (_usedOrderNumbers.contains(normalizedOrder) || challenge.isUsed) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.alreadyUsed,
        message:
            'This customer QR has already been used. No delivery state changed.',
      );
    }
    if (challenge.isExpired) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.expired,
        message: 'This customer QR has expired. No delivery state changed.',
      );
    }

    final failedAttempts = _failedAttempts[normalizedOrder] ?? 0;
    if (failedAttempts >= maxAttempts) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.tooManyAttempts,
        message:
            'Too many unsuccessful QR attempts. Delivery remains locked. Use the delivery PIN or contact Getin Support.',
      );
    }

    if (qrPayload.trim() != demoPayload) {
      final nextAttempts = failedAttempts + 1;
      _failedAttempts[normalizedOrder] = nextAttempts;
      if (nextAttempts >= maxAttempts) {
        return const DriverDeliveryQrVerificationResult.failure(
          reason: DriverDeliveryQrFailureReason.tooManyAttempts,
          message:
              'Too many unsuccessful QR attempts. Delivery remains locked. Use the delivery PIN or contact Getin Support.',
        );
      }
      final remaining = maxAttempts - nextAttempts;
      return DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.invalidQr,
        message:
            'Invalid customer QR. Ask the customer to show the current delivery QR or use the PIN fallback. $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
      );
    }

    final verifiedAt = DateTime.now();
    final receipt = DriverDeliveryPinReceipt(
      auditId: 'DEMO-QR-$normalizedOrder-${verifiedAt.millisecondsSinceEpoch}',
      orderNumber: normalizedOrder,
      customerReference: challenge.customerReference,
      assignedDriverReference: challenge.assignedDriverReference,
      verifiedAt: verifiedAt,
      verificationType: 'qr',
      serverAcknowledged: false,
      isDemo: true,
    );
    _failedAttempts.remove(normalizedOrder);
    _usedOrderNumbers.add(normalizedOrder);
    _usedAt[normalizedOrder] = verifiedAt;
    _verifiedReceipts[normalizedOrder] = receipt;

    return DriverDeliveryQrVerificationResult.success(
      value: receipt,
      message:
          'Delivery Verified. Demo QR verification succeeded locally; Laravel has not acknowledged delivery completion.',
    );
  }
}

class UnavailableDriverDeliveryQrRepository
    implements DriverDeliveryQrRepository {
  const UnavailableDriverDeliveryQrRepository();

  @override
  DriverDeliveryQrDataSource get source => DriverDeliveryQrDataSource.api;

  @override
  Future<DriverDeliveryQrLoadResult> loadChallenge({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    return const DriverDeliveryQrLoadResult.failure(
      'Customer QR verification is not connected to Laravel yet. Getin will not invent a QR payload, expiry, customer reference, or assigned-driver verification in production.',
    );
  }

  @override
  Future<DriverDeliveryQrVerificationResult> verifyQr({
    required int? apiOrderId,
    required DriverDeliveryQrChallenge challenge,
    required String orderNumber,
    required String customerReference,
    required String assignedDriverReference,
    required String qrPayload,
  }) async {
    return const DriverDeliveryQrVerificationResult.failure(
      reason: DriverDeliveryQrFailureReason.unavailable,
      message:
          'Could not confirm with Getin. The order status has not changed. Use PIN if available or retry after the Laravel verification service is connected.',
    );
  }
}

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
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
    if (config.environment == AppEnvironment.development) {
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
    if (qrPayload.trim() != demoPayload) {
      return const DriverDeliveryQrVerificationResult.failure(
        reason: DriverDeliveryQrFailureReason.invalidQr,
        message: 'Invalid demo customer QR.',
      );
    }
    final verifiedAt = DateTime.now();
    _usedOrderNumbers.add(orderNumber);
    _usedAt[orderNumber] = verifiedAt;
    return DriverDeliveryQrVerificationResult.success(
      value: DriverDeliveryPinReceipt(
        auditId: 'DEMO-QR-$orderNumber-${verifiedAt.millisecondsSinceEpoch}',
        orderNumber: orderNumber,
        customerReference: challenge.customerReference,
        assignedDriverReference: challenge.assignedDriverReference,
        verifiedAt: verifiedAt,
        verificationType: 'qr',
        serverAcknowledged: false,
        isDemo: true,
      ),
      message: 'Delivery Verified locally in demo mode.',
    );
  }
}

class UnavailableDriverDeliveryQrRepository
    implements DriverDeliveryQrRepository {
  const UnavailableDriverDeliveryQrRepository();
  @override
  DriverDeliveryQrDataSource get source => DriverDeliveryQrDataSource.api;
  @override
  Future<DriverDeliveryQrLoadResult> loadChallenge(
          {required int? apiOrderId, required String orderNumber}) async =>
      const DriverDeliveryQrLoadResult.failure(
          'Customer QR verification is unavailable.');
  @override
  Future<DriverDeliveryQrVerificationResult> verifyQr(
          {required int? apiOrderId,
          required DriverDeliveryQrChallenge challenge,
          required String orderNumber,
          required String customerReference,
          required String assignedDriverReference,
          required String qrPayload}) async =>
      const DriverDeliveryQrVerificationResult.failure(
          reason: DriverDeliveryQrFailureReason.unavailable,
          message: 'Could not confirm with Getin.');
}

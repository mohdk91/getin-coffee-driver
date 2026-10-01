import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_branch_pickup_models.dart';

abstract interface class DriverBranchPickupRepository {
  DriverBranchPickupDataSource get source;

  Future<DriverBranchPickupVerificationResult> verifyToken({
    required int? apiOrderId,
    required String orderNumber,
    required String branchName,
    required String token,
  });

  Future<DriverBranchPickupVerificationResult> scanBranchQr({
    required int? apiOrderId,
    required String orderNumber,
    required String branchName,
  });

  Future<DriverBranchPickupReceiveResult> confirmReceived({
    required int? apiOrderId,
    required DriverBranchPickupVerification verification,
    required double? latitude,
    required double? longitude,
  });
}

class DriverBranchPickupRepositoryFactory {
  DriverBranchPickupRepositoryFactory._();

  static DriverBranchPickupRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverBranchPickupRepository();
    }
    return ApiDriverBranchPickupRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverBranchPickupRepository implements DriverBranchPickupRepository {
  final DriverApiContext context;

  const ApiDriverBranchPickupRepository(this.context);

  @override
  DriverBranchPickupDataSource get source => DriverBranchPickupDataSource.api;

  @override
  Future<DriverBranchPickupVerificationResult> verifyToken({
    required int? apiOrderId,
    required String orderNumber,
    required String branchName,
    required String token,
  }) async {
    final normalized = token.trim();
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(normalized)) {
      return const DriverBranchPickupVerificationResult.failure(
        'The production pickup token must be the secure 64-character branch token.',
      );
    }
    return DriverBranchPickupVerificationResult.success(
      DriverBranchPickupVerification(
        orderNumber: orderNumber,
        branchName: branchName,
        method: DriverBranchPickupVerificationMethod.token,
        verificationReference: normalized,
        verifiedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<DriverBranchPickupVerificationResult> scanBranchQr({
    required int? apiOrderId,
    required String orderNumber,
    required String branchName,
  }) async {
    return const DriverBranchPickupVerificationResult.failure(
      'Production branch QR scanning requires a real scanned token. Manual simulation is disabled.',
    );
  }

  @override
  Future<DriverBranchPickupReceiveResult> confirmReceived({
    required int? apiOrderId,
    required DriverBranchPickupVerification verification,
    required double? latitude,
    required double? longitude,
  }) async {
    if (apiOrderId == null) {
      return const DriverBranchPickupReceiveResult.failure(
        'The active delivery is missing its Laravel order identifier.',
      );
    }
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/pickup/verify',
        authenticated: true,
        body: <String, Object?>{
          'token': verification.verificationReference,
        },
        headers: <String, String>{
          'Idempotency-Key': 'driver-pickup-verify-$apiOrderId',
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final receivedAt =
          DateTime.tryParse(data['picked_up_at']?.toString() ?? '') ??
              DateTime.now();
      return DriverBranchPickupReceiveResult.success(
        DriverBranchPickupReceipt(
          auditId: 'pickup-$apiOrderId-${receivedAt.millisecondsSinceEpoch}',
          orderNumber:
              data['order_number']?.toString() ?? verification.orderNumber,
          branchName: verification.branchName,
          driverId: 'server-authenticated-driver',
          verificationMethod: verification.method,
          verificationReference: verification.verificationReference,
          verifiedAt: verification.verifiedAt,
          receivedAt: receivedAt,
          latitude: latitude,
          longitude: longitude,
          serverAcknowledged: true,
          isDemo: false,
        ),
      );
    } on ApiException catch (error) {
      return DriverBranchPickupReceiveResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverBranchPickupReceiveResult.failure(error.message);
    }
  }
}

class DemoDriverBranchPickupRepository implements DriverBranchPickupRepository {
  static const String demoToken = '2468';
  const DemoDriverBranchPickupRepository();

  @override
  DriverBranchPickupDataSource get source => DriverBranchPickupDataSource.demo;

  @override
  Future<DriverBranchPickupVerificationResult> verifyToken({
    required int? apiOrderId,
    required String orderNumber,
    required String branchName,
    required String token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (token.trim() != demoToken) {
      return const DriverBranchPickupVerificationResult.failure(
        'That pickup token is not valid for this demo order. The order was not verified.',
      );
    }
    return DriverBranchPickupVerificationResult.success(
      DriverBranchPickupVerification(
        orderNumber: orderNumber,
        branchName: branchName,
        method: DriverBranchPickupVerificationMethod.token,
        verificationReference: 'DEMO-TOKEN-$orderNumber',
        verifiedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<DriverBranchPickupVerificationResult> scanBranchQr({
    required int? apiOrderId,
    required String orderNumber,
    required String branchName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return DriverBranchPickupVerificationResult.success(
      DriverBranchPickupVerification(
        orderNumber: orderNumber,
        branchName: branchName,
        method: DriverBranchPickupVerificationMethod.qr,
        verificationReference: 'DEMO-QR-$orderNumber',
        verifiedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<DriverBranchPickupReceiveResult> confirmReceived({
    required int? apiOrderId,
    required DriverBranchPickupVerification verification,
    required double? latitude,
    required double? longitude,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final receivedAt = DateTime.now();
    return DriverBranchPickupReceiveResult.success(
      DriverBranchPickupReceipt(
        auditId:
            'DEMO-PICKUP-${verification.orderNumber}-${receivedAt.millisecondsSinceEpoch}',
        orderNumber: verification.orderNumber,
        branchName: verification.branchName,
        driverId: 'DEMO-DRIVER-001',
        verificationMethod: verification.method,
        verificationReference: verification.verificationReference,
        verifiedAt: verification.verifiedAt,
        receivedAt: receivedAt,
        latitude: latitude,
        longitude: longitude,
        serverAcknowledged: false,
        isDemo: true,
      ),
    );
  }
}

class UnavailableDriverBranchPickupRepository
    implements DriverBranchPickupRepository {
  const UnavailableDriverBranchPickupRepository();
  @override
  DriverBranchPickupDataSource get source => DriverBranchPickupDataSource.api;
  @override
  Future<DriverBranchPickupVerificationResult> verifyToken(
          {required int? apiOrderId,
          required String orderNumber,
          required String branchName,
          required String token}) async =>
      const DriverBranchPickupVerificationResult.failure(
          'Branch pickup verification is unavailable.');
  @override
  Future<DriverBranchPickupVerificationResult> scanBranchQr(
          {required int? apiOrderId,
          required String orderNumber,
          required String branchName}) async =>
      const DriverBranchPickupVerificationResult.failure(
          'Branch QR verification is unavailable.');
  @override
  Future<DriverBranchPickupReceiveResult> confirmReceived(
          {required int? apiOrderId,
          required DriverBranchPickupVerification verification,
          required double? latitude,
          required double? longitude}) async =>
      const DriverBranchPickupReceiveResult.failure(
          'Getin could not confirm pickup.');
}

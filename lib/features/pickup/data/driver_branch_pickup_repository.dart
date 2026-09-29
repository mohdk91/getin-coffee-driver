import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_branch_pickup_models.dart';

abstract interface class DriverBranchPickupRepository {
  DriverBranchPickupDataSource get source;

  Future<DriverBranchPickupVerificationResult> verifyToken({
    required String orderNumber,
    required String branchName,
    required String token,
  });

  Future<DriverBranchPickupVerificationResult> scanBranchQr({
    required String orderNumber,
    required String branchName,
  });

  Future<DriverBranchPickupReceiveResult> confirmReceived({
    required DriverBranchPickupVerification verification,
    required double? latitude,
    required double? longitude,
  });
}

class DriverBranchPickupRepositoryFactory {
  DriverBranchPickupRepositoryFactory._();

  static DriverBranchPickupRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverBranchPickupRepository()
        : const UnavailableDriverBranchPickupRepository();
  }
}

class DemoDriverBranchPickupRepository implements DriverBranchPickupRepository {
  static const String demoToken = '2468';

  const DemoDriverBranchPickupRepository();

  @override
  DriverBranchPickupDataSource get source => DriverBranchPickupDataSource.demo;

  @override
  Future<DriverBranchPickupVerificationResult> verifyToken({
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
  Future<DriverBranchPickupVerificationResult> verifyToken({
    required String orderNumber,
    required String branchName,
    required String token,
  }) async {
    return const DriverBranchPickupVerificationResult.failure(
      'Branch pickup verification is not connected to the Laravel API yet. No order status changed.',
    );
  }

  @override
  Future<DriverBranchPickupVerificationResult> scanBranchQr({
    required String orderNumber,
    required String branchName,
  }) async {
    return const DriverBranchPickupVerificationResult.failure(
      'The production branch QR scanner is not connected yet. No order status changed.',
    );
  }

  @override
  Future<DriverBranchPickupReceiveResult> confirmReceived({
    required DriverBranchPickupVerification verification,
    required double? latitude,
    required double? longitude,
  }) async {
    return const DriverBranchPickupReceiveResult.failure(
      'Getin could not confirm pickup with the server. The order remains uncollected.',
    );
  }
}

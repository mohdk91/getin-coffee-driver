import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/pickup/data/driver_branch_pickup_repository.dart';
import 'package:getin_driver/features/pickup/domain/driver_branch_pickup_models.dart';

void main() {
  test('Task 13 demo token verification records custody audit data', () async {
    const repository = DemoDriverBranchPickupRepository();

    final verificationResult = await repository.verifyToken(
      apiOrderId: null,
      orderNumber: 'GD-3101',
      branchName: 'Stanley',
      token: DemoDriverBranchPickupRepository.demoToken,
    );

    expect(verificationResult.isSuccess, isTrue);
    expect(
      verificationResult.verification!.method,
      DriverBranchPickupVerificationMethod.token,
    );

    final receiveResult = await repository.confirmReceived(
      apiOrderId: null,
      verification: verificationResult.verification!,
      latitude: 31.2458,
      longitude: 29.9668,
    );

    expect(receiveResult.isSuccess, isTrue);
    expect(receiveResult.receipt!.orderNumber, 'GD-3101');
    expect(receiveResult.receipt!.branchName, 'Stanley');
    expect(receiveResult.receipt!.auditId, startsWith('DEMO-PICKUP-GD-3101'));
    expect(receiveResult.receipt!.serverAcknowledged, isFalse);
    expect(receiveResult.receipt!.isDemo, isTrue);
    expect(repository.source, DriverBranchPickupDataSource.demo);
  });

  test('Task 13 invalid demo pickup token does not verify the order', () async {
    const repository = DemoDriverBranchPickupRepository();

    final result = await repository.verifyToken(
      apiOrderId: null,
      orderNumber: 'GD-3101',
      branchName: 'Stanley',
      token: '0000',
    );

    expect(result.isSuccess, isFalse);
    expect(result.verification, isNull);
    expect(result.errorMessage, contains('not valid'));
  });

  test('Task 13 production repository refuses fake pickup verification',
      () async {
    const repository = UnavailableDriverBranchPickupRepository();

    final result = await repository.scanBranchQr(
      apiOrderId: null,
      orderNumber: 'GD-3101',
      branchName: 'Stanley',
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('not connected'));
    expect(repository.source, DriverBranchPickupDataSource.api);
  });
}

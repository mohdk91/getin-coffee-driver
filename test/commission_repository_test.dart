import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/commissions/data/driver_commission_repository.dart';
import 'package:getin_driver/features/commissions/domain/driver_commission_models.dart';

void main() {
  test('Task 27 demo commission policy is backend-driven and versioned',
      () async {
    const repository = DemoDriverCommissionRepository();
    final result = await repository.loadPolicy();

    expect(result.isSuccess, isTrue);
    expect(result.policy, isNotNull);
    expect(result.policy!.backendDriven, isTrue);
    expect(result.policy!.historicalSnapshotRequired, isTrue);
    expect(result.policy!.editableInDriverApp, isFalse);
    expect(result.policy!.policyVersion, isNotEmpty);
    expect(result.policy!.currencyCode, 'EGP');
  });

  test('Task 27 demo commission policy exposes five active rule categories',
      () async {
    const repository = DemoDriverCommissionRepository();
    final policy = (await repository.loadPolicy()).policy!;

    expect(policy.activeRules.length, 5);
    final categories = policy.activeRules.map((rule) => rule.category).toSet();
    expect(categories.length, DriverCommissionRuleCategory.values.length);
    expect(categories, containsAll(DriverCommissionRuleCategory.values));
    expect(
      policy.rules.map((rule) => rule.id).toSet().length,
      policy.rules.length,
    );
  });

  test('Task 27 production repository never invents commission rules',
      () async {
    const repository = UnavailableDriverCommissionRepository();
    final result = await repository.loadPolicy();

    expect(result.isSuccess, isFalse);
    expect(result.policy, isNull);
    expect(result.errorMessage, contains('Laravel API'));
    expect(result.errorMessage, contains('will not invent'));
  });
}

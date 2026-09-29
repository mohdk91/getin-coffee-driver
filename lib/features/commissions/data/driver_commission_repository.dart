import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_commission_models.dart';

abstract interface class DriverCommissionRepository {
  DriverCommissionDataSource get source;
  Future<DriverCommissionLoadResult> loadPolicy();
}

class DriverCommissionRepositoryFactory {
  DriverCommissionRepositoryFactory._();

  static DriverCommissionRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverCommissionRepository()
        : const UnavailableDriverCommissionRepository();
  }
}

class DemoDriverCommissionRepository implements DriverCommissionRepository {
  const DemoDriverCommissionRepository();

  @override
  DriverCommissionDataSource get source => DriverCommissionDataSource.demo;

  @override
  Future<DriverCommissionLoadResult> loadPolicy() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();

    return DriverCommissionLoadResult.success(
      DriverCommissionPolicy(
        policyVersion: 'DEMO-POLICY-27-A',
        currencyCode: 'EGP',
        effectiveFrom: DateTime(now.year, now.month, 1),
        effectiveUntil: null,
        updatedAt: now,
        rules: const [
          DriverCommissionRule(
            id: 'demo-base',
            category: DriverCommissionRuleCategory.baseEarning,
            title: 'Base delivery earning',
            calculationLabel: 'EGP 70.00 per completed delivery',
            description:
                'Demo policy value returned by the commission repository. Laravel will own the production amount and eligibility rules.',
          ),
          DriverCommissionRule(
            id: 'demo-distance',
            category: DriverCommissionRuleCategory.distanceBonus,
            title: 'Distance bonus',
            calculationLabel: 'EGP 4.00 per eligible km after 2 km',
            description:
                'Demo distance rule only. Production distance thresholds, caps and eligible kilometres must come from Laravel.',
          ),
          DriverCommissionRule(
            id: 'demo-peak',
            category: DriverCommissionRuleCategory.peakBonus,
            title: 'Peak bonus',
            calculationLabel: '15% of base during configured peak windows',
            description:
                'Demo percentage only. Peak windows, branches, zones and percentages are backend policy data.',
          ),
          DriverCommissionRule(
            id: 'demo-tip',
            category: DriverCommissionRuleCategory.tip,
            title: 'Customer tips',
            calculationLabel: '100% of eligible customer tip',
            description:
                'Tips are shown only when supported by the active backend policy and returned with the delivery payout.',
          ),
          DriverCommissionRule(
            id: 'demo-adjustment',
            category: DriverCommissionRuleCategory.adjustment,
            title: 'Adjustments',
            calculationLabel: 'Operations-defined positive or negative amount',
            description:
                'Adjustments require a backend reason and audit record. The Driver App cannot create or modify them.',
          ),
        ],
      ),
    );
  }
}

class UnavailableDriverCommissionRepository
    implements DriverCommissionRepository {
  const UnavailableDriverCommissionRepository();

  @override
  DriverCommissionDataSource get source => DriverCommissionDataSource.api;

  @override
  Future<DriverCommissionLoadResult> loadPolicy() async {
    return const DriverCommissionLoadResult.failure(
      'Driver commission policy is not connected to the Laravel API yet. Getin will not invent production rates, thresholds, bonuses, deductions or effective dates.',
    );
  }
}

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_commission_models.dart';

abstract interface class DriverCommissionRepository {
  DriverCommissionDataSource get source;
  Future<DriverCommissionLoadResult> loadPolicy();
}

class DriverCommissionRepositoryFactory {
  DriverCommissionRepositoryFactory._();

  static DriverCommissionRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverCommissionRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.environment == AppEnvironment.development
        ? const DemoDriverCommissionRepository()
        : const UnavailableDriverCommissionRepository();
  }
}

class ApiDriverCommissionRepository implements DriverCommissionRepository {
  final DriverApiContext context;
  const ApiDriverCommissionRepository(this.context);

  @override
  DriverCommissionDataSource get source => DriverCommissionDataSource.api;

  @override
  Future<DriverCommissionLoadResult> loadPolicy() async {
    try {
      final envelope = await context.apiClient.getJson(
        '/v1/driver/earnings',
        query: const <String, Object?>{'per_page': 1},
        authenticated: true,
      );
      final items = DriverApiContext.nestedItems(envelope);
      if (items.isEmpty || items.first is! Map) {
        return const DriverCommissionLoadResult.failure(
          'No backend earning snapshot is available yet. Commission rules will appear after a server-calculated delivery earning exists.',
        );
      }

      final raw = Map<String, dynamic>.from(items.first as Map);
      final components = raw['components'] is Map
          ? Map<String, dynamic>.from(raw['components'] as Map)
          : const <String, dynamic>{};
      final policy = raw['policy'] is Map
          ? Map<String, dynamic>.from(raw['policy'] as Map)
          : const <String, dynamic>{};
      final currency = raw['currency']?.toString() ?? 'EGP';
      final version = policy['version_number']?.toString();
      final effectiveAt = DateTime.tryParse(
            policy['effective_at']?.toString() ??
                raw['earned_at']?.toString() ??
                '',
          ) ??
          DateTime.now();

      String money(String key) =>
          '$currency ${_amount(components[key]).toStringAsFixed(2)}';

      final positive = _amount(components['positive_adjustment']);
      final negative = _amount(components['negative_adjustment']);

      return DriverCommissionLoadResult.success(
        DriverCommissionPolicy(
          policyVersion: version == null
              ? 'Backend earning ${raw['id'] ?? ''}'.trim()
              : 'Policy v$version',
          currencyCode: currency,
          effectiveFrom: effectiveAt,
          effectiveUntil: null,
          updatedAt: DateTime.now(),
          rules: [
            DriverCommissionRule(
              id: 'backend-base',
              category: DriverCommissionRuleCategory.baseEarning,
              title: 'Base earning',
              calculationLabel: money('base_earning'),
              description:
                  'Base component from the latest immutable Laravel earning snapshot.',
            ),
            DriverCommissionRule(
              id: 'backend-distance',
              category: DriverCommissionRuleCategory.distanceBonus,
              title: 'Distance bonus',
              calculationLabel:
                  '${money('distance_bonus')} • ${_amount(components['distance_km']).toStringAsFixed(1)} km',
              description:
                  'Distance and bonus are calculated by Laravel. The Driver App does not recalculate distance commission.',
            ),
            DriverCommissionRule(
              id: 'backend-peak',
              category: DriverCommissionRuleCategory.peakBonus,
              title: 'Peak bonus',
              calculationLabel: money('peak_bonus'),
              description:
                  'Peak eligibility and amount are backend-owned and preserved with the earning snapshot.',
            ),
            DriverCommissionRule(
              id: 'backend-tip',
              category: DriverCommissionRuleCategory.tip,
              title: 'Customer tip',
              calculationLabel: money('customer_tip'),
              description:
                  'Customer tip component returned by the backend earning record.',
            ),
            DriverCommissionRule(
              id: 'backend-adjustment',
              category: DriverCommissionRuleCategory.adjustment,
              title: 'Adjustments',
              calculationLabel:
                  '$currency ${(positive - negative).toStringAsFixed(2)}',
              description:
                  'Positive and negative adjustments are operations-controlled and auditable in Laravel.',
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      return DriverCommissionLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverCommissionLoadResult.failure(error.message);
    }
  }

  double _amount(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
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

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_earnings_models.dart';

abstract interface class DriverEarningsRepository {
  DriverEarningsDataSource get source;
  Future<DriverEarningsLoadResult> load(DriverEarningsPeriod period);
}

class DriverEarningsRepositoryFactory {
  DriverEarningsRepositoryFactory._();

  static DriverEarningsRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverEarningsRepository()
        : const UnavailableDriverEarningsRepository();
  }
}

class DemoDriverEarningsRepository implements DriverEarningsRepository {
  const DemoDriverEarningsRepository();

  @override
  DriverEarningsDataSource get source => DriverEarningsDataSource.demo;

  @override
  Future<DriverEarningsLoadResult> load(DriverEarningsPeriod period) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);

    DateTime todayTime(Duration ago) {
      final candidate = now.subtract(ago);
      return candidate.isBefore(startToday) ? startToday : candidate;
    }

    final today = <DriverDeliveryEarning>[
      DriverDeliveryEarning(
        orderNumber: 'GD-2481',
        pickupBranch: 'Stanley',
        destinationArea: 'San Stefano',
        deliveredAt: todayTime(const Duration(minutes: 45)),
        baseEarning: 70,
        distanceBonus: 25,
        peakBonus: 20,
        tipAmount: 10,
        adjustments: -2.5,
        currencyCode: 'EGP',
        adjustmentNote: 'Demo service adjustment',
      ),
      DriverDeliveryEarning(
        orderNumber: 'GD-2479',
        pickupBranch: 'Gleem',
        destinationArea: 'Roushdy',
        deliveredAt: todayTime(const Duration(hours: 2)),
        baseEarning: 65,
        distanceBonus: 15,
        peakBonus: 0,
        tipAmount: 15,
        adjustments: 0,
        currencyCode: 'EGP',
      ),
      DriverDeliveryEarning(
        orderNumber: 'GD-2472',
        pickupBranch: 'Stanley',
        destinationArea: 'Sporting',
        deliveredAt: todayTime(const Duration(hours: 4)),
        baseEarning: 75,
        distanceBonus: 24,
        peakBonus: 25,
        tipAmount: 10,
        adjustments: 0,
        currencyCode: 'EGP',
      ),
      DriverDeliveryEarning(
        orderNumber: 'GD-2468',
        pickupBranch: 'Gleem',
        destinationArea: 'Sidi Gaber',
        deliveredAt: todayTime(const Duration(hours: 6)),
        baseEarning: 72,
        distanceBonus: 22,
        peakBonus: 20,
        tipAmount: 20,
        adjustments: 0,
        currencyCode: 'EGP',
      ),
    ];

    final week = <DriverDeliveryEarning>[
      ...today,
      DriverDeliveryEarning(
        orderNumber: 'GD-2459',
        pickupBranch: 'Stanley',
        destinationArea: 'Smouha',
        deliveredAt: now.subtract(const Duration(days: 2)),
        baseEarning: 65,
        distanceBonus: 15,
        peakBonus: 10,
        tipAmount: 0,
        adjustments: -2.5,
        currencyCode: 'EGP',
        adjustmentNote: 'Demo service adjustment',
      ),
      DriverDeliveryEarning(
        orderNumber: 'GD-2448',
        pickupBranch: 'Gleem',
        destinationArea: 'Saba Pasha',
        deliveredAt: now.subtract(const Duration(days: 4)),
        baseEarning: 70,
        distanceBonus: 20,
        peakBonus: 10,
        tipAmount: 8,
        adjustments: 0,
        currencyCode: 'EGP',
      ),
    ];

    final month = <DriverDeliveryEarning>[
      ...week,
      DriverDeliveryEarning(
        orderNumber: 'GD-2419',
        pickupBranch: 'Gleem',
        destinationArea: 'Miami',
        deliveredAt: now.subtract(const Duration(days: 10)),
        baseEarning: 68,
        distanceBonus: 18,
        peakBonus: 0,
        tipAmount: 4,
        adjustments: 0,
        currencyCode: 'EGP',
      ),
      DriverDeliveryEarning(
        orderNumber: 'GD-2397',
        pickupBranch: 'Stanley',
        destinationArea: 'Kafr Abdo',
        deliveredAt: now.subtract(const Duration(days: 18)),
        baseEarning: 70,
        distanceBonus: 19,
        peakBonus: 15,
        tipAmount: 0,
        adjustments: -1.5,
        currencyCode: 'EGP',
        adjustmentNote: 'Demo service adjustment',
      ),
    ];

    final deliveries = switch (period) {
      DriverEarningsPeriod.today => today,
      DriverEarningsPeriod.week => week,
      DriverEarningsPeriod.month => month,
    };

    return DriverEarningsLoadResult.success(
      DriverEarningsSnapshot(
        period: period,
        deliveries: List<DriverDeliveryEarning>.unmodifiable(deliveries),
        updatedAt: now,
      ),
    );
  }
}

class UnavailableDriverEarningsRepository implements DriverEarningsRepository {
  const UnavailableDriverEarningsRepository();

  @override
  DriverEarningsDataSource get source => DriverEarningsDataSource.api;

  @override
  Future<DriverEarningsLoadResult> load(DriverEarningsPeriod period) async {
    return const DriverEarningsLoadResult.failure(
      'Driver earnings are not connected to the Laravel API yet. Getin will not invent production payouts, bonuses, tips or adjustments.',
    );
  }
}

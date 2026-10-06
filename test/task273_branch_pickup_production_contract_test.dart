import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/pickup/data/driver_branch_pickup_repository.dart';
import 'package:getin_driver/features/route/data/driver_branch_route_repository.dart';

void main() {
  test('Task 273 production branch arrival and pickup use API repositories',
      () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );

    expect(
      DriverBranchRouteRepositoryFactory.create(config),
      isA<ApiDriverBranchRouteRepository>(),
    );
    expect(
      DriverBranchPickupRepositoryFactory.create(config),
      isA<ApiDriverBranchPickupRepository>(),
    );
  });
}

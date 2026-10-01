import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_completion/data/driver_delivery_completion_repository.dart';
import 'package:getin_driver/features/delivery_completion/domain/driver_delivery_completion_models.dart';

void main() {
  test('Task 118 configured production completion uses API repository', () {
    final repository = DriverDeliveryCompletionRepositoryFactory.create(
        const AppConfig(
            environment: AppEnvironment.production,
            apiBaseUrl: 'https://example.test/api'));
    expect(repository.source, DriverDeliveryCompletionDataSource.api);
    expect(repository, isA<ApiDriverDeliveryCompletionRepository>());
  });
}

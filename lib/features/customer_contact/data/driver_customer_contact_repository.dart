import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_customer_contact_models.dart';

abstract interface class DriverCustomerContactRepository {
  DriverCustomerContactDataSource get source;

  Future<DriverCustomerCallResult> callCustomer({
    required String orderNumber,
  });
}

class DriverCustomerContactRepositoryFactory {
  DriverCustomerContactRepositoryFactory._();

  static DriverCustomerContactRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverCustomerContactRepository()
        : const UnavailableDriverCustomerContactRepository();
  }
}

class DemoDriverCustomerContactRepository
    implements DriverCustomerContactRepository {
  const DemoDriverCustomerContactRepository();

  @override
  DriverCustomerContactDataSource get source =>
      DriverCustomerContactDataSource.demo;

  @override
  Future<DriverCustomerCallResult> callCustomer({
    required String orderNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const DriverCustomerCallResult(
      placed: false,
      message:
          'Demo protected call bridge is not connected. No call was placed and no customer phone number was exposed.',
    );
  }
}

class UnavailableDriverCustomerContactRepository
    implements DriverCustomerContactRepository {
  const UnavailableDriverCustomerContactRepository();

  @override
  DriverCustomerContactDataSource get source =>
      DriverCustomerContactDataSource.api;

  @override
  Future<DriverCustomerCallResult> callCustomer({
    required String orderNumber,
  }) async {
    return const DriverCustomerCallResult(
      placed: false,
      message:
          'Customer calling is not connected to Laravel yet. No call was placed and no customer phone number was exposed.',
    );
  }
}

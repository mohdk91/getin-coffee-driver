import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_customer_contact_models.dart';

abstract interface class DriverCustomerContactRepository {
  DriverCustomerContactDataSource get source;

  Future<DriverCustomerCallResult> callCustomer({
    required String orderNumber,
    int? apiOrderId,
  });
}

class DriverCustomerContactRepositoryFactory {
  DriverCustomerContactRepositoryFactory._();

  static DriverCustomerContactRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverCustomerContactRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.environment == AppEnvironment.development
        ? const DemoDriverCustomerContactRepository()
        : const UnavailableDriverCustomerContactRepository();
  }
}

class ApiDriverCustomerContactRepository
    implements DriverCustomerContactRepository {
  final DriverApiContext context;

  const ApiDriverCustomerContactRepository(this.context);

  @override
  DriverCustomerContactDataSource get source =>
      DriverCustomerContactDataSource.api;

  @override
  Future<DriverCustomerCallResult> callCustomer({
    required String orderNumber,
    int? apiOrderId,
  }) async {
    if (apiOrderId == null) {
      return const DriverCustomerCallResult(
        placed: false,
        message:
            'The active delivery is missing its Laravel order identifier. No call was placed.',
      );
    }

    try {
      final data = DriverApiContext.dataMap(
        await context.apiClient.postJson(
          '/v1/driver/orders/$apiOrderId/customer-contact/call',
          authenticated: true,
        ),
      );
      return DriverCustomerCallResult(
        placed: data['placed'] == true,
        message: data['message']?.toString() ??
            'Protected customer contact could not be confirmed.',
      );
    } on ApiException catch (error) {
      return DriverCustomerCallResult(
        placed: false,
        message: error.message,
      );
    } on FormatException catch (error) {
      return DriverCustomerCallResult(
        placed: false,
        message: error.message,
      );
    }
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
    int? apiOrderId,
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
    int? apiOrderId,
  }) async {
    return const DriverCustomerCallResult(
      placed: false,
      message:
          'Customer calling is not connected to Laravel yet. No call was placed and no customer phone number was exposed.',
    );
  }
}

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_delivery_destination_models.dart';

abstract interface class DriverDeliveryDestinationRepository {
  DriverDeliveryDestinationDataSource get source;

  Future<DriverDeliveryDestinationLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  });

  Future<String?> arriveAtCustomer({required int? apiOrderId});
}

class DriverDeliveryDestinationRepositoryFactory {
  DriverDeliveryDestinationRepositoryFactory._();

  static DriverDeliveryDestinationRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverDeliveryDestinationRepository();
    }
    return ApiDriverDeliveryDestinationRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverDeliveryDestinationRepository
    implements DriverDeliveryDestinationRepository {
  final DriverApiContext context;

  const ApiDriverDeliveryDestinationRepository(this.context);

  @override
  DriverDeliveryDestinationDataSource get source =>
      DriverDeliveryDestinationDataSource.api;

  @override
  Future<DriverDeliveryDestinationLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  }) async {
    if (apiOrderId == null) {
      return const DriverDeliveryDestinationLoadResult.failure(
        'The active delivery is missing its Laravel order identifier.',
      );
    }
    try {
      final data = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/orders/$apiOrderId',
          authenticated: true,
        ),
      );
      final delivery = data['delivery'] is Map
          ? Map<String, dynamic>.from(data['delivery'] as Map)
          : const <String, dynamic>{};
      final latitude = (delivery['latitude'] as num?)?.toDouble();
      final longitude = (delivery['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) {
        return const DriverDeliveryDestinationLoadResult.failure(
          'This assigned delivery does not have a valid destination map pin.',
        );
      }
      final line1 = delivery['address_line_1']?.toString() ?? '';
      final line2 = delivery['address_line_2']?.toString() ?? '';
      final customerNote = data['customer_notes']?.toString().trim() ?? '';
      return DriverDeliveryDestinationLoadResult.success(
        DriverDeliveryDestination(
          orderNumber: data['order_number']?.toString() ?? orderNumber,
          addressLabel: delivery['name']?.toString() ?? 'Delivery',
          streetAddress: <String>[line1, line2]
              .where((value) => value.trim().isNotEmpty)
              .join(', '),
          area: delivery['area']?.toString() ??
              delivery['city']?.toString() ??
              '',
          building: '',
          floor: '',
          apartment: '',
          latitude: latitude,
          longitude: longitude,
          deliveryInstructions:
              customerNote.isEmpty ? const <String>[] : <String>[customerNote],
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverDeliveryDestinationLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverDeliveryDestinationLoadResult.failure(error.message);
    }
  }

  @override
  Future<String?> arriveAtCustomer({required int? apiOrderId}) async {
    if (apiOrderId == null) {
      return 'The active delivery is missing its Laravel order identifier.';
    }
    try {
      await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/arrived-customer',
        authenticated: true,
        headers: <String, String>{
          'Idempotency-Key': 'driver-arrived-customer-$apiOrderId',
        },
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}

class DemoDriverDeliveryDestinationRepository
    implements DriverDeliveryDestinationRepository {
  const DemoDriverDeliveryDestinationRepository();

  @override
  DriverDeliveryDestinationDataSource get source =>
      DriverDeliveryDestinationDataSource.demo;

  @override
  Future<DriverDeliveryDestinationLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return DriverDeliveryDestinationLoadResult.success(
      DriverDeliveryDestination(
        orderNumber: orderNumber,
        addressLabel: 'Home',
        streetAddress: 'Abdel Salam Aref St, San Stefano, Alexandria',
        area: 'San Stefano',
        building: '18',
        floor: '5',
        apartment: '12B',
        latitude: 31.24555,
        longitude: 29.96728,
        deliveryInstructions: const <String>[
          'Message through Getin when you arrive at the building.',
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<String?> arriveAtCustomer({required int? apiOrderId}) async => null;
}

class UnavailableDriverDeliveryDestinationRepository
    implements DriverDeliveryDestinationRepository {
  const UnavailableDriverDeliveryDestinationRepository();
  @override
  DriverDeliveryDestinationDataSource get source =>
      DriverDeliveryDestinationDataSource.api;
  @override
  Future<DriverDeliveryDestinationLoadResult> load(
          {required String orderNumber, int? apiOrderId}) async =>
      const DriverDeliveryDestinationLoadResult.failure(
          'The exact delivery destination is not connected to the Laravel API yet. Getin will not invent a customer address, building, floor, apartment, map pin, or delivery instructions in production.');
  @override
  Future<String?> arriveAtCustomer({required int? apiOrderId}) async =>
      'Could not confirm arrival with Getin.';
}

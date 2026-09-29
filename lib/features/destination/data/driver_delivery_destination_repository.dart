import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_delivery_destination_models.dart';

abstract interface class DriverDeliveryDestinationRepository {
  DriverDeliveryDestinationDataSource get source;

  Future<DriverDeliveryDestinationLoadResult> load({
    required String orderNumber,
  });
}

class DriverDeliveryDestinationRepositoryFactory {
  DriverDeliveryDestinationRepositoryFactory._();

  static DriverDeliveryDestinationRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverDeliveryDestinationRepository()
        : const UnavailableDriverDeliveryDestinationRepository();
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
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));

    final destination = switch (orderNumber.toUpperCase()) {
      'GD-3101' => _demo(
          orderNumber: orderNumber,
          addressLabel: 'Office',
          streetAddress: 'El-Gaish Rd, San Stefano, Alexandria',
          area: 'San Stefano',
          building: 'San Stefano Grand Plaza',
          floor: '6',
          apartment: 'Office 604',
          latitude: 31.24561,
          longitude: 29.96734,
          instructions: const [
            'Use the main office entrance.',
            'Message through Getin when you reach reception.',
          ],
        ),
      'GD-3102' => _demo(
          orderNumber: orderNumber,
          addressLabel: 'Home',
          streetAddress: 'Mostafa Kamel St, Roushdy, Alexandria',
          area: 'Roushdy',
          building: '24',
          floor: '3',
          apartment: '7A',
          latitude: 31.23089,
          longitude: 29.95216,
          instructions: const [
            'Use the side entrance after 6 PM.',
            'Please do not ring the doorbell; message through Getin.',
          ],
        ),
      _ => _demo(
          orderNumber: orderNumber,
          addressLabel: 'Home',
          streetAddress: 'Abdel Salam Aref St, San Stefano, Alexandria',
          area: 'San Stefano',
          building: '18',
          floor: '5',
          apartment: '12B',
          latitude: 31.24555,
          longitude: 29.96728,
          instructions: const [
            'Enter through the main residential entrance.',
            'Message through Getin when you arrive at the building.',
            'Bring the order to the apartment door unless the customer asks otherwise.',
          ],
        ),
    };

    return DriverDeliveryDestinationLoadResult.success(destination);
  }

  static DriverDeliveryDestination _demo({
    required String orderNumber,
    required String addressLabel,
    required String streetAddress,
    required String area,
    required String building,
    required String floor,
    required String apartment,
    required double latitude,
    required double longitude,
    required List<String> instructions,
  }) {
    return DriverDeliveryDestination(
      orderNumber: orderNumber,
      addressLabel: addressLabel,
      streetAddress: streetAddress,
      area: area,
      building: building,
      floor: floor,
      apartment: apartment,
      latitude: latitude,
      longitude: longitude,
      deliveryInstructions: instructions,
      updatedAt: DateTime.now(),
    );
  }
}

class UnavailableDriverDeliveryDestinationRepository
    implements DriverDeliveryDestinationRepository {
  const UnavailableDriverDeliveryDestinationRepository();

  @override
  DriverDeliveryDestinationDataSource get source =>
      DriverDeliveryDestinationDataSource.api;

  @override
  Future<DriverDeliveryDestinationLoadResult> load({
    required String orderNumber,
  }) async {
    return const DriverDeliveryDestinationLoadResult.failure(
      'The exact delivery destination is not connected to the Laravel API yet. Getin will not invent a customer address, building, floor, apartment, map pin, or delivery instructions in production.',
    );
  }
}

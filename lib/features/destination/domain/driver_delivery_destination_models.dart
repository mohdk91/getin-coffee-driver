enum DriverDeliveryDestinationDataSource { demo, api }

class DriverDeliveryDestination {
  final String orderNumber;
  final String addressLabel;
  final String streetAddress;
  final String area;
  final String building;
  final String floor;
  final String apartment;
  final double latitude;
  final double longitude;
  final List<String> deliveryInstructions;
  final DateTime updatedAt;

  const DriverDeliveryDestination({
    required this.orderNumber,
    required this.addressLabel,
    required this.streetAddress,
    required this.area,
    required this.building,
    required this.floor,
    required this.apartment,
    required this.latitude,
    required this.longitude,
    required this.deliveryInstructions,
    required this.updatedAt,
  });
}

class DriverDeliveryDestinationLoadResult {
  final DriverDeliveryDestination? destination;
  final String? errorMessage;

  const DriverDeliveryDestinationLoadResult._({
    this.destination,
    this.errorMessage,
  });

  const DriverDeliveryDestinationLoadResult.success(
    DriverDeliveryDestination value,
  ) : this._(destination: value);

  const DriverDeliveryDestinationLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => destination != null;
}

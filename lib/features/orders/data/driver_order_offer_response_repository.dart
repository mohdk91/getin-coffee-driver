import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';

class DriverOrderOfferResponseResult {
  final bool success;
  final String message;

  const DriverOrderOfferResponseResult({
    required this.success,
    required this.message,
  });
}

abstract interface class DriverOrderOfferResponseRepository {
  Future<DriverOrderOfferResponseResult> reject(int offerId);
}

class ApiDriverOrderOfferResponseRepository
    implements DriverOrderOfferResponseRepository {
  final DriverApiContext context;

  const ApiDriverOrderOfferResponseRepository(this.context);

  @override
  Future<DriverOrderOfferResponseResult> reject(int offerId) async {
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/order-offers/$offerId/reject',
        authenticated: true,
        headers: <String, String>{
          'Idempotency-Key': 'driver-offer-reject-$offerId',
        },
      );
      return DriverOrderOfferResponseResult(
        success: true,
        message: envelope['message']?.toString() ?? 'Delivery offer declined.',
      );
    } on ApiException catch (error) {
      return DriverOrderOfferResponseResult(
        success: false,
        message: error.message,
      );
    }
  }
}

class DemoDriverOrderOfferResponseRepository
    implements DriverOrderOfferResponseRepository {
  const DemoDriverOrderOfferResponseRepository();

  @override
  Future<DriverOrderOfferResponseResult> reject(int offerId) async =>
      const DriverOrderOfferResponseResult(
        success: true,
        message: 'Test delivery offer declined.',
      );
}

class DriverOrderOfferResponseRepositoryFactory {
  DriverOrderOfferResponseRepositoryFactory._();

  static DriverOrderOfferResponseRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const DemoDriverOrderOfferResponseRepository();
    }
    return ApiDriverOrderOfferResponseRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

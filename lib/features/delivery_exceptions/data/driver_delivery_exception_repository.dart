import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_delivery_exception_models.dart';

abstract interface class DriverDeliveryExceptionRepository {
  DriverDeliveryExceptionDataSource get source;

  Future<DriverDeliveryExceptionReceipt?> loadActiveException({
    required String orderNumber,
  });

  Future<DriverDeliveryExceptionResult> reportException({
    required String orderNumber,
    required DriverDeliveryExceptionReason reason,
    required String note,
  });
}

class DriverDeliveryExceptionRepositoryFactory {
  DriverDeliveryExceptionRepositoryFactory._();

  static DriverDeliveryExceptionRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverDeliveryExceptionRepository()
        : const UnavailableDriverDeliveryExceptionRepository();
  }
}

class DemoDriverDeliveryExceptionRepository
    implements DriverDeliveryExceptionRepository {
  const DemoDriverDeliveryExceptionRepository();

  static final Map<String, DriverDeliveryExceptionReceipt> _reports = {};

  static void clearDemoState() => _reports.clear();

  @override
  DriverDeliveryExceptionDataSource get source =>
      DriverDeliveryExceptionDataSource.demo;

  @override
  Future<DriverDeliveryExceptionReceipt?> loadActiveException({
    required String orderNumber,
  }) async {
    return _reports[orderNumber.trim().toUpperCase()];
  }

  @override
  Future<DriverDeliveryExceptionResult> reportException({
    required String orderNumber,
    required DriverDeliveryExceptionReason reason,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));

    final normalizedOrder = orderNumber.trim().toUpperCase();
    final reportedAt = DateTime.now();
    final receipt = DriverDeliveryExceptionReceipt(
      auditId:
          'DEMO-EXCEPTION-$normalizedOrder-${reportedAt.millisecondsSinceEpoch}',
      orderNumber: normalizedOrder,
      driverReference: 'DEMO-DRIVER-001',
      reason: reason,
      note: note.trim(),
      reportedAt: reportedAt,
      latitude: 31.24580,
      longitude: 29.96680,
      recommendedOrderState: reason.recommendedOrderState,
      serverAcknowledged: false,
      isDemo: true,
    );

    _reports[normalizedOrder] = receipt;
    return DriverDeliveryExceptionResult.success(
      value: receipt,
      message:
          'Exception recorded locally for development only. Laravel has not changed the order state.',
    );
  }
}

class UnavailableDriverDeliveryExceptionRepository
    implements DriverDeliveryExceptionRepository {
  const UnavailableDriverDeliveryExceptionRepository();

  @override
  DriverDeliveryExceptionDataSource get source =>
      DriverDeliveryExceptionDataSource.api;

  @override
  Future<DriverDeliveryExceptionReceipt?> loadActiveException({
    required String orderNumber,
  }) async =>
      null;

  @override
  Future<DriverDeliveryExceptionResult> reportException({
    required String orderNumber,
    required DriverDeliveryExceptionReason reason,
    required String note,
  }) async {
    return const DriverDeliveryExceptionResult.failure(
      message:
          'Could not confirm this exception with Getin. The order status has not changed. Retry or contact operations.',
    );
  }
}

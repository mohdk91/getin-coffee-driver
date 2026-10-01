import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_delivery_exception_models.dart';

abstract interface class DriverDeliveryExceptionRepository {
  DriverDeliveryExceptionDataSource get source;
  Future<DriverDeliveryExceptionReceipt?> loadActiveException(
      {required int? apiOrderId, required String orderNumber});
  Future<DriverDeliveryExceptionResult> reportException(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryExceptionReason reason,
      required String note});
}

class DriverDeliveryExceptionRepositoryFactory {
  DriverDeliveryExceptionRepositoryFactory._();
  static DriverDeliveryExceptionRepository create(AppConfig config,
      {DriverApiContext? context}) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverDeliveryExceptionRepository();
    }
    return ApiDriverDeliveryExceptionRepository(
        context ?? DriverApiContext.create(config));
  }
}

class ApiDriverDeliveryExceptionRepository
    implements DriverDeliveryExceptionRepository {
  final DriverApiContext context;
  const ApiDriverDeliveryExceptionRepository(this.context);
  @override
  DriverDeliveryExceptionDataSource get source =>
      DriverDeliveryExceptionDataSource.api;
  @override
  Future<DriverDeliveryExceptionReceipt?> loadActiveException(
          {required int? apiOrderId, required String orderNumber}) async =>
      null;

  @override
  Future<DriverDeliveryExceptionResult> reportException(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryExceptionReason reason,
      required String note}) async {
    if (apiOrderId == null) {
      return const DriverDeliveryExceptionResult.failure(
          message:
              'The active delivery is missing its Laravel order identifier.');
    }
    try {
      final envelope = await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/fail-delivery',
        authenticated: true,
        body: <String, Object?>{
          'reason_code': _failureCode(reason),
          'note': note.trim().isEmpty ? null : note.trim()
        },
        headers: <String, String>{
          'Idempotency-Key': 'driver-fail-$apiOrderId-${reason.name}'
        },
      );
      final data = DriverApiContext.dataMap(envelope);
      final failure = data['failure'] is Map
          ? Map<String, dynamic>.from(data['failure'] as Map)
          : <String, dynamic>{};
      final requiresReturn = failure['requires_return'] == true;
      final reportedAt =
          DateTime.tryParse(failure['failed_at']?.toString() ?? '') ??
              DateTime.now();
      return DriverDeliveryExceptionResult.success(
        value: DriverDeliveryExceptionReceipt(
          auditId: failure['id']?.toString() ?? 'failure-$apiOrderId',
          orderNumber: orderNumber,
          driverReference: 'server-authenticated-driver',
          reason: reason,
          note: note.trim(),
          reportedAt: reportedAt,
          latitude: null,
          longitude: null,
          recommendedOrderState:
              requiresReturn ? 'failed_delivery' : 'failed_delivery',
          serverAcknowledged: true,
          isDemo: false,
        ),
        message: envelope['message']?.toString() ??
            'Delivery failure recorded by Getin.',
      );
    } on ApiException catch (error) {
      return DriverDeliveryExceptionResult.failure(message: error.message);
    } on FormatException catch (error) {
      return DriverDeliveryExceptionResult.failure(message: error.message);
    }
  }

  static String _failureCode(DriverDeliveryExceptionReason reason) =>
      switch (reason) {
        DriverDeliveryExceptionReason.customerUnavailable =>
          'customer_unavailable',
        DriverDeliveryExceptionReason.wrongAddress => 'wrong_address',
        DriverDeliveryExceptionReason.customerRefused => 'customer_rejected',
        DriverDeliveryExceptionReason.cannotAccessBuilding => 'access_issue',
        DriverDeliveryExceptionReason.damagedOrder => 'damaged_order',
        DriverDeliveryExceptionReason.safetyIssue => 'safety_issue',
        DriverDeliveryExceptionReason.supportRequired => 'other',
        DriverDeliveryExceptionReason.returnToBranch => 'other',
      };
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
  Future<DriverDeliveryExceptionReceipt?> loadActiveException(
          {required int? apiOrderId, required String orderNumber}) async =>
      _reports[orderNumber.trim().toUpperCase()];
  @override
  Future<DriverDeliveryExceptionResult> reportException(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryExceptionReason reason,
      required String note}) async {
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
        isDemo: true);
    _reports[normalizedOrder] = receipt;
    return DriverDeliveryExceptionResult.success(
        value: receipt,
        message:
            'Exception recorded locally for development only. Laravel has not changed the order state.');
  }
}

class UnavailableDriverDeliveryExceptionRepository
    implements DriverDeliveryExceptionRepository {
  const UnavailableDriverDeliveryExceptionRepository();
  @override
  DriverDeliveryExceptionDataSource get source =>
      DriverDeliveryExceptionDataSource.api;
  @override
  Future<DriverDeliveryExceptionReceipt?> loadActiveException(
          {required int? apiOrderId, required String orderNumber}) async =>
      null;
  @override
  Future<DriverDeliveryExceptionResult> reportException(
          {required int? apiOrderId,
          required String orderNumber,
          required DriverDeliveryExceptionReason reason,
          required String note}) async =>
      const DriverDeliveryExceptionResult.failure(
          message:
              'Could not confirm this exception with Getin. The order status has not changed. Retry or contact operations.');
}

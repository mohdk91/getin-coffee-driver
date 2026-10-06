import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/uat/driver_uat_delivery_exception_store.dart';
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
    if (config.allowsDemo) {
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
  Future<DriverDeliveryExceptionReceipt?> loadActiveException({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    if (apiOrderId == null) {
      return null;
    }
    try {
      final envelope = await context.apiClient.getJson(
        '/v1/driver/orders/$apiOrderId/exceptions',
        authenticated: true,
      );
      final items = DriverApiContext.dataList(envelope);
      for (final raw in items.reversed) {
        if (raw is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(raw);
        final status = item['status']?.toString();
        if (status == 'resolved' || status == 'closed') {
          continue;
        }
        final reason = _reasonFromExceptionCode(item['code']?.toString());
        if (reason == null) {
          continue;
        }
        return DriverDeliveryExceptionReceipt(
          auditId: item['id']?.toString() ?? 'exception-$apiOrderId',
          orderNumber: orderNumber,
          driverReference: 'server-authenticated-driver',
          reason: reason,
          note: item['description']?.toString() ?? '',
          reportedAt:
              DateTime.tryParse(item['occurred_at']?.toString() ?? '') ??
                  DateTime.now(),
          latitude: null,
          longitude: null,
          recommendedOrderState: reason.recommendedOrderState,
          serverAcknowledged: true,
          isDemo: false,
        );
      }
      return null;
    } on ApiException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<DriverDeliveryExceptionResult> reportException(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryExceptionReason reason,
      required String note}) async {
    if (apiOrderId == null) {
      return const DriverDeliveryExceptionResult.failure(
        message: 'The active delivery is missing its Laravel order identifier.',
      );
    }
    try {
      await context.apiClient.requestJson(
        'POST',
        '/v1/driver/orders/$apiOrderId/exceptions',
        authenticated: true,
        body: <String, Object?>{
          'category': _exceptionCategory(reason),
          'code': _exceptionCode(reason),
          'title': reason.label,
          'description': note.trim().isEmpty ? reason.description : note.trim(),
          'metadata': <String, Object?>{'source': 'driver_app'},
        },
        headers: <String, String>{
          'Idempotency-Key':
              'driver-exception-$apiOrderId-${_exceptionCode(reason)}',
        },
      );

      if (reason == DriverDeliveryExceptionReason.returnToBranch) {
        await context.apiClient.requestJson(
          'POST',
          '/v1/driver/orders/$apiOrderId/fail-delivery',
          authenticated: true,
          body: <String, Object?>{
            'reason_code': 'other',
            'note': note.trim().isEmpty
                ? 'Return to branch requested.'
                : note.trim(),
          },
          headers: <String, String>{
            'Idempotency-Key': 'driver-fail-return-$apiOrderId',
          },
        );
        final returnEnvelope = await context.apiClient.requestJson(
          'POST',
          '/v1/driver/orders/$apiOrderId/return-to-branch',
          authenticated: true,
          body: <String, Object?>{
            'note': note.trim().isEmpty ? null : note.trim(),
          },
          headers: <String, String>{
            'Idempotency-Key': 'driver-return-$apiOrderId',
          },
        );
        final returnData = DriverApiContext.dataMap(returnEnvelope);
        final failure = returnData['failure'] is Map
            ? Map<String, dynamic>.from(returnData['failure'] as Map)
            : <String, dynamic>{};
        final reportedAt =
            DateTime.tryParse(failure['returned_at']?.toString() ?? '') ??
                DateTime.now();
        return DriverDeliveryExceptionResult.success(
          value: DriverDeliveryExceptionReceipt(
            auditId: failure['id']?.toString() ?? 'return-$apiOrderId',
            orderNumber: orderNumber,
            driverReference: 'server-authenticated-driver',
            reason: reason,
            note: note.trim(),
            reportedAt: reportedAt,
            latitude: null,
            longitude: null,
            recommendedOrderState: 'returned_to_branch',
            serverAcknowledged: true,
            isDemo: false,
          ),
          message: returnEnvelope['message']?.toString() ??
              'Return to branch confirmed by Getin.',
        );
      }

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

  static String _exceptionCategory(DriverDeliveryExceptionReason reason) =>
      switch (reason) {
        DriverDeliveryExceptionReason.customerUnavailable => 'customer',
        DriverDeliveryExceptionReason.wrongAddress => 'address',
        DriverDeliveryExceptionReason.customerRefused => 'customer',
        DriverDeliveryExceptionReason.cannotAccessBuilding => 'address',
        DriverDeliveryExceptionReason.damagedOrder => 'order',
        DriverDeliveryExceptionReason.safetyIssue => 'safety',
        DriverDeliveryExceptionReason.supportRequired => 'other',
        DriverDeliveryExceptionReason.returnToBranch => 'branch',
      };

  static String _exceptionCode(DriverDeliveryExceptionReason reason) =>
      switch (reason) {
        DriverDeliveryExceptionReason.customerUnavailable =>
          'customer_unavailable',
        DriverDeliveryExceptionReason.wrongAddress => 'wrong_address',
        DriverDeliveryExceptionReason.customerRefused => 'customer_refused',
        DriverDeliveryExceptionReason.cannotAccessBuilding => 'access_issue',
        DriverDeliveryExceptionReason.damagedOrder => 'damaged_order',
        DriverDeliveryExceptionReason.safetyIssue => 'safety_issue',
        DriverDeliveryExceptionReason.supportRequired => 'support_required',
        DriverDeliveryExceptionReason.returnToBranch => 'return_to_branch',
      };

  static DriverDeliveryExceptionReason? _reasonFromExceptionCode(
          String? code) =>
      switch (code) {
        'customer_unavailable' =>
          DriverDeliveryExceptionReason.customerUnavailable,
        'wrong_address' => DriverDeliveryExceptionReason.wrongAddress,
        'customer_refused' => DriverDeliveryExceptionReason.customerRefused,
        'access_issue' => DriverDeliveryExceptionReason.cannotAccessBuilding,
        'damaged_order' => DriverDeliveryExceptionReason.damagedOrder,
        'safety_issue' => DriverDeliveryExceptionReason.safetyIssue,
        'support_required' => DriverDeliveryExceptionReason.supportRequired,
        'return_to_branch' => DriverDeliveryExceptionReason.returnToBranch,
        _ => null,
      };

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
  static SharedPreferencesDriverUatDeliveryExceptionStore _store =
      SharedPreferencesDriverUatDeliveryExceptionStore();

  static void clearDemoState() {
    _reports.clear();
    _store = SharedPreferencesDriverUatDeliveryExceptionStore();
  }

  static Future<void> clearPersistedDemoState() async {
    _reports.clear();
    await _store.clearAll();
    _store = SharedPreferencesDriverUatDeliveryExceptionStore();
  }

  static String _key(String orderNumber) =>
      orderNumber.trim().toUpperCase();

  static bool _belongsToOrder(
    DriverDeliveryExceptionReceipt receipt,
    String orderNumber,
  ) =>
      _key(receipt.orderNumber) == _key(orderNumber);
  @override
  DriverDeliveryExceptionDataSource get source =>
      DriverDeliveryExceptionDataSource.demo;
  @override
  Future<DriverDeliveryExceptionReceipt?> loadActiveException({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    final key = _key(orderNumber);
    final inMemory = _reports[key];
    if (inMemory != null && _belongsToOrder(inMemory, key)) {
      return inMemory;
    }

    final persisted = await _store.load(key);
    if (persisted == null || !_belongsToOrder(persisted, key)) {
      return null;
    }
    _reports[key] = persisted;
    return persisted;
  }
  @override
  Future<DriverDeliveryExceptionResult> reportException(
      {required int? apiOrderId,
      required String orderNumber,
      required DriverDeliveryExceptionReason reason,
      required String note}) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final normalizedOrder = _key(orderNumber);
    final existing = await loadActiveException(
      apiOrderId: apiOrderId,
      orderNumber: normalizedOrder,
    );
    final now = DateTime.now();
    final trimmedNote = note.trim();
    final effectiveNote = trimmedNote.isEmpty && (existing?.note.isNotEmpty ?? false)
        ? existing!.note
        : trimmedNote;
    final receipt = DriverDeliveryExceptionReceipt(
        auditId: existing?.auditId ??
            'DEMO-EXCEPTION-$normalizedOrder-${now.millisecondsSinceEpoch}',
        orderNumber: normalizedOrder,
        driverReference: 'DEMO-DRIVER-001',
        reason: reason,
        note: effectiveNote,
        reportedAt: existing?.reportedAt ?? now,
        latitude: 31.24580,
        longitude: 29.96680,
        recommendedOrderState: reason.recommendedOrderState,
        serverAcknowledged: false,
        isDemo: true);
    _reports[normalizedOrder] = receipt;
    await _store.upsert(receipt);
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
  Future<DriverDeliveryExceptionReceipt?> loadActiveException({
    required int? apiOrderId,
    required String orderNumber,
  }) async {
    return null;
  }

  @override
  Future<DriverDeliveryExceptionResult> reportException({
    required int? apiOrderId,
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

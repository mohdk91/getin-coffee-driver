import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_order_contents_models.dart';

abstract interface class DriverOrderContentsRepository {
  DriverOrderContentsDataSource get source;

  Future<DriverOrderContentsLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  });
}

class DriverOrderContentsRepositoryFactory {
  DriverOrderContentsRepositoryFactory._();

  static DriverOrderContentsRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const DemoDriverOrderContentsRepository();
    }
    return ApiDriverOrderContentsRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverOrderContentsRepository
    implements DriverOrderContentsRepository {
  final DriverApiContext context;

  const ApiDriverOrderContentsRepository(this.context);

  @override
  DriverOrderContentsDataSource get source => DriverOrderContentsDataSource.api;

  @override
  Future<DriverOrderContentsLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  }) async {
    if (apiOrderId == null) {
      return const DriverOrderContentsLoadResult.failure(
        'The live order identifier is missing. Refresh the active delivery and try again.',
      );
    }
    try {
      final data = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/orders/$apiOrderId',
          authenticated: true,
        ),
      );
      final items = (data['items'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);
      final handling = <String>{};
      var itemCount = 0;
      for (final item in items) {
        itemCount += (item['quantity'] as num?)?.toInt() ?? 0;
        final note = item['notes']?.toString().trim() ?? '';
        if (note.isNotEmpty) handling.add(note);
      }
      final customerNote = data['customer_notes']?.toString().trim() ?? '';
      return DriverOrderContentsLoadResult.success(
        DriverOrderContents(
          orderNumber: data['order_number']?.toString() ?? orderNumber,
          bagCount: items.isEmpty ? 0 : 1,
          itemCount: itemCount,
          handlingInstructions: handling.toList(growable: false),
          customerDeliveryNotes:
              customerNote.isEmpty ? const <String>[] : <String>[customerNote],
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverOrderContentsLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverOrderContentsLoadResult.failure(error.message);
    }
  }
}

class DemoDriverOrderContentsRepository
    implements DriverOrderContentsRepository {
  const DemoDriverOrderContentsRepository();

  @override
  DriverOrderContentsDataSource get source =>
      DriverOrderContentsDataSource.demo;

  @override
  Future<DriverOrderContentsLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));

    final definition = switch (orderNumber.toUpperCase()) {
      'GD-3101' => const _DemoContentsDefinition(
          bagCount: 2,
          itemCount: 5,
          handlingInstructions: [
            'Keep all drinks upright during transport.',
            'Keep hot and cold items separated.',
            'Check both bag seals before leaving the branch.',
          ],
          customerDeliveryNotes: [
            'Handle the drinks carefully during the ride.',
            'Keep the bags upright until handoff.',
          ],
        ),
      'GD-3102' => const _DemoContentsDefinition(
          bagCount: 1,
          itemCount: 3,
          handlingInstructions: [
            'Keep the bag upright.',
            'Do not place heavy items on top of the order.',
          ],
          customerDeliveryNotes: [
            'Please keep the order sealed until delivery.',
          ],
        ),
      _ => const _DemoContentsDefinition(
          bagCount: 2,
          itemCount: 4,
          handlingInstructions: [
            'Keep all drinks upright during transport.',
            'Keep hot and cold items separated.',
            'Confirm all bag seals before leaving the branch.',
          ],
          customerDeliveryNotes: [
            'Please handle the drinks carefully.',
            'Do not place the delivery bags directly on the floor.',
          ],
        ),
    };

    return DriverOrderContentsLoadResult.success(
      DriverOrderContents(
        orderNumber: orderNumber,
        bagCount: definition.bagCount,
        itemCount: definition.itemCount,
        handlingInstructions: definition.handlingInstructions,
        customerDeliveryNotes: definition.customerDeliveryNotes,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class UnavailableDriverOrderContentsRepository
    implements DriverOrderContentsRepository {
  const UnavailableDriverOrderContentsRepository();

  @override
  DriverOrderContentsDataSource get source => DriverOrderContentsDataSource.api;

  @override
  Future<DriverOrderContentsLoadResult> load({
    required String orderNumber,
    int? apiOrderId,
  }) async {
    return const DriverOrderContentsLoadResult.failure(
      'Order contents are not connected to the Laravel API yet. Getin will not invent bag counts, item counts, handling instructions, or customer notes in production.',
    );
  }
}

class _DemoContentsDefinition {
  final int bagCount;
  final int itemCount;
  final List<String> handlingInstructions;
  final List<String> customerDeliveryNotes;

  const _DemoContentsDefinition({
    required this.bagCount,
    required this.itemCount,
    required this.handlingInstructions,
    required this.customerDeliveryNotes,
  });
}

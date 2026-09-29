import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_order_contents_models.dart';

abstract interface class DriverOrderContentsRepository {
  DriverOrderContentsDataSource get source;

  Future<DriverOrderContentsLoadResult> load({required String orderNumber});
}

class DriverOrderContentsRepositoryFactory {
  DriverOrderContentsRepositoryFactory._();

  static DriverOrderContentsRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverOrderContentsRepository()
        : const UnavailableDriverOrderContentsRepository();
  }
}

class DemoDriverOrderContentsRepository
    implements DriverOrderContentsRepository {
  const DemoDriverOrderContentsRepository();

  @override
  DriverOrderContentsDataSource get source =>
      DriverOrderContentsDataSource.demo;

  @override
  Future<DriverOrderContentsLoadResult> load(
      {required String orderNumber}) async {
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
  Future<DriverOrderContentsLoadResult> load(
      {required String orderNumber}) async {
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

import '../../../core/data/driver_api_context.dart';
import '../../active_delivery/domain/driver_delivery_state_machine.dart';
import '../../home/domain/driver_home_models.dart';
import 'driver_runtime_recovery_store.dart';

class DriverRuntimeRecoveryApiRepository {
  final DriverApiContext context;
  const DriverRuntimeRecoveryApiRepository(this.context);

  Future<DriverRuntimeRecoverySnapshot> load() async {
    final envelope = await context.apiClient.getJson(
      '/v1/driver/runtime',
      authenticated: true,
    );
    final data = DriverApiContext.dataMap(envelope);
    final raw = data['active_delivery'];
    if (raw == null) {
      return DriverRuntimeRecoverySnapshot.empty;
    }
    if (raw is! Map) {
      throw const FormatException('Driver runtime active delivery is invalid.');
    }
    final order = Map<String, dynamic>.from(raw);
    final id = order['id'];
    final number = order['order_number']?.toString();
    final stateRaw = order['delivery_state']?.toString();
    if (id is! num || number == null || stateRaw == null) {
      throw const FormatException(
          'Driver runtime delivery identifiers are missing.');
    }
    final branch = order['branch'] is Map
        ? Map<String, dynamic>.from(order['branch'] as Map)
        : const <String, dynamic>{};
    final delivery = order['delivery'] is Map
        ? Map<String, dynamic>.from(order['delivery'] as Map)
        : const <String, dynamic>{};
    final state = DriverDeliveryState.values.firstWhere(
      (candidate) => candidate.wireValue == stateRaw,
      orElse: () => driverDeliveryStateFromStatus(stateRaw),
    );
    final area = delivery['area']?.toString();
    final city = delivery['city']?.toString();
    return DriverRuntimeRecoverySnapshot(
      activeDelivery: DriverActiveDeliverySummary(
        apiOrderId: id.toInt(),
        orderNumber: number,
        status: stateRaw,
        pickupBranch: branch['name']?.toString() ?? 'Assigned branch',
        destinationArea: area?.trim().isNotEmpty == true
            ? area!
            : (city?.trim().isNotEmpty == true
                ? city!
                : 'Delivery destination'),
        etaMinutes: 0,
        state: state,
      ),
      lastSuccessfulSyncAt: DateTime.now(),
    );
  }
}

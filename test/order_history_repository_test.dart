import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/order_history/data/driver_order_history_repository.dart';
import 'package:getin_driver/features/order_history/domain/driver_order_history_models.dart';

void main() {
  test('Task 25 demo history contains delivered and cancelled groups',
      () async {
    const repository = DemoDriverOrderHistoryRepository();
    final result = await repository.load();
    expect(result.isSuccess, isTrue);
    final items = result.snapshot!.items;
    expect(items.any((item) => item.group == DriverOrderHistoryGroup.delivered),
        isTrue);
    expect(items.any((item) => item.group == DriverOrderHistoryGroup.cancelled),
        isTrue);
    expect(result.snapshot!.branches, contains('Stanley'));
  });

  test('Task 25 production history does not invent server orders', () async {
    const repository = UnavailableDriverOrderHistoryRepository();
    final result = await repository.load();
    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('Laravel API'));
  });
}

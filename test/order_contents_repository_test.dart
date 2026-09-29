import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/order_contents/data/driver_order_contents_repository.dart';

void main() {
  test('Task 14 demo contents expose transport summary only', () async {
    const repository = DemoDriverOrderContentsRepository();

    final result = await repository.load(orderNumber: 'GD-3101');

    expect(result.isSuccess, isTrue);
    expect(result.contents?.orderNumber, 'GD-3101');
    expect(result.contents?.bagCount, 2);
    expect(result.contents?.itemCount, 5);
    expect(result.contents?.handlingInstructions, isNotEmpty);
    expect(result.contents?.customerDeliveryNotes, isNotEmpty);
  });

  test('Task 14 production repository refuses invented contents', () async {
    const repository = UnavailableDriverOrderContentsRepository();

    final result = await repository.load(orderNumber: 'GD-3101');

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, contains('Laravel API'));
    expect(result.errorMessage, contains('will not invent'));
  });
}

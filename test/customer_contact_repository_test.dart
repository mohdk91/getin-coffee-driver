import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_chat_repository.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_contact_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Task 17 chat uses an order-specific driver thread and persists locally',
      () async {
    const repository = DemoDriverCustomerChatRepository();

    final first = await repository.loadThread(orderNumber: 'GD-2481');
    expect(first.isSuccess, isTrue);
    expect(first.thread!.threadId, 'driver:GD-2481');
    expect(first.thread!.messages, isNotEmpty);

    final sent = await repository.sendDriverMessage(
      orderNumber: 'GD-2481',
      text: 'I am arriving soon.',
    );
    expect(sent.isSuccess, isTrue);
    expect(
      sent.thread!.messages
          .any((message) => message.text == 'I am arriving soon.'),
      isTrue,
    );

    final otherOrder = await repository.loadThread(orderNumber: 'GD-9999');
    expect(otherOrder.thread!.threadId, 'driver:GD-9999');
    expect(
      otherOrder.thread!.messages.any(
        (message) => message.text == 'I am arriving soon.',
      ),
      isFalse,
    );
  });

  test('Task 17 demo call never claims a customer call was placed', () async {
    const repository = DemoDriverCustomerContactRepository();
    final result = await repository.callCustomer(orderNumber: 'GD-2481');

    expect(result.placed, isFalse);
    expect(result.message, contains('No call was placed'));
    expect(result.message, contains('no customer phone number was exposed'));
  });
}

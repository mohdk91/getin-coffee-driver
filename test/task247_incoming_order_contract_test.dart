import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task 247 checks capacity before showing and before accepting an offer',
      () {
    final source = File(
      'lib/features/foundation/driver_foundation_shell.dart',
    ).readAsStringSync();

    expect(source, contains('_prepareIncomingOrderUatIdleDriver'));
    expect(source, contains('_prepareIncomingOrderUatActiveDriver'));
    expect(source, contains('if (!initialCapacity.canReceiveOffer)'));
    expect(source, contains('if (!acceptanceCapacity.canReceiveOffer)'));
    expect(source, contains("title: const Text('New order blocked')"));
  });
}

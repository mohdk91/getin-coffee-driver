import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/security/data/driver_security_repository.dart';

void main() {
  test('Task 36 demo security exposes password, PIN and active devices',
      () async {
    final repository = DemoDriverSecurityRepository();
    final result = await repository.loadSecurity();

    expect(result.isSuccess, isTrue);
    expect(result.snapshot!.passwordProtected, isTrue);
    expect(result.snapshot!.pinConfigured, isTrue);
    expect(result.snapshot!.activeSessions.length, 2);
    expect(
      result.snapshot!.activeSessions.where((session) => session.isCurrent),
      hasLength(1),
    );
  });

  test('Task 36 demo password rejects wrong current password', () async {
    final repository = DemoDriverSecurityRepository();
    final result = await repository.changePassword(
      currentPassword: 'wrong',
      newPassword: 'NewDriver123!',
    );

    expect(result.success, isFalse);
    expect(result.message, contains('incorrect'));
  });

  test('Task 36 demo PIN requires four to six digits', () async {
    final repository = DemoDriverSecurityRepository();

    final invalid = await repository.setPin(pin: '12');
    final valid = await repository.setPin(pin: '654321');
    final snapshot = await repository.loadSecurity();

    expect(invalid.success, isFalse);
    expect(valid.success, isTrue);
    expect(snapshot.snapshot!.pinDigits, 6);
  });

  test('Task 36 demo can revoke another session but not current device',
      () async {
    final repository = DemoDriverSecurityRepository();
    final before = await repository.loadSecurity();
    final current = before.snapshot!.activeSessions.firstWhere(
      (session) => session.isCurrent,
    );
    final other = before.snapshot!.activeSessions.firstWhere(
      (session) => !session.isCurrent,
    );

    final currentResult = await repository.revokeSession(current.id);
    final otherResult = await repository.revokeSession(other.id);
    final after = await repository.loadSecurity();

    expect(currentResult.success, isFalse);
    expect(otherResult.success, isTrue);
    expect(after.snapshot!.activeSessions, hasLength(1));
    expect(after.snapshot!.activeSessions.single.isCurrent, isTrue);
  });
}

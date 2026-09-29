import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../verification/data/driver_verification_repository.dart';
import '../verification/domain/driver_verification_models.dart';
import '../verification/driver_verification_status_screen.dart';
import 'domain/driver_auth_models.dart';
import 'driver_account_state_screen.dart';

Future<void> navigateAfterDriverAuthentication({
  required BuildContext context,
  required AppConfig config,
  required DriverAuthenticatedAccount account,
  required WidgetBuilder signInBuilder,
}) async {
  final destination = account.accessState == DriverAccessState.disabled
      ? DriverAccountStateScreen(
          config: config,
          account: account,
          signInBuilder: signInBuilder,
        )
      : DriverVerificationStatusScreen(
          config: config,
          initialProfile: _verificationProfileFromAccount(account),
          repository: DriverVerificationRepositoryFactory.create(config),
          signInBuilder: signInBuilder,
        );

  await Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => destination),
    (_) => false,
  );
}

DriverVerificationProfile _verificationProfileFromAccount(
  DriverAuthenticatedAccount account,
) {
  final state = switch (account.accessState) {
    DriverAccessState.active => DriverVerificationState.approved,
    DriverAccessState.pendingApproval => DriverVerificationState.pending,
    DriverAccessState.additionalInformationRequired =>
      DriverVerificationState.additionalInformationRequired,
    DriverAccessState.rejected => DriverVerificationState.rejected,
    DriverAccessState.suspended => DriverVerificationState.suspended,
    DriverAccessState.disabled => DriverVerificationState.suspended,
  };

  return DriverVerificationProfile(
    driverId: account.driverId,
    displayName: account.displayName,
    state: state,
    updatedAt: DateTime.now(),
    requestedItems:
        state == DriverVerificationState.additionalInformationRequired
            ? const [
                'Upload a clearer National ID image',
                'Confirm the driving licence expiry date',
              ]
            : const [],
  );
}

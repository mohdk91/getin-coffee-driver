import '../../eligibility/domain/driver_order_eligibility_models.dart';

enum DriverOrderAcceptanceOutcome {
  accepted,
  alreadyTaken,
  timeout,
  serverFailure,
}

extension DriverOrderAcceptanceOutcomePresentation
    on DriverOrderAcceptanceOutcome {
  String get label => switch (this) {
        DriverOrderAcceptanceOutcome.accepted => 'Accepted',
        DriverOrderAcceptanceOutcome.alreadyTaken => 'Already taken',
        DriverOrderAcceptanceOutcome.timeout => 'Timed out',
        DriverOrderAcceptanceOutcome.serverFailure => 'Server failure',
      };
}

class DriverOrderAcceptanceResult {
  final DriverOrderAcceptanceOutcome outcome;
  final String message;
  final String? lockToken;
  final DateTime? acceptedAt;

  const DriverOrderAcceptanceResult({
    required this.outcome,
    required this.message,
    this.lockToken,
    this.acceptedAt,
  });

  bool get isAccepted => outcome == DriverOrderAcceptanceOutcome.accepted;
  bool get canRetry =>
      outcome == DriverOrderAcceptanceOutcome.timeout ||
      outcome == DriverOrderAcceptanceOutcome.serverFailure;
}

class DriverAcceptedOrder {
  final DriverOrderCandidate order;
  final DriverOrderAcceptanceResult result;

  const DriverAcceptedOrder({required this.order, required this.result});
}

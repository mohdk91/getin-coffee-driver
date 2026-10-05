typedef DriverCriticalActionGate = bool Function();

enum DriverCriticalAction {
  acceptOrder,
  receivedFromBranch,
  arriveAtCustomer,
  customerVerification,
  completeDelivery,
}

extension DriverCriticalActionPresentation on DriverCriticalAction {
  String get label {
    return switch (this) {
      DriverCriticalAction.acceptOrder => 'Accept Order',
      DriverCriticalAction.receivedFromBranch => 'Received from Branch',
      DriverCriticalAction.arriveAtCustomer => 'Arrived at Customer',
      DriverCriticalAction.customerVerification => 'Customer Verification',
      DriverCriticalAction.completeDelivery => 'Complete Delivery',
    };
  }

  String get offlineMessage =>
      "You're offline. $label was not sent to Getin and no delivery state changed. Reconnect, then retry safely.";
}

bool driverCriticalActionAllowed(DriverCriticalActionGate? gate) {
  return gate?.call() ?? true;
}

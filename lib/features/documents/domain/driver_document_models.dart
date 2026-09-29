enum DriverDocumentDataSource { demo, api }

enum DriverDocumentType {
  identity('ID', 'Government identity document'),
  driverLicense('Driver license', 'License required for delivery work'),
  vehicleRegistration('Vehicle documents', 'Registration or ownership record'),
  insurance('Insurance', 'Vehicle insurance when applicable');

  final String label;
  final String description;
  const DriverDocumentType(this.label, this.description);
}

enum DriverDocumentApprovalState {
  approved('Approved'),
  pendingReview('Pending review'),
  rejected('Rejected'),
  expired('Expired'),
  missing('Missing');

  final String label;
  const DriverDocumentApprovalState(this.label);
}

enum DriverDocumentExpiryState {
  valid,
  expiringSoon,
  expired,
  notApplicable,
}

class DriverDocumentSnapshot {
  final String id;
  final DriverDocumentType type;
  final String referenceLabel;
  final DriverDocumentApprovalState approvalState;
  final DateTime? expiryDate;
  final bool replacementAllowed;
  final int expiryWarningDays;
  final String? replacementFileName;
  final DateTime? replacementSubmittedAt;

  const DriverDocumentSnapshot({
    required this.id,
    required this.type,
    required this.referenceLabel,
    required this.approvalState,
    required this.expiryDate,
    required this.replacementAllowed,
    this.expiryWarningDays = 30,
    this.replacementFileName,
    this.replacementSubmittedAt,
  });

  int? daysUntilExpiry(DateTime now) {
    final expiry = expiryDate;
    if (expiry == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDay.difference(today).inDays;
  }

  DriverDocumentExpiryState expiryStateAt(DateTime now) {
    final days = daysUntilExpiry(now);
    if (days == null) return DriverDocumentExpiryState.notApplicable;
    if (days < 0) return DriverDocumentExpiryState.expired;
    if (days <= expiryWarningDays) {
      return DriverDocumentExpiryState.expiringSoon;
    }
    return DriverDocumentExpiryState.valid;
  }

  bool hasExpiryWarningAt(DateTime now) {
    final state = expiryStateAt(now);
    return state == DriverDocumentExpiryState.expiringSoon ||
        state == DriverDocumentExpiryState.expired;
  }

  DriverDocumentSnapshot copyWith({
    DriverDocumentApprovalState? approvalState,
    DateTime? expiryDate,
    String? replacementFileName,
    DateTime? replacementSubmittedAt,
  }) {
    return DriverDocumentSnapshot(
      id: id,
      type: type,
      referenceLabel: referenceLabel,
      approvalState: approvalState ?? this.approvalState,
      expiryDate: expiryDate ?? this.expiryDate,
      replacementAllowed: replacementAllowed,
      expiryWarningDays: expiryWarningDays,
      replacementFileName: replacementFileName ?? this.replacementFileName,
      replacementSubmittedAt:
          replacementSubmittedAt ?? this.replacementSubmittedAt,
    );
  }
}

class DriverDocumentsLoadResult {
  final List<DriverDocumentSnapshot>? documents;
  final String? errorMessage;

  const DriverDocumentsLoadResult._({this.documents, this.errorMessage});

  const DriverDocumentsLoadResult.success(List<DriverDocumentSnapshot> value)
      : this._(documents: value);

  const DriverDocumentsLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => documents != null;
}

class DriverDocumentReplacementRequest {
  final String documentId;
  final String fileName;

  const DriverDocumentReplacementRequest({
    required this.documentId,
    required this.fileName,
  });
}

class DriverDocumentReplacementResult {
  final DriverDocumentSnapshot? document;
  final String? errorMessage;

  const DriverDocumentReplacementResult._({
    this.document,
    this.errorMessage,
  });

  const DriverDocumentReplacementResult.success(
    DriverDocumentSnapshot value,
  ) : this._(document: value);

  const DriverDocumentReplacementResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => document != null;
}

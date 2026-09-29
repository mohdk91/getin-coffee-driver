enum DriverOrderContentsDataSource { demo, api }

class DriverOrderContents {
  final String orderNumber;
  final int bagCount;
  final int itemCount;
  final List<String> handlingInstructions;
  final List<String> customerDeliveryNotes;
  final DateTime updatedAt;

  const DriverOrderContents({
    required this.orderNumber,
    required this.bagCount,
    required this.itemCount,
    required this.handlingInstructions,
    required this.customerDeliveryNotes,
    required this.updatedAt,
  });
}

class DriverOrderContentsLoadResult {
  final DriverOrderContents? contents;
  final String? errorMessage;

  const DriverOrderContentsLoadResult._({this.contents, this.errorMessage});

  const DriverOrderContentsLoadResult.success(DriverOrderContents value)
      : this._(contents: value);

  const DriverOrderContentsLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => contents != null;
}

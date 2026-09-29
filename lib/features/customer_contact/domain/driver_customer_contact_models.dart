enum DriverCustomerContactDataSource { demo, api }

class DriverCustomerCallResult {
  final bool placed;
  final String message;

  const DriverCustomerCallResult({
    required this.placed,
    required this.message,
  });
}

import '../../location/domain/driver_location_models.dart';

enum DriverBranchRouteDataSource { demo, api }

class DriverBranchRouteInfo {
  final int? apiOrderId;
  final String orderNumber;
  final String branchName;
  final String branchImageAsset;
  final String branchAddress;
  final String branchPhoneLabel;
  final DriverCoordinates branchCoordinates;
  final DriverCoordinates driverCoordinates;
  final int etaMinutes;
  final double distanceKm;
  final List<String> pickupInstructions;
  final DateTime updatedAt;

  const DriverBranchRouteInfo({
    this.apiOrderId,
    required this.orderNumber,
    required this.branchName,
    required this.branchImageAsset,
    required this.branchAddress,
    required this.branchPhoneLabel,
    required this.branchCoordinates,
    required this.driverCoordinates,
    required this.etaMinutes,
    required this.distanceKm,
    required this.pickupInstructions,
    required this.updatedAt,
  });
}

class DriverBranchRouteLoadResult {
  final DriverBranchRouteInfo? route;
  final String? errorMessage;

  const DriverBranchRouteLoadResult._({this.route, this.errorMessage});

  const DriverBranchRouteLoadResult.success(DriverBranchRouteInfo value)
      : this._(route: value);

  const DriverBranchRouteLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => route != null;
}

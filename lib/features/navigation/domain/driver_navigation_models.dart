enum DriverNavigationApp { systemDefault, googleMaps, appleMaps }

enum DriverNavigationPlatform { android, ios, other }

extension DriverNavigationAppPresentation on DriverNavigationApp {
  String get label {
    return switch (this) {
      DriverNavigationApp.systemDefault => 'Preferred navigation app',
      DriverNavigationApp.googleMaps => 'Google Maps',
      DriverNavigationApp.appleMaps => 'Apple Maps',
    };
  }

  String get shortLabel {
    return switch (this) {
      DriverNavigationApp.systemDefault => 'System default',
      DriverNavigationApp.googleMaps => 'Google Maps',
      DriverNavigationApp.appleMaps => 'Apple Maps',
    };
  }
}

class DriverNavigationTarget {
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;

  const DriverNavigationTarget({
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get destinationValue {
    if (hasCoordinates) {
      return '${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}';
    }
    return address;
  }
}

class DriverNavigationLaunchResult {
  final bool launched;
  final String? errorMessage;

  const DriverNavigationLaunchResult.success()
      : launched = true,
        errorMessage = null;

  const DriverNavigationLaunchResult.failure(this.errorMessage)
      : launched = false;
}

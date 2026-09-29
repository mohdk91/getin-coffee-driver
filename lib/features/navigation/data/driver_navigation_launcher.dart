import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../domain/driver_navigation_models.dart';

abstract interface class DriverNavigationLauncher {
  DriverNavigationPlatform get platform;

  Future<DriverNavigationLaunchResult> launch({
    required DriverNavigationApp app,
    required DriverNavigationTarget target,
  });
}

class DriverNavigationUrlBuilder {
  const DriverNavigationUrlBuilder._();

  static Uri googleMapsUniversal(DriverNavigationTarget target) {
    return Uri.https(
      'www.google.com',
      '/maps/dir/',
      <String, String>{
        'api': '1',
        'destination': target.destinationValue,
        'travelmode': 'driving',
      },
    );
  }

  static Uri googleMapsApp(DriverNavigationTarget target) {
    final destination = Uri.encodeQueryComponent(target.destinationValue);
    return Uri.parse(
      'comgooglemaps://?daddr=$destination&directionsmode=driving',
    );
  }

  static Uri appleMaps(DriverNavigationTarget target) {
    final destination = Uri.encodeQueryComponent(target.destinationValue);
    return Uri.parse(
      'https://maps.apple.com/?daddr=$destination&dirflg=d',
    );
  }

  static Uri androidSystem(DriverNavigationTarget target) {
    if (target.hasCoordinates) {
      final latitude = target.latitude!.toStringAsFixed(6);
      final longitude = target.longitude!.toStringAsFixed(6);
      final label = Uri.encodeQueryComponent(target.label);
      return Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude($label)');
    }
    return Uri.parse('geo:0,0?q=${Uri.encodeQueryComponent(target.address)}');
  }
}

class UrlLauncherDriverNavigationLauncher implements DriverNavigationLauncher {
  const UrlLauncherDriverNavigationLauncher();

  @override
  DriverNavigationPlatform get platform {
    if (Platform.isAndroid) return DriverNavigationPlatform.android;
    if (Platform.isIOS) return DriverNavigationPlatform.ios;
    return DriverNavigationPlatform.other;
  }

  @override
  Future<DriverNavigationLaunchResult> launch({
    required DriverNavigationApp app,
    required DriverNavigationTarget target,
  }) async {
    try {
      return switch (app) {
        DriverNavigationApp.googleMaps => _launchGoogleMaps(target),
        DriverNavigationApp.appleMaps => _launchAppleMaps(target),
        DriverNavigationApp.systemDefault => _launchSystemDefault(target),
      };
    } catch (_) {
      return const DriverNavigationLaunchResult.failure(
        'Navigation could not be opened. Check that a maps app is installed and try again.',
      );
    }
  }

  Future<DriverNavigationLaunchResult> _launchGoogleMaps(
    DriverNavigationTarget target,
  ) async {
    if (platform == DriverNavigationPlatform.android ||
        platform == DriverNavigationPlatform.ios) {
      try {
        final openedApp = await launchUrl(
          DriverNavigationUrlBuilder.googleMapsApp(target),
          mode: LaunchMode.externalApplication,
        );
        if (openedApp) return const DriverNavigationLaunchResult.success();
      } catch (_) {
        // Fall back to the Google Maps universal URL below.
      }
    }

    final openedWeb = await launchUrl(
      DriverNavigationUrlBuilder.googleMapsUniversal(target),
      mode: LaunchMode.externalApplication,
    );
    return openedWeb
        ? const DriverNavigationLaunchResult.success()
        : const DriverNavigationLaunchResult.failure(
            'Google Maps could not be opened on this device.',
          );
  }

  Future<DriverNavigationLaunchResult> _launchAppleMaps(
    DriverNavigationTarget target,
  ) async {
    if (platform != DriverNavigationPlatform.ios) {
      return const DriverNavigationLaunchResult.failure(
        'Apple Maps app navigation is available on iPhone and iPad only.',
      );
    }

    final opened = await launchUrl(
      DriverNavigationUrlBuilder.appleMaps(target),
      mode: LaunchMode.externalApplication,
    );
    return opened
        ? const DriverNavigationLaunchResult.success()
        : const DriverNavigationLaunchResult.failure(
            'Apple Maps could not be opened on this device.',
          );
  }

  Future<DriverNavigationLaunchResult> _launchSystemDefault(
    DriverNavigationTarget target,
  ) async {
    final Uri uri;
    if (platform == DriverNavigationPlatform.android) {
      uri = DriverNavigationUrlBuilder.androidSystem(target);
    } else if (platform == DriverNavigationPlatform.ios) {
      uri = DriverNavigationUrlBuilder.appleMaps(target);
    } else {
      uri = DriverNavigationUrlBuilder.googleMapsUniversal(target);
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return const DriverNavigationLaunchResult.success();
    } catch (_) {
      // Try the universal maps URL below when the device has no geo handler.
    }

    final fallback = await launchUrl(
      DriverNavigationUrlBuilder.googleMapsUniversal(target),
      mode: LaunchMode.externalApplication,
    );
    return fallback
        ? const DriverNavigationLaunchResult.success()
        : const DriverNavigationLaunchResult.failure(
            'No navigation application could open this route.',
          );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/navigation/data/driver_navigation_launcher.dart';
import 'package:getin_driver/features/navigation/domain/driver_navigation_models.dart';

void main() {
  const coordinateTarget = DriverNavigationTarget(
    label: 'Stanley',
    address: 'Stanley, Alexandria, Egypt',
    latitude: 31.2397,
    longitude: 29.9489,
  );

  test('Task 16 Google Maps URL carries driving destination', () {
    final uri = DriverNavigationUrlBuilder.googleMapsUniversal(
      coordinateTarget,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '31.239700,29.948900');
    expect(uri.queryParameters['travelmode'], 'driving');
  });

  test('Task 16 Apple Maps URL carries driving destination', () {
    final uri = DriverNavigationUrlBuilder.appleMaps(coordinateTarget);

    expect(uri.host, 'maps.apple.com');
    expect(uri.queryParameters['daddr'], '31.239700,29.948900');
    expect(uri.queryParameters['dirflg'], 'd');
  });

  test('Task 16 Android preferred-app URL uses geo intent', () {
    final uri = DriverNavigationUrlBuilder.androidSystem(coordinateTarget);

    expect(uri.scheme, 'geo');
    expect(uri.toString(), contains('31.239700,29.948900'));
    expect(uri.toString(), contains('Stanley'));
  });

  test('Task 16 area-only target falls back to address text', () {
    const areaTarget = DriverNavigationTarget(
      label: 'San Stefano',
      address: 'San Stefano',
    );

    final uri = DriverNavigationUrlBuilder.googleMapsUniversal(areaTarget);
    expect(uri.queryParameters['destination'], 'San Stefano');
  });
}

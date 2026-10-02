import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../../home/domain/driver_home_models.dart';
import '../domain/driver_location_models.dart';

enum DriverLocationDataSource { demo, api }

class DriverLocationLoadResult {
  final DriverServiceRegionProfile? profile;
  final String? errorMessage;

  const DriverLocationLoadResult._({this.profile, this.errorMessage});

  const DriverLocationLoadResult.success(DriverServiceRegionProfile profile)
      : this._(profile: profile);

  const DriverLocationLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => profile != null;
}

abstract interface class DriverLocationRepository {
  DriverLocationDataSource get source;

  Future<DriverLocationLoadResult> loadLocationProfile();
}

class DriverLocationRepositoryFactory {
  DriverLocationRepositoryFactory._();

  static DriverLocationRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.allowsDemo) {
      return const DemoDriverLocationRepository();
    }
    return ApiDriverLocationRepository(
        context ?? DriverApiContext.create(config));
  }
}

class ApiDriverLocationRepository implements DriverLocationRepository {
  final DriverApiContext context;

  const ApiDriverLocationRepository(this.context);

  @override
  DriverLocationDataSource get source => DriverLocationDataSource.api;

  @override
  Future<DriverLocationLoadResult> loadLocationProfile() async {
    try {
      final locationEnvelope = await context.apiClient.getJson(
        '/v1/driver/location',
        authenticated: true,
      );
      final rawLocation = locationEnvelope['data'];
      if (rawLocation is! Map) {
        return const DriverLocationLoadResult.failure(
          'No live GPS fix has reached Getin yet. Enable location services and send a fresh location update.',
        );
      }
      final location = Map<String, dynamic>.from(rawLocation);

      final assignments = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/assignments',
          authenticated: true,
        ),
      );
      final regions = (assignments['regions'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);
      final branches = (assignments['branches'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);

      final region = regions.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['is_primary'] == true,
            orElse: () => regions.isEmpty ? null : regions.first,
          );
      final branch = branches.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['is_primary'] == true,
            orElse: () => branches.isEmpty ? null : branches.first,
          );

      String vehicleType = '';
      try {
        final vehicles = DriverApiContext.nestedItems(
          await context.apiClient.getJson(
            '/v1/driver/vehicles',
            authenticated: true,
          ),
        );
        final maps = vehicles
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .toList(growable: false);
        if (maps.isNotEmpty) {
          final primary = maps.cast<Map<String, dynamic>?>().firstWhere(
                (item) => item?['is_primary'] == true,
                orElse: () => maps.first,
              );
          vehicleType = primary?['vehicle_type']?.toString() ?? '';
        }
      } on Object {
        // Vehicle summary is supporting context only. GPS itself remains usable.
      }

      final capturedAt = DateTime.tryParse(
            location['timestamp']?.toString() ?? '',
          ) ??
          DateTime.now();

      return DriverLocationLoadResult.success(
        DriverServiceRegionProfile(
          country: region?['country_code']?.toString() ??
              branch?['country_code']?.toString() ??
              '—',
          city:
              region?['city']?.toString() ?? branch?['city']?.toString() ?? '—',
          region: region?['name']?.toString() ?? 'Assigned region',
          zone: region?['name']?.toString() ?? 'Assigned region',
          allowedBranches: branches
              .map((item) => item['name']?.toString() ?? '')
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
          deliveryRadiusKm: (region?['radius_km'] as num?)?.toDouble() ?? 0,
          vehicleType: vehicleType.isEmpty ? 'Backend vehicle' : vehicleType,
          currentGps: DriverGpsFix(
            coordinates: DriverCoordinates(
              latitude: (location['latitude'] as num).toDouble(),
              longitude: (location['longitude'] as num).toDouble(),
            ),
            accuracyMeters: (location['accuracy'] as num).toDouble(),
            capturedAt: capturedAt,
            state: DriverGpsState.ready,
          ),
        ),
      );
    } on ApiException catch (error) {
      return DriverLocationLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverLocationLoadResult.failure(error.message);
    } on TypeError {
      return const DriverLocationLoadResult.failure(
        'Getin returned an incomplete GPS record. Refresh location and try again.',
      );
    }
  }
}

class DemoDriverLocationRepository implements DriverLocationRepository {
  const DemoDriverLocationRepository();

  @override
  DriverLocationDataSource get source => DriverLocationDataSource.demo;

  @override
  Future<DriverLocationLoadResult> loadLocationProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    return DriverLocationLoadResult.success(
      DriverServiceRegionProfile(
        country: 'Egypt',
        city: 'Alexandria',
        region: 'Stanley / San Stefano',
        zone: 'East Alexandria',
        allowedBranches: const ['Stanley', 'Gleem'],
        deliveryRadiusKm: 8,
        vehicleType: 'Motorbike',
        currentGps: DriverGpsFix(
          coordinates: const DriverCoordinates(
            latitude: 31.24580,
            longitude: 29.96680,
          ),
          accuracyMeters: 12,
          capturedAt: DateTime.now(),
          state: DriverGpsState.ready,
        ),
      ),
    );
  }
}

class UnavailableDriverLocationRepository implements DriverLocationRepository {
  const UnavailableDriverLocationRepository();

  @override
  DriverLocationDataSource get source => DriverLocationDataSource.api;

  @override
  Future<DriverLocationLoadResult> loadLocationProfile() async {
    return const DriverLocationLoadResult.failure(
      'Driver location and service-region API are not connected yet. No demo GPS is shown outside development.',
    );
  }
}

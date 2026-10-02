import '../../../core/config/app_config.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_profile_models.dart';

abstract interface class DriverProfileRepository {
  DriverProfileDataSource get source;
  Future<DriverProfileLoadResult> loadProfile();
}

class DriverProfileRepositoryFactory {
  DriverProfileRepositoryFactory._();

  static DriverProfileRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverProfileRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.allowsDemo
        ? const DemoDriverProfileRepository()
        : const UnavailableDriverProfileRepository();
  }
}

class ApiDriverProfileRepository implements DriverProfileRepository {
  final DriverApiContext context;

  const ApiDriverProfileRepository(this.context);

  @override
  DriverProfileDataSource get source => DriverProfileDataSource.api;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    try {
      final envelope = await context.apiClient.getJson(
        '/v1/driver/profile',
        authenticated: true,
      );
      final data = DriverApiContext.dataMap(envelope);
      return DriverProfileLoadResult.success(_map(data));
    } on ApiException catch (error) {
      return DriverProfileLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverProfileLoadResult.failure(error.message);
    }
  }

  DriverProfileSnapshot _map(Map<String, dynamic> data) {
    final regions = _names(data['assigned_regions']);
    final branches = _names(data['assigned_branches']);
    final approval = data['approval_status']?.toString().toLowerCase();
    final note = data['verification_notes']?.toString().trim() ?? '';

    return DriverProfileSnapshot(
      fullName: data['name']?.toString() ?? 'Driver',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      driverId: data['id']?.toString() ?? '',
      verificationStatus: _verificationStatus(approval, note),
      assignedRegion: regions.isEmpty ? 'Not assigned' : regions.join(', '),
      assignedBranches: List<String>.unmodifiable(branches),
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  List<String> _names(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .whereType<Map>()
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  DriverProfileVerificationStatus _verificationStatus(
    String? approval,
    String note,
  ) {
    return switch (approval) {
      'approved' => DriverProfileVerificationStatus.approved,
      'rejected' => DriverProfileVerificationStatus.rejected,
      'suspended' => DriverProfileVerificationStatus.suspended,
      'under_review' when note.isNotEmpty =>
        DriverProfileVerificationStatus.additionalInformationRequired,
      _ => DriverProfileVerificationStatus.pending,
    };
  }
}

class DemoDriverProfileRepository implements DriverProfileRepository {
  const DemoDriverProfileRepository();

  @override
  DriverProfileDataSource get source => DriverProfileDataSource.demo;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    return DriverProfileLoadResult.success(
      DriverProfileSnapshot(
        fullName: 'Demo Driver',
        phone: '+20 100 000 0000',
        email: 'driver@getin.local',
        driverId: 'DRV-DEMO-001',
        verificationStatus: DriverProfileVerificationStatus.approved,
        assignedRegion: 'East Alexandria',
        assignedBranches: const ['Stanley', 'San Stefano'],
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class UnavailableDriverProfileRepository implements DriverProfileRepository {
  const UnavailableDriverProfileRepository();

  @override
  DriverProfileDataSource get source => DriverProfileDataSource.api;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    return const DriverProfileLoadResult.failure(
      'Driver profile data is not connected to the Laravel API yet. Getin will not invent production identity, contact or assignment details.',
    );
  }
}

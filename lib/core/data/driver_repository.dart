enum DriverDataSource { demo, api }

class DriverFoundationSnapshot {
  final String driverName;
  final bool online;
  final int completedToday;
  final double earningsToday;
  final double rating;

  const DriverFoundationSnapshot({
    required this.driverName,
    required this.online,
    required this.completedToday,
    required this.earningsToday,
    required this.rating,
  });
}

abstract class DriverRepository {
  DriverDataSource get source;
  Future<DriverFoundationSnapshot> loadFoundationSnapshot();
}

/// Local data is explicitly demo-only until the Laravel API is connected.
class DemoDriverRepository implements DriverRepository {
  const DemoDriverRepository();

  @override
  DriverDataSource get source => DriverDataSource.demo;

  @override
  Future<DriverFoundationSnapshot> loadFoundationSnapshot() async {
    return const DriverFoundationSnapshot(
      driverName: 'Demo Driver',
      online: false,
      completedToday: 0,
      earningsToday: 0,
      rating: 0,
    );
  }
}

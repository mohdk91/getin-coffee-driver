enum AppEnvironment {
  development('dev', 'Development'),
  staging('staging', 'Staging'),
  production('prod', 'Production');

  final String key;
  final String label;

  const AppEnvironment(this.key, this.label);

  static AppEnvironment parse(String value) {
    final normalized = value.trim().toLowerCase();
    return AppEnvironment.values.firstWhere(
      (environment) => environment.key == normalized,
      orElse: () => AppEnvironment.development,
    );
  }
}

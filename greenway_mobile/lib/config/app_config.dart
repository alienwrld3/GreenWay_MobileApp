class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'GREENWAY_API_BASE_URL',
    defaultValue: 'http://192.168.65.192:3000',
  );

  static Uri apiUri(String path) => Uri.parse('$backendBaseUrl$path');
}

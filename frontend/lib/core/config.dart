enum Environment { dev, prod }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
  });

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  static void init({
    required Environment environment,
    required String apiBaseUrl,
  }) {
    _instance = AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
    );
  }
}

import 'dart:io' show Platform;

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static const int timeout = 20000;
  static const String appName = 'Transport Ease';
}

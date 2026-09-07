import 'dart:io' show Platform;

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    return 'http://127.0.0.1:8000/api';
  }

  static const int timeout = 20000;
  static const String appName = 'Transport Ease';
}

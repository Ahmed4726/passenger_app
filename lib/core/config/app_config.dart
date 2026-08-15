import 'dart:io' show Platform;

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    return 'http://api.booksdada.com/api';
  }

  static const int timeout = 20000;
  static const String appName = 'Transport Ease';
}

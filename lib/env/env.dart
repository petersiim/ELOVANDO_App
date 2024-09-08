import 'dart:io';

class Env {
  static String get apiKey => Platform.environment['API_KEY'] ?? '';
}

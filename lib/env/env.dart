import 'dart:io';

class Env {
  static String get apiKey => Platform.environment['OPEN_AI_API_KEY'] ?? '';
}
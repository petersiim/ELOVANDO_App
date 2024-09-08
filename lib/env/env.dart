import 'package:envied/envied.dart';
import 'dart:io';

part 'env.g.dart';

// Uncomment the following lines for local testing
// @Envied(path: '.env')
// abstract class Env {
//   @EnviedField(varName: 'API_KEY')
//   static const String apiKey = _Env.apiKey;
// }

// Use this for production builds
class Env {
  static String get apiKey => Platform.environment['API_KEY'] ?? '';
}
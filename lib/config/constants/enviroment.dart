import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> initEnvironment() async {
    await dotenv.load(fileName: '.env');
  }

  static String apiUrl =
      dotenv.env['API_URL'] ?? 'No está configurado el API_URL';
  static String maptilerKey =
      dotenv.env['MAPTILER_KEY'] ?? 'No está configurado el MAPTILER_KEY';
}

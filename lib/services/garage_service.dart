import 'package:http/http.dart' as http;

class GarageService {
  static Future<bool> pressButton() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1/press"))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkOnline() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1"))
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
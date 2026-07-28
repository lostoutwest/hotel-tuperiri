import 'package:http/http.dart' as http;

class GarageService {
  static const _baseUrl = "http://192.168.4.1";
  static const _commandToken = "ChangeThisToken";

  static Future<bool> pressButton() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/press?token=$_commandToken"))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkOnline() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

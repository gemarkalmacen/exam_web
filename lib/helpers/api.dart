import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static const String baseUrl = "http://localhost:8000/api";

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return jsonDecode(response.body);
  }
}

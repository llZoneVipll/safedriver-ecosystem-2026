import 'dart:convert';
import 'package:flutter/foundation.dart'; // Necesario para kIsWeb
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Ajuste automático de IP: Localhost para Web, 10.0.2.2 para Emulador Android
  final String baseUrl =
      kIsWeb ? "http://localhost:8000" : "http://10.0.2.2:8000";

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'username=$username&password=$password',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['access_token'];
        final String role = data['role'] ?? 'usuario';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_role', role);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
  }
}

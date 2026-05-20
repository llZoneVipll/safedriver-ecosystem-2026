import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conductor.dart';
import '../models/alerta.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = "http://localhost:8000";

  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Conductores ──────────────────────────────────────────
  Future<List<Conductor>> fetchConductores() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/conductores/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List json = jsonDecode(response.body);
        return json.map((d) => Conductor.fromJson(d)).toList();
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      throw Exception('No se pudo conectar con SafeDriver Backend');
    }
  }

  Future<bool> crearConductor(String nombre, String licencia) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/conductores/'),
      headers: headers,
      body: jsonEncode({'nombre': nombre, 'licencia': licencia}),
    );
    return response.statusCode == 201;
  }

  // ── Alertas ──────────────────────────────────────────────
  Future<List<Alerta>> fetchAlertas() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$baseUrl/alertas/'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List json = jsonDecode(response.body);
        return json.map((d) => Alerta.fromJson(d)).toList();
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      throw Exception('No se pudo obtener alertas');
    }
  }
}
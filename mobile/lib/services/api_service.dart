import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/conductor.dart';
import '../models/alerta.dart';
import '../models/vehiculo.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl =
      kIsWeb ? "http://localhost:8000" : "http://10.0.2.2:8000";

  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final h = await _headers();
      final r = await http
          .get(Uri.parse('$baseUrl/stats'), headers: h)
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
      throw Exception('Error ${r.statusCode}');
    } catch (e) {
      throw Exception('No se pudo conectar con SafeDriver');
    }
  }

  Future<List<Conductor>> fetchConductores() async {
    try {
      final h = await _headers();
      final r = await http
          .get(Uri.parse('$baseUrl/conductores/'), headers: h)
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        List json = jsonDecode(r.body);
        return json.map((d) => Conductor.fromJson(d)).toList();
      }
      throw Exception('Error ${r.statusCode}');
    } catch (e) {
      throw Exception('No se pudo conectar con SafeDriver');
    }
  }

  // ── NUEVO: Petición para Vehículos ────────────────────────
  Future<List<Vehiculo>> fetchVehiculos() async {
    try {
      final h = await _headers();
      final r = await http
          .get(Uri.parse('$baseUrl/vehiculos/'), headers: h)
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        List json = jsonDecode(r.body);
        return json.map((d) => Vehiculo.fromJson(d)).toList();
      }
      return []; // Devuelve vacío si no hay
    } catch (_) {
      return [];
    }
  }

  Future<bool> crearConductor(String nombre, String licencia) async {
    try {
      final h = await _headers();
      final r = await http.post(
        Uri.parse('$baseUrl/conductores/'),
        headers: h,
        body: jsonEncode({'nombre': nombre, 'licencia': licencia}),
      );
      return r.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> eliminarConductor(int id) async {
    try {
      final h = await _headers();
      final r =
          await http.delete(Uri.parse('$baseUrl/conductores/$id'), headers: h);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Alerta>> fetchAlertas() async {
    try {
      final h = await _headers();
      final r = await http
          .get(Uri.parse('$baseUrl/alertas/'), headers: h)
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        List json = jsonDecode(r.body);
        return json.map((d) => Alerta.fromJson(d)).toList();
      }
      throw Exception('Error ${r.statusCode}');
    } catch (e) {
      throw Exception('No se pudo obtener las alertas');
    }
  }
}

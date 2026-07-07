import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/alerta.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Alerta> _criticas = [];
  List<Alerta> _recientes = [];
  bool _loading = true;
  String? _error;
  String _userRole = 'usuario';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = await AuthService().getRole();
      final stats = await ApiService().fetchStats();
      final alertas = await ApiService().fetchAlertas();

      if (mounted) {
        setState(() {
          _userRole = role ?? 'usuario';
          _stats = stats;

          _criticas =
              alertas.where((a) => a.nivel == 'CRITICO').take(3).toList();
          _recientes =
              alertas.where((a) => a.nivel != 'CRITICO').take(5).toList();

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Color _colorNivel(String n) => n == 'CRITICO'
      ? Colors.red
      : n == 'ALERTA'
          ? Colors.orange
          : Colors.green;

  // ── SOLUCIÓN: Formateador dinámico para evitar los null ──
  String _formatMetrics(Alerta a) {
    List<String> parts = [];
    if (a.valorBpm != null) parts.add('BPM: ${a.valorBpm}');
    if (a.valorVelocidad != null) parts.add('${a.valorVelocidad} km/h');
    return parts.isNotEmpty
        ? parts.join('  ·  ')
        : 'Datos de telemetría no disponibles';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE64A19),
        title: const Row(children: [
          Icon(Icons.local_shipping, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text('SafeDriver',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargar),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE64A19)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: const Color(0xFFE64A19),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 20),
                      _buildStatsGrid(),
                      if (_criticas.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildCriticas(),
                      ],
                      const SizedBox(height: 24),
                      _buildRecientes(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  _userRole == 'gestor'
                      ? 'Central de Control'
                      : 'Panel de Conductor',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(
                  _userRole == 'gestor'
                      ? 'Monitoreo global en tiempo real'
                      : 'Resumen de tus métricas de manejo',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ]),
      );

  Widget _buildStatsGrid() {
    if (_stats == null) return const SizedBox();

    bool enRiesgo = _stats!['alertas_criticas'] > 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_userRole == 'gestor' ? 'Resumen del Sistema' : 'Tus Estadísticas',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _statCard(
              _userRole == 'gestor' ? 'Conductores' : 'Mi Estado',
              _userRole == 'gestor'
                  ? '${_stats!['total_conductores']}'
                  : (enRiesgo ? 'En Riesgo' : 'Óptimo'),
              _userRole == 'gestor' ? Icons.people : Icons.health_and_safety,
              _userRole == 'gestor'
                  ? Colors.blue
                  : (enRiesgo ? Colors.red : Colors.green)),
          _statCard(
              _userRole == 'gestor' ? 'Total Alertas' : 'Mis Alertas',
              '${_stats!['total_alertas']}',
              Icons.notifications,
              const Color(0xFFE64A19)),
          _statCard(_userRole == 'gestor' ? 'Críticas' : 'Mis Críticas',
              '${_stats!['alertas_criticas']}', Icons.warning, Colors.red),
          _statCard(
              _userRole == 'gestor' ? 'En Alerta' : 'Mis Avisos',
              '${_stats!['alertas_en_alerta']}',
              Icons.warning_amber,
              Colors.orange),
        ],
      ),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value,
                    style: TextStyle(
                        fontSize: value.length > 5 ? 18 : 26,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ],
          ),
        ),
      );

  Widget _buildCriticas() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Atención Urgente',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          ..._criticas.map((a) {
            return Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200, width: 1),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  child: const Icon(Icons.warning, color: Colors.red, size: 20),
                ),
                title: Text('${a.tipo} — Conductor #${a.conductorId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: Text(
                    '${_formatMetrics(a)}\nFecha: ${a.timestamp.substring(0, 16)}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                isThreeLine: true,
              ),
            );
          }),
        ],
      );

  Widget _buildRecientes() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _userRole == 'gestor'
                  ? 'Historial de Alertas'
                  : 'Tus últimos Avisos',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_recientes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.check_circle_outline,
                        size: 40, color: Colors.green[300]),
                    const SizedBox(height: 8),
                    const Text('No hay alertas menores',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                ),
              ),
            )
          else
            ..._recientes.map((a) {
              final color = _colorNivel(a.nivel);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: color, width: 4)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(
                          a.tipo == 'FATIGA' ? Icons.bedtime : Icons.speed,
                          color: color,
                          size: 18),
                    ),
                    title: Text('${a.tipo} — Conductor #${a.conductorId}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: color)),
                    subtitle: Text(_formatMetrics(a)),
                    trailing: Chip(
                      label: Text(a.nivel,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: color.withOpacity(0.1),
                      side: BorderSide(color: color),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              );
            }),
        ],
      );

  Widget _buildError() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Sin conexión con el servidor',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64A19),
                foregroundColor: Colors.white),
          ),
        ]),
      );
}

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
  List<Alerta> _recientes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats   = await ApiService().fetchStats();
      final alertas = await ApiService().fetchAlertas();
      setState(() {
        _stats    = stats;
        _recientes = alertas.take(5).toList();
        _loading  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _colorNivel(String n) =>
      n == 'CRITICO' ? Colors.red : n == 'ALERTA' ? Colors.orange : Colors.green;

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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargar),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE64A19)))
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
    child: const Row(children: [
      Icon(Icons.shield_outlined, color: Colors.white, size: 40),
      SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Central de Control',
              style: TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Monitoreo en tiempo real de conductores',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    ]),
  );

  Widget _buildStatsGrid() {
    if (_stats == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Resumen del Sistema',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _statCard('Conductores', '${_stats!['total_conductores']}',
              Icons.people, Colors.blue),
          _statCard('Total Alertas', '${_stats!['total_alertas']}',
              Icons.notifications, const Color(0xFFE64A19)),
          _statCard('Críticas', '${_stats!['alertas_criticas']}',
              Icons.warning, Colors.red),
          _statCard('En Alerta', '${_stats!['alertas_en_alerta']}',
              Icons.warning_amber, Colors.orange),
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
                    style: TextStyle(fontSize: 26,
                        fontWeight: FontWeight.bold, color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ],
          ),
        ),
      );

  Widget _buildRecientes() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Últimas 5 Alertas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (_recientes.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(children: [
                Icon(Icons.check_circle_outline, size: 40, color: Colors.green[300]),
                const SizedBox(height: 8),
                const Text('Sin alertas registradas',
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
                    color: color, size: 18),
                ),
                title: Text('${a.tipo} — Conductor #${a.conductorId}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                subtitle: Text('BPM: ${a.valorBpm ?? "N/A"} · ${a.valorVelocidad != null ? "${a.valorVelocidad} km/h" : ""}'),
                trailing: Chip(
                  label: Text(a.nivel,
                      style: TextStyle(color: color, fontSize: 11,
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
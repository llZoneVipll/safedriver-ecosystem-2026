import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../models/alerta.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Conductor>> futureConductores;
  late Future<List<Alerta>> futureAlertas;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  void _refrescar() {
    setState(() {
      futureConductores = ApiService().fetchConductores();
      futureAlertas = ApiService().fetchAlertas();
    });
  }

  Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'CRITICO':
        return Colors.red;
      case 'ALERTA':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeDriver — Central de Control'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refrescar(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Sección Conductores ──────────────────────
            const Text('🚗 Conductores Registrados',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Conductor>>(
              future: futureConductores,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text('${snapshot.error}'),
                    ),
                  );
                } else if (snapshot.data!.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No hay conductores registrados'),
                    ),
                  );
                }
                return Column(
                  children: snapshot.data!.map((c) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.deepOrange,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(c.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text('Licencia: ${c.licencia}'),
                      trailing: Text('#${c.id}',
                          style:
                              const TextStyle(color: Colors.grey)),
                    ),
                  )).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Sección Alertas ──────────────────────────
            const Text('🚨 Alertas Recientes',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Alerta>>(
              future: futureAlertas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text('${snapshot.error}'),
                    ),
                  );
                } else if (snapshot.data!.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No hay alertas registradas'),
                    ),
                  );
                }
                return Column(
                  children: snapshot.data!.map((a) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _colorNivel(a.nivel),
                        child: const Icon(Icons.warning,
                            color: Colors.white),
                      ),
                      title: Text('${a.tipo} — ${a.nivel}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _colorNivel(a.nivel))),
                      subtitle: Text(
                          'Conductor #${a.conductorId} · BPM: ${a.valorBpm ?? "N/A"}'),
                      trailing: Text(
                          a.timestamp.length > 10
                              ? a.timestamp.substring(0, 10)
                              : a.timestamp,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
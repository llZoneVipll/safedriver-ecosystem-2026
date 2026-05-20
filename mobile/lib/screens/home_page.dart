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
                  children: snapshot.data!.map((c) => Dismissible(
                    // La Key es obligatoria y debe ser única para cada elemento
                    key: Key(c.id.toString()),
                    // Solo permitimos deslizar de derecha a izquierda
                    direction: DismissDirection.endToStart,
                    // El fondo rojo con el tacho de basura que aparece al deslizar
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    // Lo que sucede cuando el usuario termina de deslizar
                    onDismissed: (direction) async {
                      bool ok = await ApiService().eliminarConductor(c.id);
                      
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${c.nombre} eliminado del sistema")),
                        );
                        _refrescar(); // Actualizamos la lista con el backend
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error de permisos o servidor caído")),
                        );
                        _refrescar(); // Recargamos para que el conductor vuelva a aparecer si falló
                      }
                    },
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(c.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('Licencia: ${c.licencia}'),
                        // --- AQUÍ EMPIEZA EL CAMBIO PARA EL MODAL DE EDICIÓN ---
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () {
                            TextEditingController nombreCtrl = TextEditingController(text: c.nombre);
                            TextEditingController licenciaCtrl = TextEditingController(text: c.licencia);

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Editar Conductor"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nombreCtrl, 
                                      decoration: const InputDecoration(labelText: "Nombre")
                                    ),
                                    TextField(
                                      controller: licenciaCtrl, 
                                      decoration: const InputDecoration(labelText: "Licencia")
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context), 
                                    child: const Text("Cancelar")
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      bool ok = await ApiService().editarConductor(
                                        c.id, 
                                        nombreCtrl.text, 
                                        licenciaCtrl.text
                                      );
                                      if (ok) {
                                        if (context.mounted) {
                                          Navigator.pop(context); // Cierra el modal
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Conductor actualizado")),
                                          );
                                        }
                                        _refrescar(); // Actualiza la lista automáticamente
                                      }
                                    },
                                    child: const Text("Guardar"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // --- AQUÍ TERMINA EL CAMBIO ---
                      ),
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
      // ── NUEVO COMPONENTE: BOTÓN FLOTANTE PARA CREAR CONDUCTOR ──
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        tooltip: 'Registrar Conductor',
        onPressed: () {
          TextEditingController nuevoNombreCtrl = TextEditingController();
          TextEditingController nuevaLicenciaCtrl = TextEditingController();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Registrar Nuevo Conductor"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nuevoNombreCtrl,
                    decoration: const InputDecoration(labelText: "Nombre Completo"),
                  ),
                  TextField(
                    controller: nuevaLicenciaCtrl,
                    decoration: const InputDecoration(labelText: "Número de Licencia"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nuevoNombreCtrl.text.isNotEmpty && nuevaLicenciaCtrl.text.isNotEmpty) {
                      bool ok = await ApiService().crearConductor(
                        nuevoNombreCtrl.text,
                        nuevaLicenciaCtrl.text,
                      );
                      if (ok) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Conductor registrado con éxito")),
                          );
                        }
                        _refrescar(); 
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error: No autorizado o servidor caído")),
                          );
                        }
                      }
                    }
                  },
                  child: const Text("Registrar"),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
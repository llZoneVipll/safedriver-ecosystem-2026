import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../models/vehiculo.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'add_conductor_screen.dart';

class ConductoresScreen extends StatefulWidget {
  const ConductoresScreen({super.key});
  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  late Future<List<Conductor>> _futureConductores;
  late Future<List<Vehiculo>> _futureVehiculos;
  String _userRole = 'usuario';

  @override
  void initState() {
    super.initState();
    // Cargamos ambas fuentes de datos al entrar a la pantalla
    _futureConductores = ApiService().fetchConductores();
    _futureVehiculos = ApiService().fetchVehiculos();
    _cargarRol();
  }

  void _cargarRol() async {
    final role = await AuthService().getRole();
    if (mounted) {
      setState(() {
        _userRole = role ?? 'usuario';
      });
    }
  }

  void _refrescar() {
    setState(() {
      _futureConductores = ApiService().fetchConductores();
      _futureVehiculos = ApiService().fetchVehiculos();
    });
  }

  Future<void> _eliminar(Conductor c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conductor'),
        content: Text('¿Confirmas eliminar a ${c.nombre}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      final success = await ApiService().eliminarConductor(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '${c.nombre} eliminado'
              : 'Error al eliminar (Verifica permisos)'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
      if (success) _refrescar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE64A19),
        // Título dinámico
        title: Text(_userRole == 'gestor' ? 'Conductores' : 'Mi Información',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refrescar),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refrescar(),
        color: const Color(0xFFE64A19),
        child: FutureBuilder<List<Conductor>>(
          future: _futureConductores,
          builder: (ctx, snapConductor) {
            if (snapConductor.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE64A19)));
            }
            if (snapConductor.hasError) {
              return const Center(child: Text('Sin conexión con el servidor'));
            }

            // ── VISTA DE ADMINISTRADOR (La lista original) ──
            if (_userRole == 'gestor') {
              if (snapConductor.data == null || snapConductor.data!.isEmpty) {
                return const Center(
                    child: Text('No hay conductores registrados',
                        style: TextStyle(color: Colors.grey)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapConductor.data!.length,
                itemBuilder: (_, i) {
                  final c = snapConductor.data![i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE64A19),
                        child: Text(
                          c.nombre.isNotEmpty
                              ? c.nombre.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(c.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(children: [
                        const Icon(Icons.credit_card,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(c.licencia,
                            style: const TextStyle(color: Colors.grey)),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('#${c.id}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _eliminar(c),
                        ),
                      ]),
                    ),
                  );
                },
              );
            }
            // ── VISTA DE CONDUCTOR (Su perfil personal) ──
            else {
              if (snapConductor.data == null || snapConductor.data!.isEmpty) {
                return const Center(child: Text('Error al cargar perfil'));
              }
              final conductorActual = snapConductor.data!.first;

              // Anidamos un FutureBuilder para mostrar también el camión
              return FutureBuilder<List<Vehiculo>>(
                  future: _futureVehiculos,
                  builder: (ctx, snapVehiculo) {
                    if (snapVehiculo.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE64A19)));
                    }
                    final vehiculos = snapVehiculo.data ?? [];
                    return _buildPerfilPersonal(conductorActual, vehiculos);
                  });
            }
          },
        ),
      ),
      // Solo el gestor puede agregar nuevos
      floatingActionButton: _userRole == 'gestor'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddConductorScreen()),
                );
                if (result == true) _refrescar();
              },
              backgroundColor: const Color(0xFFE64A19),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Nuevo Conductor',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  // ── DISEÑO DE LA PANTALLA DE PERFIL (UX) ──
  Widget _buildPerfilPersonal(Conductor conductor, List<Vehiculo> vehiculos) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Avatar grande
        Center(
          child: CircleAvatar(
            radius: 56,
            backgroundColor: const Color(0xFFE64A19).withOpacity(0.1),
            child: const Icon(Icons.person, size: 64, color: Color(0xFFE64A19)),
          ),
        ),
        const SizedBox(height: 20),

        // Datos limpios sin ID técnico
        Text(conductor.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('Licencia: ${conductor.licencia}',
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Chip(
            label: const Text('Estado: Activo',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.withOpacity(0.1),
            side: BorderSide.none,
          ),
        ),

        const SizedBox(height: 40),
        const Text('Vehículo Asignado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Información del Camión
        if (vehiculos.isEmpty)
          Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: Text(
                          'No tienes un vehículo asignado en el sistema.',
                          style: TextStyle(color: Colors.grey)))))
        else
          ...vehiculos.map((v) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.directions_car, color: Colors.blue),
                  ),
                  title: Text(v.modelo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Placa: ${v.placa}'),
                ),
              )),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../services/api_service.dart';
import 'add_conductor_screen.dart';

class ConductoresScreen extends StatefulWidget {
  const ConductoresScreen({super.key});
  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  late Future<List<Conductor>> _future;

  @override
  void initState() { super.initState(); _refrescar(); }

  void _refrescar() =>
      setState(() => _future = ApiService().fetchConductores());

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? '${c.nombre} eliminado' : 'Error al eliminar'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) _refrescar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE64A19),
        title: const Text('Conductores',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE64A19)));
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Sin conexión con el servidor',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _refrescar,
                          child: const Text('Reintentar')),
                    ]),
              );
            }
            if (snap.data!.isEmpty) {
              return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay conductores registrados',
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Usa el botón + para agregar uno',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snap.data!.length,
              itemBuilder: (_, i) {
                final c = snap.data![i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE64A19),
                      child: Text(
                        c.nombre.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(c.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(children: [
                      const Icon(Icons.credit_card, size: 14, color: Colors.grey),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#${c.id}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _eliminar(c),
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
}
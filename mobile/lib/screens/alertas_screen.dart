import 'package:flutter/material.dart';
import '../models/alerta.dart';
import '../services/api_service.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});
  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  late Future<List<Alerta>> _future;
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  void _refrescar() {
    setState(() {
      _future = ApiService().fetchAlertas();
    });
  }

  Color _color(String n) => n == 'CRITICO'
      ? Colors.red
      : n == 'ALERTA'
          ? Colors.orange
          : Colors.green;

  IconData _icon(String t) => t == 'FATIGA'
      ? Icons.bedtime
      : t == 'VELOCIDAD'
          ? Icons.speed
          : Icons.check_circle;

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
        title: const Text('Alertas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refrescar),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['TODOS', 'CRITICO', 'ALERTA', 'NORMAL'].map((f) {
                final color = f == 'CRITICO'
                    ? Colors.red
                    : f == 'ALERTA'
                        ? Colors.orange
                        : f == 'NORMAL'
                            ? Colors.green
                            : const Color(0xFFE64A19);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f,
                        style: TextStyle(
                            color: _filtro == f ? color : Colors.grey,
                            fontWeight: _filtro == f
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    selected: _filtro == f,
                    selectedColor: color.withOpacity(0.1),
                    checkmarkColor: color,
                    side: BorderSide(
                        color: _filtro == f ? color : Colors.grey[300]!),
                    onSelected: (_) => setState(() => _filtro = f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refrescar(),
            color: const Color(0xFFE64A19),
            child: FutureBuilder<List<Alerta>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE64A19)));
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Sin conexión',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _refrescar,
                              child: const Text('Reintentar')),
                        ]),
                  );
                }
                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          const Text('Sin alertas en esta categoría',
                              style: TextStyle(color: Colors.grey)),
                        ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final a = lista[i];
                    final color = _color(a.nivel);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border(left: BorderSide(color: color, width: 5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child:
                                  Icon(_icon(a.tipo), color: color, size: 22),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                    Row(children: [
                                      Text(a.tipo,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(color: color),
                                        ),
                                        child: Text(a.nivel,
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Conductor #${a.conductorId}  ·  ${_formatMetrics(a)}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    if (a.timestamp.length > 10)
                                      Text(
                                        a.timestamp.substring(0, 19),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 11),
                                      ),
                                  ]),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

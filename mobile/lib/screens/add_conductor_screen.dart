import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddConductorScreen extends StatefulWidget {
  const AddConductorScreen({super.key});
  @override
  State<AddConductorScreen> createState() => _AddConductorScreenState();
}

class _AddConductorScreenState extends State<AddConductorScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _licCtrl    = TextEditingController();
  bool _loading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await ApiService().crearConductor(
        _nombreCtrl.text.trim(), _licCtrl.text.trim());
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conductor registrado'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Licencia ya registrada o sin conexión'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE64A19),
        title: const Text('Nuevo Conductor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE64A19).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add,
                            size: 48, color: Color(0xFFE64A19)),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text('Registrar Conductor',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _licCtrl,
                        decoration: InputDecoration(
                          labelText: 'Número de licencia',
                          prefixIcon: const Icon(Icons.credit_card),
                          hintText: 'Ej: LC-004',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 50,
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFE64A19)))
                            : ElevatedButton.icon(
                                onPressed: _guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE64A19),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar Conductor',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
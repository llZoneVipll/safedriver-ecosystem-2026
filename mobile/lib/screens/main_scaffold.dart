import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'conductores_screen.dart';
import 'alertas_screen.dart';
import '../services/auth_service.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  String _userRole = 'usuario';

  @override
  void initState() {
    super.initState();
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

  final List<Widget> _screens = const [
    DashboardScreen(),
    ConductoresScreen(),
    AlertasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: const Color(0xFFE64A19).withOpacity(0.15),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFE64A19)),
            label: 'Dashboard',
          ),
          // ── CAMBIO DINÁMICO DE ICONO Y TEXTO ──
          NavigationDestination(
            icon: Icon(_userRole == 'gestor'
                ? Icons.people_outline
                : Icons.person_outline),
            selectedIcon: Icon(
                _userRole == 'gestor' ? Icons.people : Icons.person,
                color: const Color(0xFFE64A19)),
            label: _userRole == 'gestor' ? 'Conductores' : 'Mi Perfil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber, color: Color(0xFFE64A19)),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

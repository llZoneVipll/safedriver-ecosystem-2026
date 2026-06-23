import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/auth_service.dart';

void main() => runApp(const SafeDriverApp());

class SafeDriverApp extends StatelessWidget {
  const SafeDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeDriver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE64A19),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Color(0xFFE64A19)),
                    SizedBox(height: 16),
                    Text('Iniciando SafeDriver...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScaffold();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
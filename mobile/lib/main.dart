import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
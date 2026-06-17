// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/mqtt_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) {
          final svc = MqttService();
          svc.connect(); // fire and forget — falls back to simulation on error
          return svc;
        }),
      ],
      child: const NeuroBandApp(),
    ),
  );
}

class NeuroBandApp extends StatelessWidget {
  const NeuroBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroBand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          secondary: const Color(0xFF00C6AE),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const _RootRouter(),
    );
  }
}

/// Switches between Login and Dashboard based on auth state.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return auth.isLoggedIn
        ? const DashboardScreen()
        : const LoginScreen();
  }
}

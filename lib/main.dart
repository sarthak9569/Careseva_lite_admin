import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'services/admin_store.dart';
import 'theme/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global exception handlers for production resilience
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[CareSeva Admin Error] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[CareSeva Admin Platform Error] $error\n$stack');
    return true;
  };

  // Custom UI Error Widget fallback
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const CareSevaAdminApp());
}

class CareSevaAdminApp extends StatelessWidget {
  const CareSevaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminStore(),
      child: Consumer<AdminStore>(
        builder: (context, adminStore, child) {
          return MaterialApp(
            title: 'CareSeva SuperAdmin Command Center',
            debugShowCheckedModeBanner: false,
            theme: AdminTheme.darkTheme,
            home: adminStore.isLoggedIn ? const AdminDashboardScreen() : const AdminLoginScreen(),
          );
        },
      ),
    );
  }
}

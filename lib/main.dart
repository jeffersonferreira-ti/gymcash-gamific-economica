// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega preferência de tema antes de exibir qualquer tela
  final themeService = ThemeService();
  await themeService.load();

  runApp(
    ChangeNotifierProvider<ThemeService>.value(
      value: themeService,
      child: const GymCashApp(),
    ),
  );
}

class GymCashApp extends StatelessWidget {
  const GymCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'GymCash',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.mode,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      // Rota raiz — usada pelo reset completo em SettingsScreen
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
  }
}

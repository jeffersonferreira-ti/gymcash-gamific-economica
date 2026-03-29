// lib/screens/splash_screen.dart
//
// Splash screen animada exibida na abertura do app.
// Sequência: fade-in do logo → slide-up da tagline → transição para o app.
// Dura ~2s no total. Não bloqueia o carregamento real dos dados.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controladores de animação ─────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double>  _logoScale;
  late final Animation<double>  _logoFade;
  late final Animation<Offset>  _taglineSlide;
  late final Animation<double>  _taglineFade;
  late final Animation<double>  _exitFade;

  UserModel? _savedUser;

  @override
  void initState() {
    super.initState();

    // Logo: escala + fade-in em 600ms
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(
        parent: _logoCtrl, curve: Curves.easeOut);

    // Tagline: slide-up + fade-in em 500ms, começa após 400ms
    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _taglineSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _taglineCtrl, curve: Curves.easeOutCubic));
    _taglineFade = CurvedAnimation(
        parent: _taglineCtrl, curve: Curves.easeOut);

    // Saída: fade-out em 350ms
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Carrega dados em paralelo com a animação
    _savedUser = await LocalStorageService().getUser();

    // Animações
    await _logoCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _taglineCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // Saída
    await _exitCtrl.forward();
    if (!mounted) return;

    // Navega substituindo a splash
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => _savedUser != null
            ? MainShell(user: _savedUser!)
            : const OnboardingScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _taglineCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeService>().isDark;
    final accent  = isDark ? const Color(0xFF00E676) : const Color(0xFF00C853);
    final bg      = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final onBg    = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final soft    = isDark ? const Color(0xFF888888) : const Color(0xFF777777);

    return FadeTransition(
      opacity: _exitFade,
      child: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo animado ─────────────────────────────────────────────
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color:        accent,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color:      accent.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Nome do app ───────────────────────────────────────────────
              FadeTransition(
                opacity: _logoFade,
                child: Text(
                  'GymCash',
                  style: TextStyle(
                    color:       onBg,
                    fontSize:    32,
                    fontWeight:  FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Tagline animada ───────────────────────────────────────────
              SlideTransition(
                position: _taglineSlide,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Poupe mais. Compita com amigos.',
                    style: TextStyle(
                      color:    soft,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Indicador de versão no rodapé ─────────────────────────────────
        bottomNavigationBar: FadeTransition(
          opacity: _taglineFade,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'v1.2.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    soft.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

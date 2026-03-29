// lib/services/theme_service.dart
//
// Gerencia a preferência de tema (claro / escuro) do usuário.
// Persiste via SharedPreferences e notifica o app via ChangeNotifier.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.light; // padrão: claro

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Carrega a preferência salva. Deve ser chamado antes de runApp().
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    _mode = raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Alterna entre claro e escuro e persiste a escolha.
  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
    notifyListeners();
  }

  // ── Tema claro ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness:   Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: const ColorScheme.light(
          primary:   Color(0xFF00C853),
          secondary: Color(0xFF448AFF),
          surface:   Color(0xFFFFFFFF),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor:  Color(0xFFFFFFFF),
          foregroundColor:  Color(0xFF1A1A1A),
          elevation:        0,
          centerTitle:      false,
          titleTextStyle:   TextStyle(
            color:      Color(0xFF1A1A1A),
            fontSize:   18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color:       Colors.white,
          elevation:   0,
          shape:       RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE8E8E8)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor:      Color(0xFFFFFFFF),
          selectedItemColor:    Color(0xFF00C853),
          unselectedItemColor:  Color(0xFFAAAAAA),
          elevation:            0,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00C853),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:    true,
          fillColor: const Color(0xFFF0F0F0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF00C853), width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color:     Color(0xFFEEEEEE),
          thickness: 1,
        ),
        extensions: const [GymCashColors.light],
      );

  // ── Tema escuro ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness:   Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF00E676),
          secondary: Color(0xFF448AFF),
          surface:   Color(0xFF161616),
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          foregroundColor: Colors.white,
          elevation:       0,
          centerTitle:     false,
          titleTextStyle:  TextStyle(
            color:      Colors.white,
            fontSize:   18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color:     const Color(0xFF161616),
          elevation: 0,
          shape:     RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: const BorderSide(color: Color(0xFF222222)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor:     Color(0xFF111111),
          selectedItemColor:   Color(0xFF00E676),
          unselectedItemColor: Color(0xFF555555),
          elevation:           0,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00E676),
          foregroundColor: Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:    true,
          fillColor: const Color(0xFF161616),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF222222)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF222222)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF00E676), width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color:     Color(0xFF222222),
          thickness: 1,
        ),
        extensions: const [GymCashColors.dark],
      );
}

// ── Extensão de cores semânticas do GymCash ───────────────────────────────────
//
// Permite acessar cores contextuais sem hardcode em widgets:
//   Theme.of(context).extension<GymCashColors>()!.accent
@immutable
class GymCashColors extends ThemeExtension<GymCashColors> {
  const GymCashColors({
    required this.accent,
    required this.accentSoft,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.textMuted,
    required this.textSoft,
    required this.background,
  });

  final Color accent;       // cor de destaque principal (verde)
  final Color accentSoft;   // versão com alpha baixo do accent
  final Color surface;      // superfície de cards
  final Color surfaceHigh;  // superfície elevada (modais, chips)
  final Color border;       // bordas e divisores
  final Color textMuted;    // texto de baixa ênfase
  final Color textSoft;     // texto médio
  final Color background;   // fundo da tela

  static const light = GymCashColors(
    accent:      Color(0xFF00C853),
    accentSoft:  Color(0x1A00C853),
    surface:     Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF5F5F5),
    border:      Color(0xFFE8E8E8),
    textMuted:   Color(0xFFAAAAAA),
    textSoft:    Color(0xFF777777),
    background:  Color(0xFFF5F5F5),
  );

  static const dark = GymCashColors(
    accent:      Color(0xFF00E676),
    accentSoft:  Color(0x1A00E676),
    surface:     Color(0xFF161616),
    surfaceHigh: Color(0xFF1E1E1E),
    border:      Color(0xFF222222),
    textMuted:   Color(0xFF555555),
    textSoft:    Color(0xFF888888),
    background:  Color(0xFF0A0A0A),
  );

  @override
  GymCashColors copyWith({
    Color? accent,
    Color? accentSoft,
    Color? surface,
    Color? surfaceHigh,
    Color? border,
    Color? textMuted,
    Color? textSoft,
    Color? background,
  }) =>
      GymCashColors(
        accent:      accent      ?? this.accent,
        accentSoft:  accentSoft  ?? this.accentSoft,
        surface:     surface     ?? this.surface,
        surfaceHigh: surfaceHigh ?? this.surfaceHigh,
        border:      border      ?? this.border,
        textMuted:   textMuted   ?? this.textMuted,
        textSoft:    textSoft    ?? this.textSoft,
        background:  background  ?? this.background,
      );

  @override
  GymCashColors lerp(GymCashColors other, double t) => GymCashColors(
        accent:      Color.lerp(accent,      other.accent,      t)!,
        accentSoft:  Color.lerp(accentSoft,  other.accentSoft,  t)!,
        surface:     Color.lerp(surface,     other.surface,     t)!,
        surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
        border:      Color.lerp(border,      other.border,      t)!,
        textMuted:   Color.lerp(textMuted,   other.textMuted,   t)!,
        textSoft:    Color.lerp(textSoft,    other.textSoft,    t)!,
        background:  Color.lerp(background,  other.background,  t)!,
      );
}

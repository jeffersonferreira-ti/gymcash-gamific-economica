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
    final raw = prefs.getString(_key);
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

  // ── Paleta global ─────────────────────────────────────────────────────────
  // Primária:   Violeta Elétrico  #8B5CF6
  // Secundária: Ciano             #06B6D4
  // Destaque:   Rosa Choque       #EC4899
  // Acento:     Azul Elétrico     #448AFF
  // Fundo dark: Preto Puro        #121212
  // Cards dark: Preto Profundo    #0A0A0A

  // ── Tema claro ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F4F8),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFFFFFFFF),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE8E6F0)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          selectedItemColor: Color(0xFF8B5CF6),
          unselectedItemColor: Color(0xFFAAAAAA),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0EEF8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDD9EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDD9EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEEECF8),
          thickness: 1,
        ),
        extensions: const [GymCashColors.light],
      );

  // ── Tema escuro ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF1C1C2E),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF0A0A0A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFF2A2A3E)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: Color(0xFF8B5CF6),
          unselectedItemColor: Color(0xFF555577),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2A2A3E),
          thickness: 1,
        ),
        extensions: const [GymCashColors.dark],
      );
}

// ── Extensão de cores semânticas do GymCash ───────────────────────────────────
//
// Paleta:
//   accent     = Violeta Elétrico  #8B5CF6  (primária — ações, botões, seleção)
//   secondary  = Ciano             #06B6D4  (confirmação, progresso)
//   highlight  = Rosa Choque       #EC4899  (recordes, conquistas, metas)
//   electric   = Azul Elétrico     #448AFF  (acentos, bordas de cards)
//   cardDeep   = Preto Profundo    #0A0A0A  (fundo de cards no dark)
@immutable
class GymCashColors extends ThemeExtension<GymCashColors> {
  const GymCashColors({
    required this.accent,
    required this.accentSoft,
    required this.secondary,
    required this.highlight,
    required this.electric,
    required this.surface,
    required this.surfaceHigh,
    required this.cardDeep,
    required this.border,
    required this.textMuted,
    required this.textSoft,
    required this.background,
  });

  final Color accent; // Violeta Elétrico — ações principais
  final Color accentSoft; // Violeta com alpha baixo
  final Color secondary; // Ciano — confirmação, progresso
  final Color highlight; // Rosa Choque — recordes, conquistas, metas
  final Color electric; // Azul Elétrico — acentos, bordas
  final Color surface; // superfície de cards
  final Color surfaceHigh; // superfície elevada (modais, chips)
  final Color cardDeep; // cards fundos (dark: #0A0A0A)
  final Color border; // bordas e divisores
  final Color textMuted; // texto de baixa ênfase
  final Color textSoft; // texto médio
  final Color background; // fundo da tela

  static const light = GymCashColors(
    accent: Color(0xFF8B5CF6),
    accentSoft: Color(0x1A8B5CF6),
    secondary: Color(0xFF06B6D4),
    highlight: Color(0xFFEC4899),
    electric: Color(0xFF448AFF),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF4F4F8),
    cardDeep: Color(0xFFF0EEF8),
    border: Color(0xFFE8E6F0),
    textMuted: Color(0xFFAAAAAA),
    textSoft: Color(0xFF6B6B8A),
    background: Color(0xFFF4F4F8),
  );

  static const dark = GymCashColors(
    accent: Color(0xFF8B5CF6),
    accentSoft: Color(0x1A8B5CF6),
    secondary: Color(0xFF06B6D4),
    highlight: Color(0xFFEC4899),
    electric: Color(0xFF448AFF),
    surface: Color(0xFF1C1C2E),
    surfaceHigh: Color(0xFF252540),
    cardDeep: Color(0xFF0A0A0A),
    border: Color(0xFF2A2A3E),
    textMuted: Color(0xFF555577),
    textSoft: Color(0xFF8888AA),
    background: Color(0xFF121212),
  );

  @override
  GymCashColors copyWith({
    Color? accent,
    Color? accentSoft,
    Color? secondary,
    Color? highlight,
    Color? electric,
    Color? surface,
    Color? surfaceHigh,
    Color? cardDeep,
    Color? border,
    Color? textMuted,
    Color? textSoft,
    Color? background,
  }) =>
      GymCashColors(
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        secondary: secondary ?? this.secondary,
        highlight: highlight ?? this.highlight,
        electric: electric ?? this.electric,
        surface: surface ?? this.surface,
        surfaceHigh: surfaceHigh ?? this.surfaceHigh,
        cardDeep: cardDeep ?? this.cardDeep,
        border: border ?? this.border,
        textMuted: textMuted ?? this.textMuted,
        textSoft: textSoft ?? this.textSoft,
        background: background ?? this.background,
      );

  @override
  GymCashColors lerp(GymCashColors other, double t) => GymCashColors(
        accent: Color.lerp(accent, other.accent, t)!,
        accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
        secondary: Color.lerp(secondary, other.secondary, t)!,
        highlight: Color.lerp(highlight, other.highlight, t)!,
        electric: Color.lerp(electric, other.electric, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
        cardDeep: Color.lerp(cardDeep, other.cardDeep, t)!,
        border: Color.lerp(border, other.border, t)!,
        textMuted: Color.lerp(textMuted, other.textMuted, t)!,
        textSoft: Color.lerp(textSoft, other.textSoft, t)!,
        background: Color.lerp(background, other.background, t)!,
      );
}

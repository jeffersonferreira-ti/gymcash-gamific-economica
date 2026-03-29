// lib/screens/main_shell.dart
//
// Shell principal do app após login.
// Gerencia as 4 abas via BottomNavigationBar com NavigatorState independente
// por aba (mantém estado ao trocar de aba).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user});
  final UserModel user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Cada aba tem seu próprio Navigator para manter o estado independente
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Animação da barra de seleção
  late final AnimationController _indicatorCtrl;
  late final Animation<double>   _indicatorAnim;

  @override
  void initState() {
    super.initState();
    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _indicatorAnim = CurvedAnimation(
      parent: _indicatorCtrl,
      curve: Curves.easeOutCubic,
    );
    _indicatorCtrl.forward();
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Toque na aba atual → volta ao root da aba
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
    _indicatorCtrl
      ..reset()
      ..forward();
    HapticFeedback.selectionClick();
  }

  // Intercepta o botão voltar do Android: desce na stack da aba atual
  Future<bool> _onWillPop() async {
    final nav = _navigatorKeys[_currentIndex].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GymCashColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            _buildTab(0, HomeScreen(user: widget.user)),
            _buildTab(1, RankingScreen(user: widget.user)),
            _buildTab(2, ProfileScreen(user: widget.user)),
            _buildTab(3, SettingsScreen(user: widget.user)),
          ],
        ),
        bottomNavigationBar: _GymCashBottomNav(
          currentIndex: _currentIndex,
          onTap:        _onTabTapped,
          colors:       colors,
          isDark:       isDark,
          animation:    _indicatorAnim,
        ),
      ),
    );
  }

  // Usa Offstage + TickerMode para preservar o estado de cada aba
  Widget _buildTab(int index, Widget screen) {
    final isActive = index == _currentIndex;
    return Offstage(
      offstage: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: Navigator(
          key:    _navigatorKeys[index],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => screen,
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar customizada ────────────────────────────────────────
class _GymCashBottomNav extends StatelessWidget {
  const _GymCashBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.colors,
    required this.isDark,
    required this.animation,
  });

  final int            currentIndex;
  final ValueChanged<int> onTap;
  final GymCashColors  colors;
  final bool           isDark;
  final Animation<double> animation;

  static const _items = [
    _NavItem(icon: Icons.group_outlined,        activeIcon: Icons.group_rounded,          label: 'Grupos'),
    _NavItem(icon: Icons.leaderboard_outlined,  activeIcon: Icons.leaderboard_rounded,    label: 'Ranking'),
    _NavItem(icon: Icons.person_outline_rounded,activeIcon: Icons.person_rounded,         label: 'Perfil'),
    _NavItem(icon: Icons.settings_outlined,     activeIcon: Icons.settings_rounded,       label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item     = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: _NavButton(
                  item:      item,
                  selected:  selected,
                  colors:    colors,
                  isDark:    isDark,
                  animation: animation,
                  onTap:     () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.colors,
    required this.isDark,
    required this.animation,
    required this.onTap,
  });

  final _NavItem          item;
  final bool              selected;
  final GymCashColors     colors;
  final bool              isDark;
  final Animation<double> animation;
  final VoidCallback      onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:     onTap,
      behavior:  HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pill de seleção animada
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve:    Curves.easeOutCubic,
            height:   32,
            padding:  selected
                ? const EdgeInsets.symmetric(horizontal: 16)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color:        selected
                  ? colors.accent.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key:   ValueKey(selected),
                    color: selected ? colors.accent : colors.textMuted,
                    size:  22,
                  ),
                ),
                // Label inline quando selecionado (pill expandida)
                if (selected) ...[
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color:      colors.accent,
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Label abaixo quando não selecionado
          AnimatedOpacity(
            opacity:  selected ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              item.label,
              style: TextStyle(
                color:     colors.textMuted,
                fontSize:  10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String   label;
}

// lib/widgets/goal_reached_dialog.dart

import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Diálogo animado exibido ao atingir a meta do mês.
class GoalReachedDialog extends StatefulWidget {
  const GoalReachedDialog({super.key});

  @override
  State<GoalReachedDialog> createState() => _GoalReachedDialogState();
}

class _GoalReachedDialogState extends State<GoalReachedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<GymCashColors>()!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    // Usa highlight (Rosa Choque) para metas atingidas
    final accent = colors.highlight;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),

          // Ícone animado
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.2).animate(
              CurvedAnimation(
                  parent: _controller, curve: Curves.easeInOut),
            ),
            child: RotationTransition(
              turns: Tween(begin: -0.05, end: 0.05).animate(
                CurvedAnimation(
                    parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:  accent.withValues(alpha: 0.12),
                  shape:  BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_rounded,
                    color: accent, size: 60),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'META ATINGIDA!',
            style: TextStyle(
                color:      onSurface,
                fontSize:   20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Parabéns! Você alcançou 100% do seu objetivo este mês. Continue assim!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: colors.textSoft, fontSize: 14),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text('Continuar Poupando',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Função de conveniência para abrir o diálogo de meta atingida.
Future<void> showGoalReachedDialog(BuildContext context) {
  return showDialog<void>(
    context:            context,
    barrierDismissible: true,
    barrierColor:       Colors.black.withValues(alpha: 0.65),
    builder: (_)        => const GoalReachedDialog(),
  );
}

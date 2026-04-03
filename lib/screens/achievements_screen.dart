// lib/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../models/rank_model.dart';
import '../services/achievement_service.dart';
import '../services/local_storage_service.dart';
import '../services/theme_service.dart';

class AchievementsScreen extends StatefulWidget {
  final String userId;
  const AchievementsScreen({super.key, required this.userId});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _storage      = LocalStorageService();
  late final _service = AchievementService(_storage);

  List<AchievementModel> _achievements = [];
  double _total   = 0;
  bool   _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final achievements = await _service.getAchievements(widget.userId);
    final total        = await _storage.getTotalAccumulated(widget.userId);
    if (mounted) {
      setState(() {
        _achievements = achievements;
        _total        = total;
        _loading      = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<GymCashColors>()!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final rank      = RankModel.fromTotal(_total);
    final nextRank  = RankModel.nextRank(rank);
    final progress  = RankModel.progressToNext(_total);
    final unlocked  = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: const Text('Conquistas'),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: colors.accent, strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Card de patente ────────────────────────────────────────
                _RankCard(
                  rank:     rank,
                  nextRank: nextRank,
                  total:    _total,
                  progress: progress,
                  colors:   colors,
                ),

                const SizedBox(height: 20),

                // ── Progresso geral ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Conquistas',
                        style: TextStyle(
                            color:      onSurface,
                            fontSize:   16,
                            fontWeight: FontWeight.w700)),
                    Text('$unlocked / ${_achievements.length}',
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Lista de conquistas ────────────────────────────────────
                ..._achievements.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AchievementTile(
                          achievement: a, colors: colors),
                    )),
              ],
            ),
    );
  }
}

// ── Card de patente ───────────────────────────────────────────────────────────
class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.rank,
    required this.nextRank,
    required this.total,
    required this.progress,
    required this.colors,
  });

  final RankModel  rank;
  final RankModel? nextRank;
  final double     total;
  final double     progress;
  final GymCashColors colors;

  String _fmt(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf   = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write('.');
      buf.write(parts[i]);
    }
    return 'R\$ ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final color     = Color(rank.colorValue);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rank.emoji,
                  style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sua patente',
                      style: TextStyle(
                          color:      colors.textSoft,
                          fontSize:   12,
                          fontWeight: FontWeight.w500)),
                  Text(rank.title,
                      style: TextStyle(
                          color:      color,
                          fontSize:   24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Acumulado',
                      style: TextStyle(
                          color: colors.textSoft, fontSize: 11)),
                  Text(_fmt(total),
                      style: TextStyle(
                          color:      onSurface,
                          fontSize:   16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),

          if (nextRank != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Próxima: ${nextRank!.emoji} ${nextRank!.title}',
                    style: TextStyle(
                        color: colors.textSoft, fontSize: 12)),
                Text(_fmt(nextRank!.minAmount),
                    style: TextStyle(
                        color: colors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           progress,
                minHeight:       6,
                backgroundColor: colors.border,
                valueColor:      AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Patente máxima atingida!',
                  style: TextStyle(
                      color:      color,
                      fontSize:   12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tile de conquista ─────────────────────────────────────────────────────────
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.colors,
  });

  final AchievementModel achievement;
  final GymCashColors    colors;

  @override
  Widget build(BuildContext context) {
    final unlocked  = achievement.isUnlocked;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        unlocked ? colors.surface : colors.cardDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? colors.accent.withValues(alpha: 0.2)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          // Emoji / cadeado
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: unlocked
                  ? colors.highlight.withValues(alpha: 0.12)
                  : colors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: unlocked
                  ? Text(achievement.emoji,
                      style: const TextStyle(fontSize: 22))
                  : Icon(Icons.lock_outline_rounded,
                      color: colors.textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 14),

          // Título e descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: TextStyle(
                        color:      unlocked ? onSurface : colors.textMuted,
                        fontSize:   14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(achievement.description,
                    style: TextStyle(
                        color:   colors.textSoft, fontSize: 12)),
              ],
            ),
          ),

          // Badge desbloqueado
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        colors.highlight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('✓',
                  style: TextStyle(
                      color:      colors.highlight,
                      fontSize:   13,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

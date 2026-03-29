// lib/screens/ranking_screen.dart
//
// Aba Ranking: exibe o ranking do mês atual de todos os grupos
// em que o usuário participa, com cards expansíveis por grupo.

import 'package:flutter/material.dart';

import '../models/contribution_model.dart';
import '../models/group_model.dart';
import '../models/ranking_entry.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/ranking_service.dart';
import '../services/theme_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _storage = LocalStorageService();

  List<_GroupRanking> _groupRankings = [];
  bool _loading = true;
  String _month = '';

  @override
  void initState() {
    super.initState();
    _month = _currentMonth();
    _load();
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String get _monthLabel {
    final parts = _month.split('-');
    if (parts.length != 2) return _month;
    const months = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final groups = await _storage.getGroups();
      final contribs = await _storage.getContributions();

      // Fecha meses pendentes em paralelo
      for (final g in groups) {
        await RankingService(_storage).checkAndCloseMonths(g);
      }

      // Monta ranking por grupo
      final result = <_GroupRanking>[];
      for (final group in groups) {
        // Só exibe grupos em que o usuário é membro
        if (!group.members.any((m) => m.id == widget.user.id)) continue;

        final monthContribs = contribs
            .where((c) => c.groupId == group.id && c.month == _month)
            .toList();

        final entries = group.members.map((member) {
          ContributionModel? contrib;
          try {
            contrib = monthContribs.firstWhere((c) => c.userId == member.id);
          } catch (_) {
            contrib = null;
          }
          return RankingEntry(member: member, contribution: contrib);
        }).toList()
          ..sort((a, b) {
            final diff = b.progress.compareTo(a.progress);
            return diff != 0 ? diff : a.member.name.compareTo(b.member.name);
          });

        result.add(_GroupRanking(group: group, entries: entries));
      }

      if (mounted) {
        setState(() {
          _groupRankings = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GymCashColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ranking',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(_monthLabel,
                style: TextStyle(
                    color: colors.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: Icon(Icons.refresh_rounded, color: colors.textMuted),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: colors.accent, strokeWidth: 2))
          : _groupRankings.isEmpty
              ? _buildEmpty(colors)
              : RefreshIndicator(
                  color: colors.accent,
                  backgroundColor: colors.surface,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    itemCount: _groupRankings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _GroupRankingCard(
                      groupRanking: _groupRankings[i],
                      currentUser: widget.user,
                      colors: colors,
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty(GymCashColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.leaderboard_outlined,
                  color: colors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Nenhum grupo ainda',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Crie um grupo na aba Grupos\ne adicione membros para ver o ranking.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: colors.textSoft, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dados de ranking por grupo ────────────────────────────────────────────────
class _GroupRanking {
  const _GroupRanking({required this.group, required this.entries});
  final GroupModel group;
  final List<RankingEntry> entries;
}

// ── Card expansível de ranking por grupo ──────────────────────────────────────
class _GroupRankingCard extends StatefulWidget {
  const _GroupRankingCard({
    required this.groupRanking,
    required this.currentUser,
    required this.colors,
  });
  final _GroupRanking groupRanking;
  final UserModel currentUser;
  final GymCashColors colors;

  @override
  State<_GroupRankingCard> createState() => _GroupRankingCardState();
}

class _GroupRankingCardState extends State<_GroupRankingCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = true; // começa expandido

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final group = widget.groupRanking.group;
    final entries = widget.groupRanking.entries;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Posição do usuário atual
    final myIndex =
        entries.indexWhere((e) => e.member.id == widget.currentUser.id);
    final myPosition = myIndex >= 0 ? myIndex + 1 : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // ── Header do card ───────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.group_rounded,
                        color: colors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name,
                            style: TextStyle(
                                color: onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${entries.length} ${entries.length == 1 ? "membro" : "membros"}'
                          '${myPosition != null ? " · você em $myPosition°" : ""}',
                          style:
                              TextStyle(color: colors.textSoft, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de ranking ─────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                Divider(color: colors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: entries.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RankingRow(
                          position: e.key + 1,
                          entry: e.value,
                          isCurrentUser:
                              e.value.member.id == widget.currentUser.id,
                          colors: colors,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ── Linha de ranking ──────────────────────────────────────────────────────────
class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.entry,
    required this.isCurrentUser,
    required this.colors,
  });

  final int position;
  final RankingEntry entry;
  final bool isCurrentUser;
  final GymCashColors colors;

  String _medal(int pos) {
    switch (pos) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$pos°';
    }
  }

  Color _posColor(int pos) {
    switch (pos) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return colors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final progress = entry.progress;
    final hasGoal = entry.hasGoal;
    final reached = entry.goalReached;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colors.accent.withValues(alpha: 0.07)
            : colors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? colors.accent.withValues(alpha: 0.25)
              : colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Posição
              SizedBox(
                width: 32,
                child: Text(
                  _medal(position),
                  style: TextStyle(
                    fontSize: position <= 3 ? 18 : 13,
                    color: _posColor(position),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),

              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.accent.withValues(alpha: 0.12),
                child: Text(
                  entry.member.initials,
                  style: TextStyle(
                      color: colors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),

              // Nome
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.member.name,
                        style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: isCurrentUser
                                ? FontWeight.w700
                                : FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('você',
                            style: TextStyle(
                                color: colors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),

              // Progresso
              Text(
                entry.progressLabel,
                style: TextStyle(
                  color: reached ? colors.accent : onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Barra de progresso
          if (hasGoal) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  reached ? colors.accent : const Color(0xFF448AFF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

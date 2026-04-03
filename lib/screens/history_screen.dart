// lib/screens/history_screen.dart
//
// Exibe o histórico de meses fechados de um grupo,
// com vencedor e ranking completo de cada mês.

import 'package:flutter/material.dart';
import '../models/monthly_result_model.dart';
import '../services/local_storage_service.dart';
import '../services/theme_service.dart';

class HistoryScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const HistoryScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = LocalStorageService();
  List<MonthlyResultModel> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results =
        await _storage.getMonthlyResults(groupId: widget.groupId);
    if (mounted) {
      setState(() {
        _results  = results;
        _loading  = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GymCashColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(widget.groupName,
                style: TextStyle(
                    color: colors.textSoft, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                    color: colors.accent, strokeWidth: 2))
            : _results.isEmpty
                ? _buildEmpty(colors)
                : _buildList(colors),
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
              width: 72, height: 72,
              decoration: BoxDecoration(
                color:        colors.surface,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: colors.border),
              ),
              child: Icon(Icons.history_rounded,
                  color: colors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Nenhum mês fechado ainda',
                style: TextStyle(
                    color:      Theme.of(context).colorScheme.onSurface,
                    fontSize:   17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'O ranking do mês é salvo\nautomaticamente quando o mês vira.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textSoft, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(GymCashColors colors) {
    return ListView.separated(
      padding:          const EdgeInsets.all(24),
      itemCount:        _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:      (_, i)  => _MonthCard(
          result: _results[i], colors: colors),
    );
  }
}

// ── Card expansível de um mês ─────────────────────────────────────────────────
class _MonthCard extends StatefulWidget {
  const _MonthCard({required this.result, required this.colors});
  final MonthlyResultModel result;
  final GymCashColors      colors;

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final result    = widget.result;
    final colors    = widget.colors;
    final hasWinner = result.winnerId != null;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Cor do troféu: dourado para vencedor, muted para sem vencedor
    const gold = Color(0xFFFFD700);

    return Container(
      decoration: BoxDecoration(
        color:        colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWinner
              ? gold.withValues(alpha: 0.25)
              : colors.border,
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          InkWell(
            onTap:        () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: hasWinner
                          ? gold.withValues(alpha: 0.1)
                          : colors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasWinner
                          ? Icons.emoji_events_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: hasWinner ? gold : colors.textMuted,
                      size:  22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.monthLabel,
                            style: TextStyle(
                                color:      onSurface,
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          hasWinner
                              ? '🥇 ${result.winnerName}'
                              : 'Sem vencedor',
                          style: TextStyle(
                            color:      hasWinner ? gold : colors.textMuted,
                            fontSize:   13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Ranking expandido ────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild:  const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                Divider(color: colors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: result.ranking.map((snap) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RankRow(
                              snapshot: snap, colors: colors),
                        )).toList(),
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration:  const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ── Linha do ranking no histórico ─────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  const _RankRow({required this.snapshot, required this.colors});
  final RankingSnapshot snapshot;
  final GymCashColors   colors;

  String _medal(int pos) {
    switch (pos) {
      case 1:  return '🥇';
      case 2:  return '🥈';
      case 3:  return '🥉';
      default: return '$pos°';
    }
  }

  String get _initials {
    final parts = snapshot.userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isFirst   = snapshot.position == 1;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final reached   = snapshot.progress >= 1.0;

    return Row(
      children: [
        // Posição
        SizedBox(
          width: 36,
          child: Text(
            _medal(snapshot.position),
            style: TextStyle(
              fontSize:   snapshot.position <= 3 ? 18 : 13,
              color:      colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),

        // Avatar
        CircleAvatar(
          radius:          16,
          backgroundColor: colors.accent.withValues(alpha: 0.12),
          child: Text(_initials,
              style: TextStyle(
                  color:      colors.accent,
                  fontSize:   11,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),

        // Nome
        Expanded(
          child: Text(snapshot.userName,
              style: TextStyle(
                color:      isFirst ? onSurface : colors.textSoft,
                fontSize:   14,
                fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
              )),
        ),

        // Progresso
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: reached
                ? colors.secondary.withValues(alpha: 0.12)
                : colors.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            snapshot.progressLabel,
            style: TextStyle(
              color:      reached ? colors.secondary : colors.textSoft,
              fontSize:   13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

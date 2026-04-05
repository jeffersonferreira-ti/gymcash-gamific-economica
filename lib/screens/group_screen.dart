// lib/screens/group_screen.dart
//
// Exibe o ranking de contribuições do mês e gerencia membros.

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/contribution_model.dart';
import '../models/ranking_entry.dart';
import '../services/local_storage_service.dart';
import '../services/ranking_service.dart';
import '../services/theme_service.dart';
import 'add_member_screen.dart';
import 'add_contribution_screen.dart';
import 'history_screen.dart';
import '../widgets/rename_group_dialog.dart';

class GroupScreen extends StatefulWidget {
  final GroupModel group;
  final UserModel  currentUser;

  const GroupScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  final _storage = LocalStorageService();
  late GroupModel        _group;
  List<RankingEntry>     _ranking = [];
  bool                   _loading = true;
  late TabController     _tabs;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabs  = TabController(length: 3, vsync: this);
    _checkMonthClose();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final groups = await _storage.getGroups();
    final fresh  = groups.firstWhere(
      (g) => g.id == _group.id,
      orElse: () => _group,
    );
    final contribs =
        await _storage.getGroupContributions(groupId: fresh.id);

    final entries = fresh.members.map((member) {
      ContributionModel? contrib;
      try {
        contrib = contribs.firstWhere((c) => c.userId == member.id);
      } catch (_) {
        contrib = null;
      }
      return RankingEntry(member: member, contribution: contrib);
    }).toList()
      ..sort((a, b) {
        final diff = b.progress.compareTo(a.progress);
        return diff != 0 ? diff : a.member.name.compareTo(b.member.name);
      });

    if (mounted) {
      setState(() {
        _group   = fresh;
        _ranking = entries;
        _loading = false;
      });
    }
  }

  Future<void> _checkMonthClose() async {
    final closed =
        await RankingService(_storage).checkAndCloseMonths(_group);
    if (closed && mounted) _load();
  }

  Future<void> _goToHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          groupId:   _group.id,
          groupName: _group.name,
        ),
      ),
    );
  }

  Future<void> _goToContribution() async {
    final existing = await _storage.getContribution(
      userId:  widget.currentUser.id,
      groupId: _group.id,
    );
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddContributionScreen(
          groupId:     _group.id,
          currentUser: widget.currentUser,
          existing:    existing,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _goToAddMember() async {
    final updated = await Navigator.of(context).push<GroupModel>(
      MaterialPageRoute(
          builder: (_) => AddMemberScreen(groupId: _group.id)),
    );
    if (updated != null && mounted) {
      setState(() => _group = updated);
      _load();
    }
  }

  Future<void> _removeMember(
      String memberId, String memberName, GymCashColors colors) async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Remover membro?',
            style: TextStyle(
                color: onSurface, fontWeight: FontWeight.w700)),
        content: Text('$memberName será removido do grupo.',
            style: TextStyle(color: colors.textSoft, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover',
                style: TextStyle(
                    color:      Colors.redAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.removeMember(_group.id, memberId);
    _load();
  }

  Future<void> _renameGroup(GymCashColors colors) async {
    final newName = await showRenameGroupDialog(
      context,
      initialName: _group.name,
    );
    if (newName == null || !mounted) return;

    try {
      final updated = await _storage.renameGroup(_group.id, newName);
      if (!mounted) return;
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         const Text('Nome do grupo atualizado.'),
        behavior:        SnackBarBehavior.floating,
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ));
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      _showErrorSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnack('Não foi possível salvar o nome. Tente novamente.');
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<GymCashColors>()!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          _group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip:   'Renomear grupo',
            icon:      const Icon(Icons.edit_outlined),
            onPressed: () => _renameGroup(colors),
          ),
        ],
        bottom: TabBar(
          controller:           _tabs,
          labelColor:           colors.accent,
          unselectedLabelColor: colors.textMuted,
          indicatorColor:       colors.accent,
          indicatorSize:        TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Ranking'),
            Tab(text: 'Membros'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: colors.accent, strokeWidth: 2))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildRankingTab(colors, onSurface),
                _buildMembersTab(colors, onSurface),
                _buildHistoryTab(colors, onSurface),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          if (_tabs.index == 0) {
            return FloatingActionButton.extended(
              onPressed:       _goToContribution,
              icon:            const Icon(Icons.savings_outlined),
              label:           const Text('Minha contribuição',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            );
          }
          if (_tabs.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _goToAddMember,
              icon:      const Icon(Icons.person_add_rounded),
              label:     const Text('Adicionar membro',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Aba: Ranking ──────────────────────────────────────────────────────────
  Widget _buildRankingTab(GymCashColors colors, Color onSurface) {
    if (_ranking.isEmpty) return _buildEmptyState(
      colors:  colors,
      icon:    Icons.bar_chart_rounded,
      title:   'Sem membros no grupo',
      subtitle: 'Adicione membros e registre\nsuas contribuições.',
    );

    final month = ContributionModel.currentMonth();

    return ListView.builder(
      padding:   const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: _ranking.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(children: [
              Icon(Icons.emoji_events_rounded,
                  color: colors.accent, size: 16),
              const SizedBox(width: 6),
              Text('Ranking de $month',
                  style: TextStyle(
                      color: colors.textMuted, fontSize: 13)),
            ]),
          );
        }
        final pos   = i - 1;
        final entry = _ranking[pos];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RankingCard(
            position:      pos + 1,
            entry:         entry,
            isCurrentUser: entry.member.id == widget.currentUser.id,
            colors:        colors,
            onSurface:     onSurface,
          ),
        );
      },
    );
  }

  // ── Aba: Membros ──────────────────────────────────────────────────────────
  Widget _buildMembersTab(GymCashColors colors, Color onSurface) {
    final members = _group.members;
    if (members.isEmpty) return _buildEmptyState(
      colors:   colors,
      icon:     Icons.person_outline_rounded,
      title:    'Sem membros',
      subtitle: null,
    );

    return ListView.separated(
      padding:          const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount:        members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = members[i];
        return _MemberTile(
          member:        m,
          isCurrentUser: m.id == widget.currentUser.id,
          colors:        colors,
          onSurface:     onSurface,
          onRemove: () => _removeMember(m.id, m.name, colors),
        );
      },
    );
  }

  // ── Aba: Histórico ────────────────────────────────────────────────────────
  Widget _buildHistoryTab(GymCashColors colors, Color onSurface) {
    const gold = Color(0xFFFFD700);

    return FutureBuilder(
      future: _storage.getMonthlyResults(groupId: _group.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  color: colors.accent, strokeWidth: 2));
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return _buildEmptyState(
            colors:   colors,
            icon:     Icons.history_rounded,
            title:    'Nenhum mês fechado ainda',
            subtitle: 'O ranking é salvo automaticamente\nquando o mês vira.',
          );
        }
        return ListView.separated(
          padding:          const EdgeInsets.fromLTRB(24, 16, 24, 40),
          itemCount:        results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r         = results[i];
            final hasWinner = r.winnerId != null;
            return GestureDetector(
              onTap: _goToHistory,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasWinner
                        ? gold.withValues(alpha: 0.2)
                        : colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: hasWinner
                            ? gold.withValues(alpha: 0.1)
                            : colors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasWinner
                            ? Icons.emoji_events_rounded
                            : Icons.remove_circle_outline_rounded,
                        color: hasWinner ? gold : colors.textMuted,
                        size:  20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.monthLabel,
                              style: TextStyle(
                                  color:      onSurface,
                                  fontSize:   15,
                                  fontWeight: FontWeight.w600)),
                          if (r.winnerName != null)
                            Text('🥇 ${r.winnerName}',
                                style: const TextStyle(
                                    color:   Color(0xFFFFD700),
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: colors.textMuted, size: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Estado vazio genérico ─────────────────────────────────────────────────
  Widget _buildEmptyState({
    required GymCashColors colors,
    required IconData      icon,
    required String        title,
    required String?       subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color:        colors.surface,
                borderRadius: BorderRadius.circular(18),
                border:       Border.all(color: colors.border),
              ),
              child: Icon(icon, color: colors.textMuted, size: 32),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: TextStyle(
                    color:      Theme.of(context).colorScheme.onSurface,
                    fontSize:   17,
                    fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:  colors.textSoft,
                      fontSize: 13,
                      height:   1.6)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Card do ranking ───────────────────────────────────────────────────────────
class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.position,
    required this.entry,
    required this.isCurrentUser,
    required this.colors,
    required this.onSurface,
  });

  final int           position;
  final RankingEntry  entry;
  final bool          isCurrentUser;
  final GymCashColors colors;
  final Color         onSurface;

  Color get _positionColor {
    switch (position) {
      case 1:  return const Color(0xFFFFD700);
      case 2:  return const Color(0xFFC0C0C0);
      case 3:  return const Color(0xFFCD7F32);
      default: return colors.textMuted;
    }
  }

  String _medal(int pos) {
    switch (pos) {
      case 1:  return '🥇';
      case 2:  return '🥈';
      case 3:  return '🥉';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = entry.progress;
    final hasData  = entry.contribution != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colors.accent.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? colors.accent.withValues(alpha: 0.3)
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
                  position <= 3 ? _medal(position) : '$position°',
                  style: TextStyle(
                    fontSize:   position <= 3 ? 20 : 14,
                    color:      _positionColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius:          18,
                backgroundColor: colors.accent.withValues(alpha: 0.12),
                child: Text(
                  entry.member.initials,
                  style: TextStyle(
                      color:      colors.accent,
                      fontSize:   12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),

              // Nome
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.member.name,
                            style: TextStyle(
                                color:      onSurface,
                                fontSize:   15,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:        colors.accent
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('você',
                                style: TextStyle(
                                    color:      colors.accent,
                                    fontSize:   10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    if (!hasData)
                      Text('Sem contribuição',
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ),

              // Porcentagem
              Text(
                entry.progressLabel,
                style: TextStyle(
                  color: entry.goalReached
                      ? colors.secondary
                      : onSurface,
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Barra de progresso
          if (hasData && entry.hasGoal) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           progress.clamp(0.0, 1.0),
                minHeight:       6,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  entry.goalReached
                      ? colors.secondary
                      : colors.electric,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tile de membro ────────────────────────────────────────────────────────────
class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.colors,
    required this.onSurface,
    required this.onRemove,
  });

  final UserModel     member;
  final bool          isCurrentUser;
  final GymCashColors colors;
  final Color         onSurface;
  final VoidCallback  onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        colors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius:          20,
            backgroundColor: colors.accent.withValues(alpha: 0.12),
            child: Text(member.initials,
                style: TextStyle(
                    color:      colors.accent,
                    fontSize:   14,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text(member.name,
                    style: TextStyle(
                        color:      onSurface,
                        fontSize:   15,
                        fontWeight: FontWeight.w500)),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:        colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('você',
                        style: TextStyle(
                            color:      colors.accent,
                            fontSize:   10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          if (!isCurrentUser)
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded,
                  color: colors.textMuted, size: 20),
              onPressed: onRemove,
              tooltip:   'Remover',
            ),
        ],
      ),
    );
  }
}

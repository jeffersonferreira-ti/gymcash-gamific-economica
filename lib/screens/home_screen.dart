// lib/screens/home_screen.dart
//
// Aba Grupos do MainShell.
// Header simplificado — perfil, extrato e configurações vivem em abas próprias.

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/local_storage_service.dart';
import '../services/sort_service.dart';
import '../services/streak_service.dart';
import '../services/achievement_service.dart';
import '../services/theme_service.dart';
import '../models/rank_model.dart';
import '../models/achievement_model.dart';
import 'achievements_screen.dart';
import 'create_group_screen.dart';
import 'group_screen.dart';
import '../widgets/achievement_unlock_toast.dart';
import '../widgets/rename_group_dialog.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage     = LocalStorageService();
  final _sortService = SortService();

  List<GroupModel> _groups        = [];
  List<GroupModel> _groupsSorted  = [];
  double   _totalAccumulated      = 0.0;
  int      _streak                = 0;
  RankModel? _rank;
  int      _unlockedCount         = 0;
  bool     _loading               = true;
  String?  _loadError;
  GroupSortOrder _sortOrder       = GroupSortOrder.recent;

  @override
  void initState() {
    super.initState();
    _loadSortOrder().then((_) => _loadGroups());
  }

  Future<void> _loadSortOrder() async {
    final order = await _sortService.loadOrder();
    if (mounted) setState(() => _sortOrder = order);
  }

  void _applySorting() {
    _groupsSorted = _sortService.sort(_groups, _sortOrder);
  }

  Future<void> _toggleSort() async {
    final next = _sortOrder == GroupSortOrder.recent
        ? GroupSortOrder.alphabetical
        : GroupSortOrder.recent;
    await _sortService.saveOrder(next);
    setState(() {
      _sortOrder = next;
      _applySorting();
    });
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _loadError = null;
        if (_groups.isEmpty) _loading = true;
      });
    }
    try {
      final groups        = await _storage.getGroups();
      final total         = await _storage.getTotalAccumulated(widget.user.id);
      final streak        = await StreakService(_storage).calculateStreak(widget.user.id);
      final newlyUnlocked = await AchievementService(_storage).checkAndUnlock(widget.user.id);
      final unlockedCount = await AchievementService(_storage).unlockedCount(widget.user.id);
      final rank          = RankModel.fromTotal(total);

      if (!mounted) return;
      setState(() {
        _groups           = groups;
        _totalAccumulated = total;
        _streak           = streak;
        _rank             = rank;
        _unlockedCount    = unlockedCount;
        _loading          = false;
        _loadError        = null;
        _applySorting();
      });

      if (newlyUnlocked.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AchievementUnlockToast.showSequence(context, newlyUnlocked);
        });
      }
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _loadError = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading   = false;
        _loadError = 'Não foi possível carregar seus dados. Toque para tentar de novo.';
      });
    }
  }

  Future<void> _goToCreateGroup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(currentUser: widget.user),
      ),
    );
    _loadGroups();
  }

  Future<void> _goToGroup(GroupModel group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupScreen(group: group, currentUser: widget.user),
      ),
    );
    _loadGroups();
  }

  Future<void> _deleteGroup(GroupModel group) async {
    final colors = Theme.of(context).extension<GymCashColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir grupo?',
            style: TextStyle(
                color:      Theme.of(ctx).colorScheme.onSurface,
                fontWeight: FontWeight.w700)),
        content: Text(
          'O grupo "${group.name}" e todos os seus dados serão removidos permanentemente.',
          style: TextStyle(color: colors.textSoft, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar',
                  style: TextStyle(color: colors.textMuted))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir',
                  style: TextStyle(
                      color:      Colors.redAccent,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.deleteGroup(group.id);
    _loadGroups();
  }

  Future<void> _renameGroup(GroupModel group) async {
    final colors  = Theme.of(context).extension<GymCashColors>()!;
    final newName = await showRenameGroupDialog(
        context, initialName: group.name);
    if (newName == null || !mounted) return;
    try {
      await _storage.renameGroup(group.id, newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         const Text('Nome atualizado.'),
        behavior:        SnackBarBehavior.floating,
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border)),
      ));
      _loadGroups();
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(e.message),
        behavior:        SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.4))),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<GymCashColors>()!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor:           colors.background,
        automaticallyImplyLeading: false,
        title: Text('Olá, ${widget.user.firstName}! 👋',
            style: TextStyle(
                color:      onSurface,
                fontSize:   20,
                fontWeight: FontWeight.w800)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cards de resumo ────────────────────────────────────────────
          if (!_loading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: _AccumulatedCard(
                  total: _totalAccumulated, colors: colors),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _StreakCard(streak: _streak, colors: colors),
            ),
            const SizedBox(height: 10),
            if (_rank != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _RankBadge(
                  rank:          _rank!,
                  unlockedCount: _unlockedCount,
                  colors:        colors,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (_) =>
                            AchievementsScreen(userId: widget.user.id),
                      ))
                      .then((_) => _loadGroups()),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // ── Cabeçalho da lista ─────────────────────────────────────────
          if (!_loading && _groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
              child: Row(
                children: [
                  Text('Grupos',
                      style: TextStyle(
                          color:         colors.textMuted,
                          fontSize:      12,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.8)),
                  const Spacer(),
                  _SortButton(
                    order:    _sortOrder,
                    colors:   colors,
                    onToggle: _toggleSort,
                  ),
                ],
              ),
            ),

          // ── Banner de erro parcial ─────────────────────────────────────
          if (!_loading && _loadError != null && _groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: _ErrorBanner(
                  message: _loadError!, onRetry: _loadGroups, colors: colors),
            ),

          // ── Corpo ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: colors.accent, strokeWidth: 2))
                : _loadError != null && _groups.isEmpty
                    ? _buildFullError(colors)
                    : _groups.isEmpty
                        ? _buildEmpty(colors)
                        : _buildList(colors),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateGroup,
        icon:      const Icon(Icons.add_rounded),
        label:     const Text('Novo grupo',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildList(GymCashColors colors) {
    return RefreshIndicator(
      color:           colors.accent,
      backgroundColor: colors.surface,
      onRefresh:       _loadGroups,
      child: ListView.separated(
        padding:          const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount:        _groupsSorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final group = _groupsSorted[i];
          return _GroupCard(
            group:    group,
            colors:   colors,
            onTap:    () => _goToGroup(group),
            onRename: () => _renameGroup(group),
            onDelete: () => _deleteGroup(group),
          );
        },
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
              child: Icon(Icons.group_outlined,
                  color: colors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Nenhum grupo ainda',
                style: TextStyle(
                    color:      Theme.of(context).colorScheme.onSurface,
                    fontSize:   18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Crie seu primeiro grupo\npelo botão abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textSoft, fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildFullError(GymCashColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size:  56,
                color: Colors.redAccent.withValues(alpha: 0.65)),
            const SizedBox(height: 20),
            Text(_loadError ?? 'Erro ao carregar.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFAAAAAA), fontSize: 15, height: 1.5)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loadGroups,
              icon:      const Icon(Icons.refresh_rounded),
              label:     const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botão de ordenação ────────────────────────────────────────────────────────
class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.order,
    required this.colors,
    required this.onToggle,
  });
  final GroupSortOrder order;
  final GymCashColors  colors;
  final VoidCallback   onToggle;

  @override
  Widget build(BuildContext context) {
    final isAlpha = order == GroupSortOrder.alphabetical;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:        colors.surface,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlpha
                  ? Icons.sort_by_alpha_rounded
                  : Icons.access_time_rounded,
              color: colors.accent,
              size:  14,
            ),
            const SizedBox(width: 5),
            Text(
              isAlpha ? 'A→Z' : 'Recentes',
              style: TextStyle(
                  color:      colors.accent,
                  fontSize:   11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner de erro parcial ────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.colors,
  });
  final String        message;
  final VoidCallback  onRetry;
  final GymCashColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: colors.textSoft, fontSize: 13, height: 1.35)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Atualizar',
                style: TextStyle(
                    color:      colors.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Card de grupo ─────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.colors,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });
  final GroupModel    group;
  final GymCashColors colors;
  final VoidCallback  onTap;
  final VoidCallback  onRename;
  final VoidCallback  onDelete;

  @override
  Widget build(BuildContext context) {
    final count     = group.members.length;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            color:        colors.surface,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color:        colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group_rounded,
                    color: colors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines:  2,
                        overflow:  TextOverflow.ellipsis,
                        style: TextStyle(
                            color:      onSurface,
                            fontSize:   16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      count == 0
                          ? 'Sem membros'
                          : '$count ${count == 1 ? "membro" : "membros"}',
                      style: TextStyle(
                          color: colors.textSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                icon:    Icon(Icons.more_vert_rounded,
                    color: colors.textMuted, size: 22),
                color:   colors.surfaceHigh,
                shape:   RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:         BorderSide(color: colors.border),
                ),
                offset: const Offset(0, 40),
                onSelected: (v) {
                  if (v == 'rename') onRename();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          color: colors.accent, size: 20),
                      const SizedBox(width: 12),
                      Text('Renomear',
                          style: TextStyle(
                              color:      Theme.of(ctx).colorScheme.onSurface,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent.withValues(alpha: 0.9),
                          size: 20),
                      const SizedBox(width: 12),
                      Text('Excluir grupo',
                          style: TextStyle(
                              color: Colors.redAccent.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de total acumulado ───────────────────────────────────────────────────
class _AccumulatedCard extends StatelessWidget {
  const _AccumulatedCard({required this.total, required this.colors});
  final double        total;
  final GymCashColors colors;

  String _fmt(double v) {
    final parts   = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec     = parts[1];
    final buf     = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    return 'R\$ ${buf.toString()},$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.12),
            colors.accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        colors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.savings_outlined,
                color: colors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total acumulado',
                    style: TextStyle(
                        color:      colors.textSoft,
                        fontSize:   12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(_fmt(total),
                    style: TextStyle(
                        color:         Theme.of(context).colorScheme.onSurface,
                        fontSize:      22,
                        fontWeight:    FontWeight.w800,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('histórico',
                style: TextStyle(
                    color:      colors.accent,
                    fontSize:   10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Card de streak ────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.colors});
  final int           streak;
  final GymCashColors colors;

  String get _label {
    if (streak == 0) return 'Comece a contribuir este mês!';
    if (streak == 1) return '1 mês consecutivo';
    return '$streak meses consecutivos';
  }

  String get _emoji {
    if (streak == 0) return '💤';
    if (streak < 3)  return '🔥';
    if (streak < 6)  return '🔥🔥';
    return '🔥🔥🔥';
  }

  Color get _fireColor {
    if (streak == 0) return const Color(0xFF999999);
    if (streak < 3)  return const Color(0xFFFF6B35);
    if (streak < 6)  return const Color(0xFFFF4500);
    return const Color(0xFFFF2200);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: streak > 0
            ? _fireColor.withValues(alpha: 0.07)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak > 0
              ? _fireColor.withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        _fireColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(_emoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sequência',
                    style: TextStyle(
                        color:      colors.textSoft,
                        fontSize:   12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(_label,
                    style: TextStyle(
                        color:      streak > 0 ? onSurface : colors.textMuted,
                        fontSize:   16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        _fireColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$streak',
                  style: TextStyle(
                      color:      _fireColor,
                      fontSize:   22,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

// ── Badge de patente ──────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.unlockedCount,
    required this.colors,
    required this.onTap,
  });
  final RankModel     rank;
  final int           unlockedCount;
  final GymCashColors colors;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(rank.colorValue);
    final total = AchievementModel.all.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(rank.emoji,
                style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rank.title,
                      style: TextStyle(
                          color:      color,
                          fontSize:   15,
                          fontWeight: FontWeight.w700)),
                  Text('$unlockedCount/$total conquistas',
                      style: TextStyle(
                          color: colors.textSoft, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// lib/screens/settings_screen.dart
//
// Tela de configurações: tema claro/escuro, nome do usuário e sobre o app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = LocalStorageService();
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  // ── Alterar nome ──────────────────────────────────────────────────────────

  Future<void> _changeName() async {
    final newName = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => _ChangeNameDialog(currentName: _user.name),
    );
    if (newName == null || !mounted) return;

    try {
      final updated = UserModel(id: _user.id, name: newName.trim());
      await _storage.saveUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      _showSnack('Nome atualizado para "${updated.name}".');
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    }
  }

  // ── Reset completo ────────────────────────────────────────────────────────

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Redefinir tudo?',
            style:
                TextStyle(color: _onSurface(ctx), fontWeight: FontWeight.w700)),
        content: Text(
          'Todos os grupos, contribuições e conquistas serão apagados permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: _textSoft(ctx), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: _textSoft(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar tudo',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _storage.clearUser();
    if (!mounted) return;
    // Reinicia o app voltando ao onboarding
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    final colors = Theme.of(context).extension<GymCashColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.redAccent.withValues(alpha: 0.15) : colors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? Colors.redAccent.withValues(alpha: 0.4)
                : colors.accent.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  // ── Helpers de cor (tema-aware) ───────────────────────────────────────────

  Color _surface(BuildContext ctx) =>
      Theme.of(ctx).extension<GymCashColors>()!.surface;

  Color _onSurface(BuildContext ctx) => Theme.of(ctx).colorScheme.onSurface;

  Color _textSoft(BuildContext ctx) =>
      Theme.of(ctx).extension<GymCashColors>()!.textSoft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GymCashColors>()!;
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeService>().isDark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: const Text('Configurações'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            // ── Perfil ────────────────────────────────────────────────────
            _SectionLabel('Perfil', colors: colors),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Nome de exibição',
              subtitle: _user.name,
              colors: colors,
              onTap: _changeName,
              trailing:
                  Icon(Icons.edit_outlined, size: 18, color: colors.textMuted),
            ),

            const SizedBox(height: 24),

            // ── Aparência ─────────────────────────────────────────────────
            _SectionLabel('Aparência', colors: colors),
            const SizedBox(height: 10),
            _SettingsTile(
              icon:
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              title: 'Tema',
              subtitle: isDark ? 'Escuro' : 'Claro',
              colors: colors,
              trailing: Switch.adaptive(
                value: isDark,
                activeTrackColor: colors.accent,
                onChanged: (_) => context.read<ThemeService>().toggle(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Dados ─────────────────────────────────────────────────────
            _SectionLabel('Dados', colors: colors),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Redefinir tudo',
              subtitle: 'Apaga grupos, contribuições e conquistas',
              colors: colors,
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
              onTap: _confirmReset,
            ),

            const SizedBox(height: 24),

            // ── Sobre ─────────────────────────────────────────────────────
            _SectionLabel('Sobre', colors: colors),
            const SizedBox(height: 10),
            _AboutCard(colors: colors, theme: theme),
          ],
        ),
      ),
    );
  }
}

// ── Label de seção ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.colors});
  final String label;
  final GymCashColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Tile de configuração ──────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.colors,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final GymCashColors colors;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? colors.accent;
    final effectiveTitleColor =
        titleColor ?? Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: effectiveTitleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style:
                              TextStyle(color: colors.textSoft, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: colors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card sobre o app ──────────────────────────────────────────────────────────
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.colors, required this.theme});
  final GymCashColors colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.fitness_center_rounded,
                color: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                size: 32),
          ),
          const SizedBox(height: 14),
          Text('GymCash',
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Versão 1.2.0',
              style: TextStyle(color: colors.textSoft, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            'Gamificação de poupança pessoal\ncom privacidade por design.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: colors.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text('Desenvolvido por Jefferson Ferreira',
                  style: TextStyle(color: colors.textSoft, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Diálogo de alterar nome ───────────────────────────────────────────────────
class _ChangeNameDialog extends StatefulWidget {
  const _ChangeNameDialog({required this.currentName});
  final String currentName;

  @override
  State<_ChangeNameDialog> createState() => _ChangeNameDialogState();
}

class _ChangeNameDialogState extends State<_ChangeNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GymCashColors>()!;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Alterar nome',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18)),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Seu nome',
            labelStyle: TextStyle(color: colors.textSoft),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Digite um nome.';
            if (v.trim().length < 2) return 'Nome muito curto.';
            if (v.trim().length > 60) return 'Use no máximo 60 caracteres.';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: colors.textMuted)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Salvar',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

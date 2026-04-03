// lib/screens/add_contribution_screen.dart
//
// Permite ao usuário registrar ou editar o valor guardado no mês atual
// e definir sua meta individual para aquele grupo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contribution_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/streak_service.dart';
import '../services/achievement_service.dart';
import '../services/theme_service.dart';
import '../widgets/achievement_unlock_toast.dart';
import '../widgets/goal_reached_dialog.dart';

class AddContributionScreen extends StatefulWidget {
  final String groupId;
  final UserModel currentUser;
  final ContributionModel? existing;

  const AddContributionScreen({
    super.key,
    required this.groupId,
    required this.currentUser,
    this.existing,
  });

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  final _amountController = TextEditingController();
  final _goalController   = TextEditingController();
  final _formKey          = GlobalKey<FormState>();
  final _storage          = LocalStorageService();
  bool _saving            = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _amountController.text = widget.existing!.amount.toStringAsFixed(2);
      _goalController.text   = widget.existing!.goal.toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final amount = double.parse(
          _amountController.text.trim().replaceAll(',', '.'));
      final goal   = double.parse(
          _goalController.text.trim().replaceAll(',', '.'));

      final saveResult = await _storage.saveContribution(
        userId:  widget.currentUser.id,
        groupId: widget.groupId,
        amount:  amount,
        goal:    goal,
      );

      if (!mounted) return;

      if (saveResult.goalJustReached) {
        HapticFeedback.heavyImpact();
        await showDialog<void>(
          context:          context,
          barrierDismissible: true,
          barrierColor:     Colors.black.withValues(alpha: 0.65),
          builder: (ctx)    => const GoalReachedDialog(),
        );
      }

      await StreakService(_storage).calculateStreak(widget.currentUser.id);
      final newlyUnlocked = await AchievementService(_storage)
          .checkAndUnlock(widget.currentUser.id);

      if (!mounted) return;
      if (newlyUnlocked.isNotEmpty) {
        AchievementUnlockToast.showSequence(context, newlyUnlocked);
      }
      Navigator.of(context).pop(true);
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível salvar a contribuição. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:         Text(msg),
        behavior:        SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors    = Theme.of(context).extension<GymCashColors>()!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final month     = ContributionModel.currentMonth();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(_isEditing ? 'Editar contribuição' : 'Nova contribuição'),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mês de referência
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:        colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          color: colors.accent, size: 16),
                      const SizedBox(width: 8),
                      Text('Mês de referência: $month',
                          style: TextStyle(
                              color: colors.textSoft, fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Campo: valor guardado
                _FieldLabel(label: 'Valor guardado este mês', colors: colors),
                const SizedBox(height: 8),
                _CurrencyField(
                  controller: _amountController,
                  hint:       '0,00',
                  colors:     colors,
                  onSurface:  onSurface,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o valor';
                    final parsed = double.tryParse(
                        v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) return 'Valor inválido';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo: meta
                _FieldLabel(label: 'Meta individual do mês', colors: colors),
                const SizedBox(height: 8),
                _CurrencyField(
                  controller: _goalController,
                  hint:       '0,00',
                  colors:     colors,
                  onSurface:  onSurface,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe a meta';
                    final parsed = double.tryParse(
                        v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Meta deve ser maior que zero';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botão salvar
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         colors.accent,
                      foregroundColor:         isDark
                          ? Colors.black
                          : Colors.white,
                      disabledBackgroundColor: colors.accent
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color:       isDark ? Colors.black : Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Salvar alterações' : 'Registrar',
                            style: const TextStyle(
                                fontSize:   17,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Label de campo ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.colors});
  final String        label;
  final GymCashColors colors;

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          color:      colors.textSoft,
          fontSize:   13,
          fontWeight: FontWeight.w500));
}

// ── Input numérico ────────────────────────────────────────────────────────────
class _CurrencyField extends StatelessWidget {
  const _CurrencyField({
    required this.controller,
    required this.hint,
    required this.colors,
    required this.onSurface,
    required this.validator,
  });

  final TextEditingController       controller;
  final String                      hint;
  final GymCashColors               colors;
  final Color                       onSurface;
  final String? Function(String?)   validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:      controller,
      keyboardType:    const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      style: TextStyle(
          color: onSurface, fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(color: colors.textMuted),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

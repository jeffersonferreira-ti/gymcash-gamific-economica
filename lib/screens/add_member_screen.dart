// lib/screens/add_member_screen.dart
//
// Tela para adicionar um membro a um grupo existente.
// Retorna o GroupModel atualizado ao fazer pop().

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/local_storage_service.dart';
import '../services/theme_service.dart';

class AddMemberScreen extends StatefulWidget {
  final String groupId;
  const AddMemberScreen({super.key, required this.groupId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _controller = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  final _storage    = LocalStorageService();
  bool _saving      = false;

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updated = await _storage.addMember(
        widget.groupId,
        _controller.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop<GroupModel>(updated);
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível adicionar o membro. Tente novamente.');
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
    _controller.dispose();
    super.dispose();
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
        title: const Text('Adicionar membro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome do membro',
                    style: TextStyle(
                        color:      colors.textSoft,
                        fontSize:   13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),

                TextFormField(
                  controller:         _controller,
                  autofocus:          true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: onSurface, fontSize: 17),
                  decoration: InputDecoration(
                    hintText:  'Ex: João Silva',
                    hintStyle: TextStyle(color: colors.textMuted),
                  ),
                  onFieldSubmitted: (_) => _add(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Digite o nome do membro';
                    }
                    if (v.trim().length < 2) return 'Nome muito curto';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _add,
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
                        : const Text('Adicionar',
                            style: TextStyle(
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

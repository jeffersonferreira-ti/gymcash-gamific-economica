// lib/widgets/rename_group_dialog.dart

import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Exibe campo de nome; retorna o texto salvo (trim) ou `null` se cancelar.
Future<String?> showRenameGroupDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context:      context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => _RenameGroupDialogBody(initialName: initialName),
  );
}

class _RenameGroupDialogBody extends StatefulWidget {
  const _RenameGroupDialogBody({required this.initialName});
  final String initialName;

  @override
  State<_RenameGroupDialogBody> createState() => _RenameGroupDialogBodyState();
}

class _RenameGroupDialogBodyState extends State<_RenameGroupDialogBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
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
    final colors    = Theme.of(context).extension<GymCashColors>()!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Renomear grupo',
        style: TextStyle(
            color:      onSurface,
            fontWeight: FontWeight.w700,
            fontSize:   18),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller:         _controller,
          autofocus:          true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: onSurface, fontSize: 16),
          decoration: InputDecoration(
            labelText:  'Nome do grupo',
            labelStyle: TextStyle(color: colors.textSoft),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.8)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.8)),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Digite um nome para o grupo.';
            }
            if (v.trim().length > 80) {
              return 'Use no máximo 80 caracteres.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: TextStyle(color: colors.textMuted)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Salvar',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Caixa de diálogo estilo iOS com um campo de texto.
/// Retorna o texto digitado, ou `null` se cancelado / vazio.
class TextFieldEx {
  static Future<String?> ask(
    BuildContext context, {
    required String title,
    required String hint,
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController();
    String result = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xF007140F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (v) => result = v,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AColors.glassFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK',
                  style: TextStyle(
                      color: AColors.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (ok != true) return null;
    return result.trim();
  }
}

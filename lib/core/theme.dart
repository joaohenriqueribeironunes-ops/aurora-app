import 'dart:ui';

import 'package:flutter/material.dart';

/// Paleta — verde grafite + liquidez Apple.
class AColors {
  static const bgTop = Color(0xFF0E1F18); // verde grafite
  static const bgBottom = Color(0xFF060D0A);
  static const glassFill = Color(0x14FFFFFF); // 8% branco
  static const glassFillStrong = Color(0x24FFFFFF); // 14%
  static const glassBorder = Color(0x33FFFFFF); // 20%
  static const glassHighlight = Color(0x55FFFFFF); // 33% (borda superior)
  static const textPrimary = Color(0xFFF2FBF7);
  static const textSecondary = Color(0xFF9DBFB1); // verde suave
  static const accent = Color(0xFF46E0A6); // verde-água Apple-adjacente
  static const accentSoft = Color(0x2646E0A6);
  static const danger = Color(0xFFFF6B6B);
}

/// Container de "liquid glass": blur de fundo, preenchimento translúcido,
/// borda de luz no topo e brilho canto superior esquerdo — como o iOS.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool strong;
  final VoidCallback? onTap;

  const Glass({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding = const EdgeInsets.all(18),
    this.strong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: strong
                  ? [AColors.glassFillStrong, AColors.glassFill]
                  : [AColors.glassFill, const Color(0x07FFFFFF)],
            ),
            border: Border(
              top: BorderSide(color: AColors.glassHighlight, width: 0.8),
              left: BorderSide(color: AColors.glassBorder, width: 0.5),
              right: BorderSide(color: AColors.glassBorder, width: 0.5),
              bottom: BorderSide(color: AColors.glassBorder, width: 0.5),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, child: body);
  }
}

/// Botão cápsula estilo iOS com efeito de vidro.
class CapsuleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const CapsuleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AColors.accent;
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: c.withOpacity(0.18),
                border: Border.all(color: c.withOpacity(0.45), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: c),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: c,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de seção, tipografia SF-adjacente.
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? AColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Alias usado em algumas telas.
typedef AppColors = AColors;

TextTheme auroraText() {
  const base = TextStyle(
    fontFamily: 'SFPro',
    color: AColors.textPrimary,
    height: 1.25,
  );
  return TextTheme(
    displaySmall: base.copyWith(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1),
    titleLarge: base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    titleMedium: base.copyWith(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
    bodyLarge: base.copyWith(fontSize: 17, letterSpacing: -0.2),
    bodyMedium: base.copyWith(fontSize: 15, letterSpacing: -0.1),
    bodySmall: TextStyle(color: AColors.textSecondary, fontSize: 13, height: 1.3),
  );
}

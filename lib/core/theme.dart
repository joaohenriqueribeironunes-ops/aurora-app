import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta — verde grafite + liquidez Apple.
class AColors {
  /// Versão visível em toda a UI — fonte única de verdade do rótulo.
  static const version = 'v1.2.0';
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

  /// Sombras ambientais (profundidade dos cartões de vidro).
  static const shadowAmbient = Color(0x88000000);
}

/// Container de "liquid glass": preenchimento translúcido em camadas,
/// junta de luz no topo, sombra ambiente e brilho no canto — como o iOS.
///
/// Performance no Helio G96 (Mali-G57): **sem `BackdropFilter` de verdade**.
/// Blur real re-desfoca a área do cartão a cada frame (o fundo anima atrás),
/// e é o principal assassino de FPS em GPUs médias. Este "fake glass"
/// imita o vidro com preenchimento + bordas de luz — visualmente idêntico
/// sobre o fundo escuro, com custo quase zero.
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
    final body = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: strong
              ? [AColors.glassFillStrong, AColors.glassFill]
              : [AColors.glassFill, const Color(0x07FFFFFF)],
        ),
        border: const Border(
          top: BorderSide(color: AColors.glassHighlight, width: 0.8),
          left: BorderSide(color: AColors.glassBorder, width: 0.5),
          right: BorderSide(color: AColors.glassBorder, width: 0.5),
          bottom: BorderSide(color: AColors.glassBorder, width: 0.5),
        ),
        boxShadow: const [
          // sombra ambiente — dá profundidade ao cartão
          BoxShadow(
            color: AColors.shadowAmbient,
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return body;
    return _Pressable(
      onTap: onTap!,
      child: body,
    );
  }
}

/// Envolvente de toque: escala sutil + haptics no pressionar.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Botão cápsula estilo iOS — preenchimento de vidro, resposta tátil e
/// micro-escala ao pressionar.
class CapsuleButton extends StatefulWidget {
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
  State<CapsuleButton> createState() => _CapsuleButtonState();
}

class _CapsuleButtonState extends State<CapsuleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AColors.accent;
    final enabled = widget.onPressed != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          // Sem BackdropFilter (mesma razão do Glass: custo de GPU em Mali).
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.withOpacity(0.24),
                  c.withOpacity(0.16),
                ],
              ),
              border: Border(
                top: BorderSide(color: c.withOpacity(0.55), width: 0.8),
                bottom: BorderSide(color: c.withOpacity(0.25), width: 0.5),
                left: BorderSide(color: c.withOpacity(0.45), width: 0.6),
                right: BorderSide(color: c.withOpacity(0.45), width: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: c.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 17, color: c),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
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
    );
  }
}

/// Título de seção — sobretítulo com marcador de vidro.
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AColors.accent, Color(0xFF5AA7FF)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: color ?? AColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
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
    displaySmall: base.copyWith(
        fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1),
    titleLarge: base.copyWith(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    titleMedium: base.copyWith(
        fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
    bodyLarge: base.copyWith(fontSize: 17, letterSpacing: -0.2),
    bodyMedium: base.copyWith(fontSize: 15, letterSpacing: -0.1),
    bodySmall: TextStyle(color: AColors.textSecondary, fontSize: 13, height: 1.3),
  );
}

/// Tema Material global afinado — sliders, diálogos, snackbars e divisores
/// no padrão visual Aurora ( usado pelo MaterialApp ).
ThemeData auroraTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AColors.bgBottom,
    textTheme: auroraText(),
    splashFactory: NoSplash.splashFactory,
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08), thickness: 0.6),
    colorScheme: ColorScheme.dark(
      primary: AColors.accent,
      surface: AColors.glassFill,
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      trackShape: RoundedRectSliderTrackShape(),
      showValueIndicator: ShowValueIndicator.never,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xF0091410),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xF00E211A),
      contentTextStyle: const TextStyle(color: AColors.textPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),
  );
}

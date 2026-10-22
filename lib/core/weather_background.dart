import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_state.dart';
import 'theme.dart';

/// Fundo animado por modo de clima:
/// - `sunny`: orbes de luz flutuando
/// - `fog`: fumaça/névoa translúcida passando
/// - `aurora`: fitas de aurora boreal ondulando
class WeatherBackground extends StatefulWidget {
  final WeatherMode mode;
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  /// Relógio de tempo decorrido (segundos, sempre crescente).
  /// Usa Ticker direto — um AnimationController.unbounded().repeat() quebra
  /// no release ("Infinity or NaN toInt", porque os limites são ±∞).
  late final Ticker _ticker;
  late final ValueNotifier<double> _tick;
  double _t = 0;
  late List<_Orb> _orbs;
  late List<_FogBlob> _fogs;
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _tick = ValueNotifier<double>(0);
    _ticker = createTicker((elapsed) {
      _t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      // ~30 fps no fundo (movimento lento, não precisa dos 60) —
      // corta quase metade do custo de GPU/painting do app.
      if ((_t - _tick.value).abs() >= 1 / 30) _tick.value = _t;
    });
    _ticker.start();
    _seed();
  }

  void _seed() {
    _orbs = List.generate(10, (i) {
      return _Orb(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        r: 18 + _rng.nextDouble() * 55,
        speed: 0.010 + _rng.nextDouble() * 0.030,
        phase: _rng.nextDouble() * 6.28,
        hue: 120 + _rng.nextDouble() * 45,
      );
    });
    _fogs = List.generate(6, (i) {
      return _FogBlob(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        r: 130 + _rng.nextDouble() * 180,
        speed: 0.015 + _rng.nextDouble() * 0.035,
        phase: _rng.nextDouble() * 6.28,
      );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        final t = _tick.value;
        return Stack(
          children: [
            // Verde grafite com gradiente suave (vivo, não chapado) —
            // estático (não anima), custo de performance zero.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.55, 1.0],
                  colors: [
                    AColors.bgTop,
                    AColors.bgSolid,
                    AColors.bgBottom,
                  ],
                ),
              ),
            ),
            // Tinte por modo: garante que trocar de clima MUDA a cara do app
            // no primeiro segundo (estático, sem custo por frame).
            Positioned.fill(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(gradient: _modeTint(widget.mode)),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                // isolado: o fundo repinta sozinho sem arrastar a página
                child: CustomPaint(
                  isComplex: true,
                  willChange: true,
                  painter: _WeatherPainter(
                    mode: widget.mode,
                    t: t,
                    orbs: _orbs,
                    fogs: _fogs,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }

  static LinearGradient _modeTint(WeatherMode mode) {
    switch (mode) {
      case WeatherMode.sunny:
        return const LinearGradient(colors: [
          Color(0x00000000),
          Color(0x00000000)
        ]);
      case WeatherMode.fog:
        // véu acinzentado-esverdeado, mais denso em cima
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x2E9DBFB1),
            Color(0x149DBFB1),
            Color(0x0A9DBFB1),
          ],
        );
      case WeatherMode.aurora:
        // noite auroral: azul-verde profundo, mais denso no alto
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x463B6E68),
            Color(0x2A1F4A55),
            Color(0x142A1838),
          ],
        );
    }
  }
}

class _Orb {
  final double x, y, r, speed, phase, hue;
  const _Orb({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.hue,
  });
}

class _FogBlob {
  final double x, y, r, speed, phase;
  const _FogBlob({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

class _WeatherPainter extends CustomPainter {
  final WeatherMode mode;
  final double t;
  final List<_Orb> orbs;
  final List<_FogBlob> fogs;

  _WeatherPainter({
    required this.mode,
    required this.t,
    required this.orbs,
    required this.fogs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case WeatherMode.sunny:
        _paintOrbs(canvas, size);
        break;
      case WeatherMode.fog:
        _paintFog(canvas, size);
        break;
      case WeatherMode.aurora:
        _paintAurora(canvas, size);
        break;
    }
  }

  void _paintOrbs(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (final o in orbs) {
      final dy = math.sin(t * o.speed * 6.28 + o.phase) * 40;
      final dx = ((o.x + t * o.speed / 6) % 1.2) * w - 0.1 * w;
      final center = Offset(dx, o.y * h + dy);
      final rect = Rect.fromCenter(
        center: center,
        width: o.r * 2,
        height: o.r * 2,
      );
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            HSLColor.fromAHSL(0.5, o.hue, 0.55, 0.72).toColor(),
            HSLColor.fromAHSL(0.045, o.hue, 0.65, 0.65).toColor(),
          ],
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // camada 1 — blobs largos e claros (visíveis de longe)
    for (final f in fogs) {
      final dx = ((f.x + t * f.speed / 6) % 1.3) * w - 0.15 * w;
      final dy = f.y * h + math.sin(t * f.speed * 6.28 + f.phase) * 60;
      final center = Offset(dx, dy);
      final rect = Rect.fromCenter(
        center: center,
        width: f.r * 2.6,
        height: f.r * 1.4,
      );
      final paint = Paint()
        ..shader = RadialGradient(
          stops: const [0.0, 0.55, 1.0],
          colors: [
            const Color(0xFFDCEFE7).withOpacity(0.26),
            const Color(0xFFB7D9CB).withOpacity(0.17),
            const Color(0xFFB7D9CB).withOpacity(0.0),
          ],
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }
    // camada 2 — fios de fumaça mais rápidos, contraste com a lenta
    for (int i = 0; i < 4; i++) {
      final ph = t * 0.05 + i * 1.9;
      final y = h * (0.18 + 0.22 * i) + math.sin(ph * 6.28) * 22;
      final x0 = ((ph % 1.2) * 1.6 - 0.5) * w;
      final rect = Rect.fromCenter(
        center: Offset(x0 + w * 0.5, y),
        width: w * 1.1,
        height: 70 + i * 26.0,
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFCBF0E2).withOpacity(0.0),
            const Color(0xFFCBF0E2).withOpacity(0.14),
            const Color(0xFFCBF0E2).withOpacity(0.0),
          ],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(40)),
        paint,
      );
    }
    // véu superior — camada de nuvem sempre presente, agora mais densa
    final full = Offset.zero & size;
    final paintTop = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.4, 1.0],
        colors: [
          const Color(0xFFCBF0E2).withOpacity(0.22),
          const Color(0xFFB7D9CB).withOpacity(0.08),
          const Color(0xFFB7D9CB).withOpacity(0.0),
        ],
      ).createShader(full);
    canvas.drawRect(full, paintTop);
  }

  void _paintAurora(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // brilho geral (glow de nebulosa no alto da tela)
    final glow = Rect.fromCenter(
      center: Offset(w * 0.7, h * 0.16),
      width: w * 1.4,
      height: h * 0.55,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6CE8BF).withOpacity(0.12),
            const Color(0xFF5A7BE8).withOpacity(0.05),
            Colors.transparent,
          ],
        ).createShader(glow),
    );
    for (int band = 0; band < 5; band++) {
      final path = Path()..moveTo(-20, 0);
      final step = w / 24;
      final baseY = h * (0.10 + band * 0.09);
      final amp = 46.0 + band * 18;
      final speed = 0.5 + band * 0.22;
      // do verde-verde-água até o violeta (aurora boreal de verdade)
      final hue = 150.0 + band * 26.0;
      for (int i = 0; i <= 24; i++) {
        final x = i * step;
        final y = baseY +
            math.sin(t * 0.7 * speed + i * 0.55 + band * 1.7) * amp +
            math.sin(t * 1.3 * speed + i * 0.22 + band) * 18;
        path.lineTo(x, y);
      }
      path
        ..lineTo(w + 20, -10)
        ..close();
      // brilho pulsa devagar — a fita acorda e adormece
      final pulse = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 0.6 + band * 1.4));
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.62, 1.0],
          colors: [
            HSLColor.fromAHSL(0.10 * pulse, hue, 0.85, 0.62).toColor(),
            HSLColor.fromAHSL(0.62 * pulse, hue, 0.85, 0.64).toColor(),
            HSLColor.fromAHSL(0.04 * pulse, hue + 20, 0.9, 0.7).toColor(),
          ],
        ).createShader(Rect.fromLTRB(0, 0, w, baseY + amp + 24));
      canvas.drawPath(path, paint);

      // núcleo brilhante da fita (linha fina) — o "fio de luz"
      final core = Path();
      for (int i = 0; i <= 24; i++) {
        final x = i * step;
        final y = baseY +
            math.sin(t * 0.7 * speed + i * 0.55 + band * 1.7) * amp +
            math.sin(t * 1.3 * speed + i * 0.22 + band) * 18 -
            amp * 0.55;
        if (i == 0) core.moveTo(x, y); else core.lineTo(x, y);
      }
      canvas.drawPath(
        core,
        Paint()
          ..blendMode = BlendMode.screen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = HSLColor.fromAHSL(0.55 * pulse, hue + 8, 0.9, 0.78).toColor(),
      );
    }
    // estrelinhas — mais numerosas e cintilantes
    for (int s = 0; s < 90; s++) {
      final x = (s * 97.13) % w;
      final y = (s * 61.7) % h * 0.7;
      final tw = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(t * 2 + s));
      final paint = Paint()..color = Colors.white.withOpacity(tw * 0.55);
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
}

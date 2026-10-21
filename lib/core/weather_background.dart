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
        r: 90 + _rng.nextDouble() * 150,
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
            const ColoredBox(color: AColors.bgBottom),
            // Degradê base verde grafite.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AColors.bgTop, AColors.bgBottom],
                  stops: [0.0, 0.85],
                ),
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
    for (final f in fogs) {
      final dx = ((f.x + t * f.speed / 6) % 1.3) * w - 0.15 * w;
      final dy = f.y * h + math.sin(t * f.speed * 6.28 + f.phase) * 60;
      final center = Offset(dx, dy);
      final rect = Rect.fromCenter(
        center: center,
        width: f.r * 2,
        height: f.r * 1.1,
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }
    // camada superior sutil, sempre presente
    final full = Offset.zero & size;
    final paintTop = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.03),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(full);
    canvas.drawRect(full, paintTop);
  }

  void _paintAurora(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (int band = 0; band < 4; band++) {
      final path = Path()..moveTo(-20, 0);
      final step = w / 24;
      final baseY = h * (0.12 + band * 0.09);
      final amp = 40.0 + band * 22;
      final speed = 0.5 + band * 0.22;
      final hue = 130.0 + band * 24;
      for (int i = 0; i <= 24; i++) {
        final x = i * step;
        final y = baseY +
            math.sin(t * 0.7 * speed + i * 0.55 + band * 1.7) * amp +
            math.sin(t * 1.3 * speed + i * 0.22 + band) * 18;
        path.lineTo(x, y);
      }
      path
        ..lineTo(w + 20, -h * 0.6)
        ..lineTo(-20, -h * 0.6)
        ..close();
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HSLColor.fromAHSL(0.0, hue, 0.8, 0.6).toColor(),
            HSLColor.fromAHSL(0.16, hue, 0.85, 0.65).toColor(),
            HSLColor.fromAHSL(0.0, hue, 0.9, 0.7).toColor(),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, paint);
    }
    // estrelinhas
    for (int s = 0; s < 60; s++) {
      final x = (s * 97.13) % w;
      final y = (s * 61.7) % h * 0.7;
      final tw = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 + s));
      final paint = Paint()..color = Colors.white.withOpacity(tw * 0.35);
      canvas.drawCircle(Offset(x, y), 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
}

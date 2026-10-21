import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Geração de WAV em memória (PCM 16-bit) — 100% local, sem assets.
///
/// Usado por:
/// - Sessão Jogos: tom distinto por cor (resposta sensorial)
/// - Sessão Frisson: ondas binaurais (beta/gama/teta/épsilon/delta/ômega),
///   ruído branco e ruído marrom.
class WavComposer {
  static const int sr = 44100;

  /// Amostra protegida: NaN/Infinity viram silêncio (nunca estoura "toInt").
  /// Retorna double em [-1, 1]; clamp manual porque `double.clamp` devolve num.
  static double _safe(double v) {
    if (!v.isFinite) return 0;
    if (v < -1) return -1;
    if (v > 1) return 1;
    return v;
  }

  static const double tau = math.pi * 2;

  /// Constrói um WAV estéreo a partir de duas funções de amostra.
  static Uint8List composeStereo({
    required double seconds,
    required double Function(double t) left,
    required double Function(double t) right,
    double amplitude = 0.55,
  }) {
    final total = seconds.isFinite ? (sr * seconds).round().clamp(1, sr * 600) : sr;
    final sec = seconds.isFinite ? seconds : 1.0;
    final data = ByteData(44 + total * 4);
    _writeWavHeader(data, total * 4, channels: 2);
    for (int i = 0; i < total; i++) {
      final t = i / sr;
      // fade in/out de 40ms para evitar estalos no loop.
      final edge =
          (t / 0.04).clamp(0.0, 1.0) * ((sec - t) / 0.04).clamp(0.0, 1.0);
      final l = _safe(left(t) * amplitude * edge) * 32767;
      final r = _safe(right(t) * amplitude * edge) * 32767;
      data.setInt16(44 + i * 4 + 0, l.round(), Endian.little);
      data.setInt16(44 + i * 4 + 2, r.round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  /// Mono (usado para os tons do jogo).
  static Uint8List composeMono({
    required double seconds,
    required double Function(double t) sample,
    double amplitude = 0.5,
  }) {
    final total = seconds.isFinite ? (sr * seconds).round().clamp(1, sr * 600) : sr;
    final sec = seconds.isFinite ? seconds : 1.0;
    final data = ByteData(44 + total * 2);
    _writeWavHeader(data, total * 2, channels: 1);
    for (int i = 0; i < total; i++) {
      final t = i / sr;
      // fade in de 10ms / fade out de 90ms — som "soft", sensorialmente calmo.
      final edge =
          (t / 0.01).clamp(0.0, 1.0) * ((sec - t) / 0.12).clamp(0.0, 1.0);
      final s = _safe(sample(t) * amplitude * edge) * 32767;
      data.setInt16(44 + i * 2, s.round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  static void _writeWavHeader(ByteData d, int dataBytes, {required int channels}) {
    final sampleRate = sr;
    final bytesPerSample = 2;
    final blockAlign = channels * bytesPerSample;
    void str(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        d.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    d.setUint32(4, 36 + dataBytes, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little); // PCM
    d.setUint16(22, channels, Endian.little);
    d.setUint32(24, sampleRate, Endian.little);
    d.setUint32(28, sampleRate * blockAlign, Endian.little);
    d.setUint16(32, blockAlign, Endian.little);
    d.setUint16(34, 16, Endian.little);
    str(36, 'data');
    d.setUint32(40, dataBytes, Endian.little);
  }

  /// Tom suave com harmônico secundário (jogo da memória / game over).
  static Uint8List tone({
    required double freq,
    required double seconds,
    double brightness = 0.35,
  }) {
    return composeMono(seconds: seconds, sample: (t) {
      final a = math.sin(tau * freq * t);
      final b = brightness * math.sin(tau * freq * 2.01 * t);
      return a + b;
    });
  }

  /// Onda binaural: senoide portadora com batida f binaural
  /// (esquerdo = base, direito = base + beat).
  static Uint8List binaural({
    required double baseCarrier,
    required double beatHz,
    double seconds = 12,
    double amplitude = 0.35,
  }) {
    return composeStereo(
      seconds: seconds,
      amplitude: amplitude,
      left: (t) => math.sin(tau * baseCarrier * t),
      right: (t) => math.sin(tau * (baseCarrier + beatHz) * t),
    );
  }

  /// Ruído branco (amostras independentes).
  static Uint8List whiteNoise({double seconds = 8, double amplitude = 0.30}) {
    final rng = math.Random(7);
    return composeStereo(
      seconds: seconds,
      amplitude: amplitude,
      left: (_) => rng.nextDouble() * 2 - 1,
      right: (_) => rng.nextDouble() * 2 - 1,
    );
  }

  /// Ruído marrom (random walk), mais grave e abafado.
  static Uint8List brownNoise({double seconds = 10, double amplitude = 0.5}) {
    final rng = math.Random(3);
    double v = 0;
    double clampAt(double x) => x.clamp(-1.0, 1.0);
    return composeStereo(
      seconds: seconds,
      amplitude: amplitude,
      left: (_) {
        v = clampAt(v + (rng.nextDouble() * 2 - 1) * 0.02);
        return v * 3.0;
      },
      right: (_) {
        v = clampAt(v + (rng.nextDouble() * 2 - 1) * 0.02);
        return v * 3.0;
      },
    );
  }
}

/// WAV → arquivo temporário (API estável do just_audio em versão 0.10+
/// não expõe fonte em memória; tocar via AudioSource.file funciona sempre).
class TempWav {
  static Future<String> write(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name.wav');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

/// Bancos de onda da Sessão Frisson.
/// Frequências: "beat" é a diferença entre os ouvidos (onda binaural real).
enum WaveBank {
  gama('Gama', 'Focus intenso · 40 Hz', 220, 40),
  beta('Beta', 'Alerta · 16 Hz', 200, 16),
  alfa('Alfa', 'Calma leve · 10 Hz', 210, 10),
  teta('Teta', 'Meditação · 6 Hz', 180, 6),
  delta('Delta', 'Sono profundo · 3 Hz', 160, 3),
  epsilon('Épsilon', 'Estado excepcional · 0,9 Hz', 150, 0.9),
  omega('Ômega', 'Ancoragem mínima · 0,3 Hz', 140, 0.3),
  branco('Ruído branco', 'Máscara sonora', 0, 0),
  marrom('Ruído marrom', 'Grave · relaxante', 0, 0);

  final String label, subtitle;
  final double carrier; // 0 = ruído
  final double beat;

  const WaveBank(this.label, this.subtitle, this.carrier, this.beat);

  String get key => toString().split('.').last;
}

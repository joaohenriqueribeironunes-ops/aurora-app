import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/audio_engine.dart';
import '../../core/theme.dart';

/// Sessão 3 — Frisson:
/// · Controle de ondas binaurais: Gama, Beta, Alfa, Teta, Delta,
///   Épsilon, Ômega + ruído branco e ruído marrom
/// · Músicas do dispositivo (selecionadas nos arquivos locais)
/// · Modo "Reinterpretação": a música é lida junto das ondas binaurais,
///   mas em turnos alternados — uma acalma conforme a outra ganha força,
///   então nunca ficam tocando ao mesmo tempo.
class FrissonPage extends StatefulWidget {
  const FrissonPage({super.key});

  @override
  State<FrissonPage> createState() => _FrissonPageState();
}

class _FrissonPageState extends State<FrissonPage> {
  WaveBank _bank = WaveBank.teta;
  bool _wavePlaying = false;

  final _wavePlayer = AudioPlayer();
  final _musicPlayer = AudioPlayer();

  // Modo Reinterpretação
  bool _reinterpret = false;
  Timer? _reinterpretTimer;
  double _phase = 0; // 0..1 dentro do ciclo
  static const _cycleSeconds = 24.0;

  double _waveVolume = 0.8;
  double _musicVolume = 1.0;

  String? _currentTitle;
  StreamSubscription? _musicStateSub;

  @override
  void initState() {
    super.initState();
    _musicStateSub = _musicPlayer.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        _musicPlayer.seek(Duration.zero);
      }
      setState(() {});
    });
    _wavePlayer.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reinterpretTimer?.cancel();
    _musicStateSub?.cancel();
    _wavePlayer.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  // ---------------- ondas binaurais ----------------

  Future<void> _stopWave() async {
    setState(() => _wavePlaying = false);
    _reinterpretTimer?.cancel();
    _reinterpret = false;
    try {
      await _wavePlayer.stop();
    } catch (_) {}
  }

  Future<void> _selectBank(WaveBank b) async {
    final wasPlaying = _wavePlaying;
    setState(() => _bank = b);
    if (wasPlaying) await _playWave();
  }

  Future<void> _playWave() async {
    try {
      final source = await _bankSource();
      await _wavePlayer.setAudioSource(source);
      await _wavePlayer.setLoopMode(LoopMode.one);
      await _wavePlayer.play();
      await _wavePlayer.setVolume(_waveVolume);
      setState(() => _wavePlaying = true);
    } catch (_) {}
  }

  /// Cache do WAV por banco — evita regerar a cada play.
  /// WAV vai para arquivo temporário e é tocado via AudioSource.file.
  Future<AudioSource> _bankSource() async {
    final b = _bank;
    if (_cacheBank == b && _cachePath != null) {
      return AudioSource.file(_cachePath!);
    }
    _cacheBank = b;
    Uint8List bytes;
    switch (b) {
      case WaveBank.branco:
        bytes = WavComposer.whiteNoise(seconds: 8);
        break;
      case WaveBank.marrom:
        bytes = WavComposer.brownNoise(seconds: 10);
        break;
      default:
        bytes = WavComposer.binaural(
          baseCarrier: b.carrier,
          beatHz: b.beat,
          seconds: 12,
          amplitude: 0.32,
        );
    }
    _cachePath = await TempWav.write('aurora_wave_${b.key}', bytes);
    return AudioSource.file(_cachePath!);
  }

  WaveBank? _cacheBank;
  String? _cachePath;

  Future<void> _toggleWave() async {
    if (_wavePlaying) {
      await _stopWave();
    } else {
      await _playWave();
    }
  }

  // ---------------- músicas locais ----------------

  Future<void> _pickMusic() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (res == null || res.files.isEmpty) return;
    final paths = res.files.where((f) => f.path != null).map((f) => f.path!).toList();
    try {
      final playlist = ConcatenatingAudioSource(
        children: paths.map((p) => AudioSource.file(p)).toList(),
      );
      await _musicPlayer.setAudioSource(playlist);
      setState(() => _currentTitle = res.files.first.name);
      await _musicPlayer.play();
      await _musicPlayer.setVolume(_musicVolume);
    } catch (_) {}
  }

  // ---------------- reinterpretação ----------------
  // Ciclo: ondas sobem ⟶ música cala ⟶ música sobe ⟶ ondas calam.
  // Ganhos jamais somam mais que ~1: elas alternam, não tocam juntas.

  void _toggleReinterpret() {
    if (_reinterpret) {
      _reinterpretTimer?.cancel();
      setState(() {
        _reinterpret = false;
        _phase = 0;
      });
      _musicVolume = _musicPlayer.volume;
      _waveVolume = _wavePlayer.volume;
      return;
    }
    setState(() => _reinterpret = true);
    const tick = Duration(milliseconds: 200);
    _reinterpretTimer = Timer.periodic(tick, (t) async {
      if (!_reinterpret) {
        t.cancel();
        return;
      }
      setState(() {
        _phase = (_phase + tick.inMilliseconds / 1000 / _cycleSeconds) % 1.0;
      });
      await _applyReinterpretation();
    });
  }

  Future<void> _applyReinterpretation() async {
    // Curva suavizada: alterna a "liderança" entre onda e música.
    final waveLead = (math.sin(_phase * 2 * math.pi) + 1) / 2; // 0..1
    final waveGain = 0.15 + 0.75 * waveLead;
    final musicGain = 0.15 + 0.75 * (1 - waveLead);
    try {
      await _wavePlayer.setVolume(
          _wavePlaying ? waveGain * _waveVolume : 0);
      await _musicPlayer.setVolume(
          _musicPlayer.playing ? musicGain * _musicVolume : 0);
    } catch (_) {}
  }

  Future<void> _startReinterpretMode() async {
    if (!_wavePlaying) await _toggleWave();
    if (!_musicPlayer.playing) {
      await _musicPlayer.play();
      await _musicPlayer.setVolume(_musicVolume);
    }
    _toggleReinterpret();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SectionTitle('Ondas'),
        const SizedBox(height: 10),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WaveBank.values.map((b) {
                  final selected = b == _bank;
                  return GestureDetector(
                    onTap: () => _selectBank(b),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: selected
                            ? AColors.accentSoft
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: selected
                              ? AColors.accent.withOpacity(0.6)
                              : Colors.white.withOpacity(0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        b.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AColors.accent : AColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '${_bank.label} — ${_bank.subtitle}',
                style: TextStyle(color: AColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Volume da onda'),
                  const Spacer(),
                  SizedBox(
                    width: 170,
                    child: Slider(
                      activeColor: AColors.accent,
                      value: _waveVolume,
                      onChanged: (v) async {
                        setState(() => _waveVolume = v);
                        if (!_reinterpret) await _wavePlayer.setVolume(v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: CapsuleButton(
                  label: _wavePlaying ? 'Parar onda' : 'Tocar onda',
                  icon: _wavePlaying
                      ? Icons.stop_rounded
                      : Icons.graphic_eq_rounded,
                  onPressed: _toggleWave,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle('Música local'),
        const SizedBox(height: 10),
        Glass(
          child: Column(
            children: [
              Text(
                _currentTitle ?? 'Nenhuma música selecionada',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _currentTitle == null
                      ? AColors.textSecondary
                      : AColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Volume da música'),
                  const Spacer(),
                  SizedBox(
                    width: 170,
                    child: Slider(
                      activeColor: AColors.accent,
                      value: _musicVolume,
                      onChanged: (v) async {
                        setState(() => _musicVolume = v);
                        if (!_reinterpret) await _musicPlayer.setVolume(v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  CapsuleButton(
                    label: 'Escolher arquivos',
                    icon: Icons.library_music_rounded,
                    onPressed: _pickMusic,
                  ),
                  CapsuleButton(
                    label: _musicPlayer.playing ? 'Pausar' : 'Tocar',
                    icon: _musicPlayer.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: () async {
                      if (_musicPlayer.playing) {
                        await _musicPlayer.pause();
                      } else {
                        await _musicPlayer.play();
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle('Reinterpretação'),
        const SizedBox(height: 10),
        Glass(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A onda binaural escolhida é combinada com a música em turnos: '
                'quando a onda sobe, a música recua — e vice-versa. Elas nunca tocam juntas.',
                style: TextStyle(color: AColors.textSecondary, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _PhaseSlider(phase: _reinterpret ? _phase : 0)),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: CapsuleButton(
                  label: _reinterpret
                      ? 'Sair da reinterpretação'
                      : 'Entrar no modo',
                  icon: Icons.auto_awesome_rounded,
                  color: _reinterpret ? AColors.danger : AColors.accent,
                  onPressed: _reinterpret
                      ? _toggleReinterpret
                      : _currentTitle == null
                          ? null
                          : _startReinterpretMode,
                ),
              ),
              if (_currentTitle == null && !_reinterpret)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: Text(
                    'Selecione primeiro uma música local',
                    style: TextStyle(color: AColors.textSecondary, fontSize: 12),
                  )),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

/// Barra visual do ciclo (onda ⟷ música) do modo reinterpretação.
class _PhaseSlider extends StatelessWidget {
  final double phase;
  const _PhaseSlider({required this.phase});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        height: 10,
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white.withOpacity(0.07),
        ),
        child: Stack(
          children: [
            Positioned(
              left: w * phase,
              top: 0,
              bottom: 0,
              width: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF46E0A6), Color(0xFF5AA7FF)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/audio_engine.dart';
import '../../core/theme.dart';

class _GameColors {
  static const List<Color> all = [
    Color(0xFF46E0A6), // verde — dó
    Color(0xFF5AA7FF), // azul — mi
    Color(0xFFFFC75A), // âmbar — sol
    Color(0xFFFF7B9C), // rosé — dó agudo
  ];
  static const List<double> freqs = [261.6, 329.6, 392.0, 523.3];
}

/// Sessão 2 — Jogos: memória de sequência de cores (estilo Simon).
/// · A sequência cresce 1 cor por rodada
/// · Errou uma cor → Game Over
/// · Cada cor tem um tom próprio — resposta sensorial (ouvir a última sequência)
class JogosPage extends StatefulWidget {
  const JogosPage({super.key});

  @override
  State<JogosPage> createState() => _JogosPageState();
}

class _JogosPageState extends State<JogosPage> {
  final _player = AudioPlayer();
  final _rng = math.Random();

  List<int> _sequence = [];
  int _round = 0;
  bool _watching = false;
  int? _flashIndex;
  int _score = 0;
  int _best = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _best = context.read<AppState>().simonBest;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _sequence = [];
      _score = 0;
      _round = 0;
      _gameOver = false;
    });
    _nextRound();
  }

  Future<void> _nextRound() async {
    _sequence.add(_rng.nextInt(4));
    _round = 0;
    _watching = true;
    await _playSequence();
  }

  Future<void> _playSequence() async {
    for (final tone in _sequence) {
      if (!mounted) return;
      await _playTone(tone);
      await Future.delayed(const Duration(milliseconds: 120));
    }
    if (!mounted) return;
    setState(() => _watching = false);
  }

  /// Som da cor — cada cor tem frequência própria (resposta sensorial).
  Future<void> _playTone(int index, {bool isGameOver = false}) async {
    if (!mounted) return;
    setState(() => _flashIndex = index);
    final wav = isGameOver
        ? WavComposer.tone(freq: 110, seconds: 0.9, brightness: 0)
        : WavComposer.tone(freq: _GameColors.freqs[index], seconds: 0.45);
    try {
      await _player.setAudioSource(ByteArrayAudioSource(wav));
      await _player.play();
    } catch (_) {
      // erro de audio não pausa o jogo
    }
    await Future.delayed(isGameOver
        ? const Duration(milliseconds: 700)
        : const Duration(milliseconds: 320));
    if (!mounted) return;
    setState(() => _flashIndex = null);
  }

  Future<void> _tap(int index) async {
    if (_watching || _sequence.isEmpty || _gameOver) return;
    if (index != _sequence[_round]) {
      await _gameOverNow();
      return;
    }
    await _playTone(index);
    _round++;
    if (_round >= _sequence.length) {
      _score = _sequence.length;
      if (_score > _best) {
        _best = _score;
        if (mounted) {
          await context.read<AppState>().setSimonBest(_score);
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
      await _nextRound();
    }
  }

  Future<void> _gameOverNow() async {
    setState(() => _gameOver = true);
    await _playTone(0, isGameOver: true);
  }

  @override
  Widget build(BuildContext context) {
    final playing = _sequence.isNotEmpty && !_gameOver;
    final watching = _watching;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Glass(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rodada',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('$_score',
                      style:
                          const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Recorde',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('$_best',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: _SimonBoard(
            colors: _GameColors.all,
            flashIndex: _flashIndex,
            watching: watching,
            gameOver: _gameOver,
            onTap: _tap,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            _gameOver
                ? 'Game Over — você errou a cor 😶‍🌫️'
                : watching
                    ? 'Observe a sequência…'
                    : playing
                        ? 'Sua vez! Repita a sequência'
                        : 'Toque em iniciar',
            style: TextStyle(
              color: _gameOver ? AppColors.danger : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: CapsuleButton(
            label: _gameOver || _sequence.isEmpty ? 'Iniciar' : 'Reiniciar',
            icon: Icons.play_arrow_rounded,
            color: _gameOver ? AppColors.danger : null,
            onPressed: _start,
          ),
        ),
        const SizedBox(height: 16),
        const Glass(
          child: Text(
            'Cada cor tem o próprio som: verde dó · azul mi · âmbar sol · rosé dó agudo.\n'
            'Ouça a cor — a memória ganha um segundo caminho: este padrão visual e este padrão sonoro.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// Tabuleiro Simon: 4 pétalas de vidro dentro de um aro circular.
class _SimonBoard extends StatelessWidget {
  final List<Color> colors;
  final int? flashIndex;
  final bool watching;
  final bool gameOver;
  final void Function(int) onTap;

  const _SimonBoard({
    required this.colors,
    required this.flashIndex,
    required this.watching,
    required this.gameOver,
    required this.onTap,
  });

  Widget petal(int i) {
    final active = flashIndex == i;
    final c = colors[i];
    final radius = BorderRadius.only(
      topLeft: i == 0 ? const Radius.circular(52) : const Radius.circular(14),
      topRight: i == 1 ? const Radius.circular(52) : const Radius.circular(14),
      bottomLeft: i == 2 ? const Radius.circular(52) : const Radius.circular(14),
      bottomRight: i == 3 ? const Radius.circular(52) : const Radius.circular(14),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: watching || gameOver ? null : () => onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: active ? c.withOpacity(0.55) : c.withOpacity(0.10),
          border: Border.all(
            color: active ? c : c.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 44, spreadRadius: 6)]
              : const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
            ),
          ),
          Container(
            width: 258,
            height: 258,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgBottom.withOpacity(0.6),
            ),
          ),
          SizedBox(
            width: 250,
            height: 250,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, petal),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../main.dart' show CrashStore;

/// Sessão 5 — Ajustes:
/// · Painel de design: escolha do clima (Ensolarado / Névoa / Aurora)
///   sobre o fundo verde grafite com liquid glass
/// · Gerência das fontes de notícias confiáveis da Sessão Foco
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  static IconData _iconOf(WeatherMode m) {
    switch (m) {
      case WeatherMode.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherMode.fog:
        return Icons.cloud_queue_rounded;
      case WeatherMode.aurora:
        return Icons.auto_awesome_rounded;
    }
  }

  static String _subOf(WeatherMode m) {
    switch (m) {
      case WeatherMode.sunny:
        return 'Orbes de luz flutuando';
      case WeatherMode.fog:
        return 'Fumaça passando alto';
      case WeatherMode.aurora:
        return 'Aurora boreal ondulando';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SectionTitle('Clima do app'),
        const SizedBox(height: 10),
        Row(
          children:
              WeatherMode.values.map((m) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: m == WeatherMode.aurora ? 0 : 10),
                child: Glass(
                  onTap: () => state.setWeather(m),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  radius: 22,
                  child: Column(
                    children: [
                      Icon(
                        _iconOf(m),
                        size: 30,
                        color: state.weather == m
                            ? AColors.accent
                            : AColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: state.weather == m
                              ? AColors.accent
                              : AColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subOf(m),
                        style: TextStyle(
                            color: AColors.textSecondary, fontSize: 10.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        const SizedBox(height: 24),

        SectionTitle('Suas marcas com o app'),
        const SizedBox(height: 10),
        Glass(
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Recorde no jogo da memória',
                      style: TextStyle(color: AColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  Text('${state.simonBest} rodadas',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AColors.accent)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Compromissos salvos',
                      style: TextStyle(color: AColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  Text('${state.commitments.length}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Artigos na biblioteca',
                      style: TextStyle(color: AColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  Text('${state.articles.length}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Glass(
          child: Text(
            'Aurora · feito para cérebros divergentes (TEA/TDAH)\n'
            'Tudo roda no seu aparelho: compromissos disparam alarmes no '
            'horário, música vem do seu dispositivo, e a IA das ideias '
            'processa tudo na hora, sem acessar nuvem.',
            style: TextStyle(color: AColors.textSecondary, fontSize: 12.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 17,
                    color: CrashStore.failures > 0 ? AColors.danger : AColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CrashStore.failures > 0
                        ? '${AColors.version} · ${CrashStore.failures} falhas registradas'
                        : '${AColors.version} · app saudável — nenhum erro registrado',
                    style: TextStyle(
                        color: CrashStore.failures > 0
                            ? AColors.danger
                            : AColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CrashStore.last,
                style: const TextStyle(
                    color: AColors.textSecondary, fontSize: 11.5, height: 1.4),
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

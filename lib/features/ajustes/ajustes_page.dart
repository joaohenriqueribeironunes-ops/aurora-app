import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../main.dart' show CrashStore;
import '../../widgets/fields.dart';

/// Sessão 5 — Ajustes:
/// · Painel de design: escolha do clima (Ensolarado / Névoa / Aurora)
///   sobre o fundo verde grafite com liquid glass
/// · Gerência das fontes de notícias confiáveis da Sessão Foco
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  static final _presets = [
    NewsSource(name: 'Ciência — Agência FAPESP', url: 'https://agencia.fapesp.br/feed/'),
    NewsSource(name: 'Ciência — Olhar Digital', url: 'https://olhardigital.com.br/feed/'),
    NewsSource(name: 'Mundo — BBC Brasil', url: 'https://feeds.bbci.co.uk/portuguese/rss.xml'),
    NewsSource(name: 'Tech — TecMundo', url: 'https://www.tecmundo.com.br/feed'),
  ];

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

        SectionTitle('Fontes de notícias'),
        const SizedBox(height: 10),
        if (state.sources.isEmpty)
          const Glass(
            child: Text(
              'Nenhuma fonte ainda. Adicione feeds RSS de sites confiáveis '
              'para a sessão Foco montar o resumo do seu dia.',
              style: TextStyle(color: AColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
          )
        else
          ...state.sources.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Glass(
                  child: Row(
                    children: [
                      const Icon(Icons.rss_feed, color: AColors.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(s.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AColors.textSecondary,
                                    fontSize: 11.5)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 17, color: AColors.textSecondary),
                        onPressed: () =>
                            context.read<AppState>().removeSource(s.url),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            CapsuleButton(
              label: 'Adicionar fonte',
              icon: Icons.add_rounded,
              onPressed: () => _addSource(context),
            ),
            ..._presets
                .where((p) =>
                    !state.sources.any((s) => s.url == p.url))
                .map(
                  (p) => CapsuleButton(
                    label: '+ ${p.name.split('—').last.trim()}',
                    icon: Icons.rss_feed_rounded,
                    color: AColors.textSecondary,
                    onPressed: () =>
                        context.read<AppState>().addSource(p),
                  ),
                ),
          ],
        ),
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
            'Tudo roda no seu aparelho: resumo de notícias é consumido quando '
            'você puxa para atualizar, música vem do seu dispositivo, e a IA '
            'das ideias processa tudo na hora, sem acessar nuvem.',
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
                        ? '${CrashStore.failures} falhas registradas'
                        : 'app saudável — nenhum erro registrado',
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

  Future<void> _addSource(BuildContext context) async {
    final name =
        await TextFieldEx.ask(context, title: 'Fonte', hint: 'Nome (BBC, G1…)');
    if (name == null || name.trim().isEmpty) return;
    final url = await TextFieldEx.ask(
      context,
      title: 'Feed RSS',
      hint: 'URL completa do feed',
      keyboardType: TextInputType.url,
    );
    if (url == null || url.trim().isEmpty) return;
    await context
        .read<AppState>()
        .addSource(NewsSource(name: name.trim(), url: url.trim()));
  }
}

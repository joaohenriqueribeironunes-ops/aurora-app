import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../main.dart' show notifications;
import '../../widgets/fields.dart';
import 'news_service.dart';

/// Sessão 1 — Foco:
/// · Resumo das manchetes das fontes confiáveis do usuário
/// · Próximos compromissos, com notificações e lembretes agendados
class FocoPage extends StatefulWidget {
  const FocoPage({super.key});

  @override
  State<FocoPage> createState() => _FocoPageState();
}

class _FocoPageState extends State<FocoPage> {
  bool _loadingNews = false;
  List<NewsItem> _news = [];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _news = state.cachedNews;
    if (_news.isEmpty) _refreshNews();
  }

  Future<void> _refreshNews() async {
    final state = context.read<AppState>();
    if (state.sources.isEmpty) return;
    setState(() => _loadingNews = true);
    final items = await NewsService.fetchAll(state.sources);
    if (!mounted) return;
    setState(() {
      _news = items;
      _loadingNews = false;
    });
    await state.cacheNews(items);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final upcoming = state.upcomingCommitments;
    final passed = state.commitments
        .where((c) => c.dateTime.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: AColors.accent,
      backgroundColor: AColors.bgTop,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ---------- Resumo de notícias ----------
          SectionTitle('Resumo de hoje — Boas fontes'),
          const SizedBox(height: 10),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.sources.isEmpty)
                  const Text(
                    'Você ainda não escolheu fontes de notícias.\n'
                    'Adicione sites confiáveis na Sessão Ajustes.',
                    style: TextStyle(color: AColors.textSecondary, fontSize: 14),
                  )
                else if (_loadingNews && _news.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else ...[
                  _NewsDigest(news: _news),
                  if (_loadingNews)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AColors.accent, strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------- Compromissos ----------
          SectionTitle('Próximos compromissos'),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const _Glassless()
          else
            ...upcoming.take(4).map((c) => _CommitmentCard(commitment: c)),
          if (passed.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionTitle('Passados'),
            const SizedBox(height: 10),
            ...passed.take(2).map((c) => _CommitmentCard(commitment: c, dimmed: true)),
          ],
          const SizedBox(height: 16),
          Center(
            child: CapsuleButton(
              label: 'Novo compromisso',
              icon: Icons.event,
              onPressed: () => _newCommitment(context),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _newCommitment(BuildContext context) async {
    final title = await TextFieldEx.ask(
      context,
      title: 'Novo compromisso',
      hint: 'O que precisa lembrar?',
    );
    if (title == null || title.trim().isEmpty) return;

    final now = DateTime.now();
    DateTime? chosen = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    chosen ??= now;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    final location = DateTime(
      chosen.year,
      chosen.month,
      chosen.day,
      time.hour,
      time.minute,
    );
    final notes = await TextFieldEx.ask(
      context,
      title: 'Notas',
      hint: 'Endereço, detalhes… (opcional)',
      optional: true,
    );

    final c = Commitment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      notes: notes ?? '',
      dateTime: location,
      notify: true,
    );
    final state = context.read<AppState>();
    await state.addCommitment(c);
    await notifications.schedule(
      'Compromisso: ${c.title}',
      c.notes.isEmpty ? 'Lembrete do Aurora' : c.notes,
      c.dateTime,
    );
    await notifications.now(
      'Lembrete agendado ✓',
      '${DateFormat('dd/MM HH:mm').format(c.dateTime)} — ${c.title}',
    );
  }
}

class _Glassless extends StatelessWidget {
  const _Glassless();

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Row(
        children: const [
          Icon(Icons.event_available, color: AColors.accent, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sem compromissos à frente. Adicione um para receber lembrete no horário.',
              style: TextStyle(color: AColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Digest das notícias — resumo curto dos assuntos de hoje.
class _NewsDigest extends StatelessWidget {
  final List<NewsItem> news;
  const _NewsDigest({required this.news});

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return const Text(
        'Sem manchetes agora (provavelmente sem rede). Tente puxar para atualizar.',
        style: TextStyle(color: AColors.textSecondary, fontSize: 14),
      );
    }
    // Agrupa por fonte: 1 linha assunto + 1 linha fonte/detalhe
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in news.take(12))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${n.source}'
                  '${n.summary.isEmpty ? '' : ' · ${n.summary}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Cartão de compromisso com botão de re-lembrar agora.
String _two(int n) => n.toString().padLeft(2, '0');

class _CommitmentCard extends StatelessWidget {
  final Commitment commitment;
  final bool dimmed;

  const _CommitmentCard({required this.commitment, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final c = commitment;
    const weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    final wd = weekdays[c.dateTime.weekday - 1];
    final df = '${wd} · ${_two(c.dateTime.day)}/${_two(c.dateTime.month)} · '
        '${_two(c.dateTime.hour)}:${_two(c.dateTime.minute)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: dimmed ? Colors.grey : AColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: dimmed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.schedule_send,
                      size: 18, color: AColors.accent),
                  tooltip: 'Lembrar agora',
                  onPressed: () {
                    notifications.now(
                      'Compromisso: ${c.title}',
                      df.format(c.dateTime),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              df.format(c.dateTime),
              style: TextStyle(
                color: dimmed ? Colors.grey : AColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (c.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  c.notes,
                  style: TextStyle(color: AColors.textSecondary, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

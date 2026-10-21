import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../main.dart' show notifications;
import '../../widgets/fields.dart';

/// Sessão 1 — Foco: agenda de compromissos com **alarme de verdade** —
/// no horário, o lembrete abre em tela cheia e toca sonoridade de alarme
/// do sistema (AlarmManager.setAlarmClock — nunca silenciado pela bateria).
class FocoPage extends StatefulWidget {
  const FocoPage({super.key});

  @override
  State<FocoPage> createState() => _FocoPageState();
}

class _FocoPageState extends State<FocoPage> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final upcoming = state.upcomingCommitments;
    final passed = state.commitments
        .where((c) => c.dateTime.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SectionTitle('Agenda — compromissos'),
        const SizedBox(height: 4),
        Text(
          'No horário, o lembrete abre em tela cheia e toca como alarme '
          '(toca mesmo com a tela apagada; não é silenciado pela bateria).',
          style: TextStyle(color: AColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _Glassless()
        else
          ...upcoming.take(6).map((c) => _CommitmentCard(commitment: c)),
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
      'Alarme agendado ✓',
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
              'Sem compromissos à frente. Um compromisso agendado toca '
              'como alarme na hora, com tela cheia.',
              style: TextStyle(color: AColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão de compromisso — lembrar agora / excluir (cancela o alarme).
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
                  dimmed ? Icons.event_busy : Icons.alarm,
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
                if (!dimmed)
                  IconButton(
                    icon: const Icon(Icons.schedule_send,
                        size: 18, color: AColors.accent),
                    tooltip: 'Lembrar agora',
                    onPressed: () {
                      notifications.now(
                        'Compromisso: ${c.title}',
                        df,
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AColors.textSecondary),
                  tooltip: 'Excluir',
                  onPressed: () async {
                    await notifications.cancelFor(c.title);
                    await context.read<AppState>().removeCommitment(c.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              df,
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

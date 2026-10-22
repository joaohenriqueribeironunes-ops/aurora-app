import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_state.dart';

/// IA 100% local — roda junto com o processador, sem rede e sem nuvem.
///
/// Modela o pensamento divergente/ramificado típico do TEA/TDAH:
/// a partir de um tópico e dos artigos baixados, extrai os eixos
/// temáticos e ramifica o raciocínio por várias frentes de uma vez
/// (analogia, contra-ponto, ponte entre ideias, implicação de longo
/// prazo, questionamento de premissa, aplicação concreta).
class DivergentEngine {
  static const _stopwords = {
    'a', 'o', 'as', 'os', 'um', 'uma', 'de', 'do', 'da', 'dos', 'das', 'em',
    'no', 'na', 'nos', 'nas', 'por', 'para', 'com', 'e', 'ou', 'que', 'se',
    'ao', 'à', 'é', 'são', 'foi', 'ser', 'sua', 'seu', 'suas', 'seus', 'como',
    'mais', 'mas', 'the', 'of', 'to', 'and', 'in', 'is', 'was', 'for', 'on',
    'with', 'by', 'at', 'it', 'this', 'be', 'not', 'you', 'or',
    'an', 'from', 'sobre', 'após', 'entre', 'sem', 'antes', 'até',
  };

  /// Extrai palavras mais frequentes como eixos temáticos.
  static List<String> _axes(List<String> texts) {
    final counts = <String, int>{};
    for (final raw in texts) {
      final words = raw
          .toLowerCase()
          .replaceAll(RegExp(r'[^\wá-úà-ùâ-ûã-õç\s-]'), ' ')
          .split(RegExp(r'\s+'));
      for (final w in words) {
        if (w.length < 3 || _stopwords.contains(w) || int.tryParse(w) != null) {
          continue;
        }
        counts[w] = (counts[w] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  /// Frases-chave: primeiros parágrafos resumidos.
  static List<String> _seedSentences(List<String> texts) {
    final out = <String>[];
    for (final t in texts) {
      final parts = t.split(RegExp(r'(?<=[.!?])\s+'));
      final pick =
          parts.where((p) => p.length > 40 && p.length < 260).take(3).toList();
      out.addAll(pick);
    }
    return out;
  }

  /// Gera as ramificações de pensamento — determinístico (sem "alucinação"
  /// aleatória: cada vez produz o mesmo conjunto para o mesmo material,
  /// porque é derivado do texto).
  static List<IdeaBranch> branches({
    required String topic,
    required List<Article> articles,
  }) {
    final texts = <String>[topic];
    texts.addAll(articles.map((a) => a.content));
    texts.addAll(articles.map((a) => a.title));
    final axes = _axes(texts);
    final seeds = _seedSentences(texts);
    String axis(int i) => axes.isEmpty ? topic.toLowerCase() : axes[i % axes.length];
    String seed(int i) => seeds.isEmpty ? topic : seeds[i % seeds.length];

    final rand = math.Random(topic.hashCode + articles.length);
    final branchesList = <IdeaBranch>[];

    // Ramo 1 — Analogia (pensamento lateral típico do TEA)
    branchesList.add(IdeaBranch(
      type: 'Analogia visual',
      icon: Icons.bubble_chart,
      text: 'Se "${axis(0)}" fosse uma máquina, '
          'que peça estaria faltando? E se "${axis(1)}" fosse um mapa, '
          'que caminho antigo ninguém contorna mais?',
    ));

    // Ramo 2 — Contra-ponto
    branchesList.add(IdeaBranch(
      type: 'Contra-ponto',
      icon: Icons.swap_vert_circle,
      text: '"${topic}" — e se o oposto também fizer sentido? '
          'O que aconteceria se "${axis(1)}" deixasse de ser critério? '
          'Quem ganharia, quem perderia?',
    ));

    // Ramo 3 — Ponte entre duas ideias do material
    branchesList.add(IdeaBranch(
      type: 'Ponte entre ideias',
      icon: Icons.route,
      text: '${axis(0)} ↔ ${axis(2)}: existe elo escondido aqui? '
          'O texto diz que "${_trim(seed(0))}". E se o elo fosse o contrário — '
          '"${axis(0)}" causa "${axis(2)}" apenas indiretamente?',
    ));

    // Ramo 4 — Implicação em cadeia (hiperfoco como aliado)
    branchesList.add(IdeaBranch(
      type: 'Implicação em cadeia',
      icon: Icons.account_tree,
      text: 'Se "${axis(0)}" for verdade, então "${axis(1)}" muda de papel, '
          'o que faz "${axis(2)}" virar o novo problema central. '
          'A cadeia termina em uma conversa sobre: ${axis(3)}.',
    ));

    // Ramo 5 — Pergunta de abertura (para agenda do dia)
    branchesList.add(IdeaBranch(
      type: 'Pergunta de abertura',
      icon: Icons.help_center,
      text: 'Pergunta para investigar hoje: '
          '"${axis(0)} e ${axis(1)} — qual me diz mais sobre ${_firstWords(topic, 4)}?"',
    ));

    // Ramo 6 — Detalhe que quase ninguém nota
    final snip = seed(rand.nextInt(math.max(1, seeds.length)));
    branchesList.add(IdeaBranch(
      type: 'Detalhe de flecha',
      icon: Icons.low_priority,
      text: 'Detalhe discreto do material: "${_trim(snip)}". '
          'O que essa frase pressupõe antes mesmo de "${axis(0)}" aparecer?',
    ));

    return branchesList;
  }

  static String _trim(String s) {
    s = s.trim();
    return s.length > 130 ? '${s.substring(0, 130)}…' : s;
  }

  static String _firstWords(String s, int n) {
    final p = s.split(' ');
    return p.take(n).join(' ');
  }

  /// "Contexto capturado" — chips com os eixos do material.
  static List<String> axesChips(String topic, List<Article> articles) {
    final texts = <String>[topic];
    texts.addAll(articles.map((a) => a.content));
    return _axes(texts).take(8).toList();
  }

  /// Processa UM artigo baixado por URL: extrai eixos e frases-chave e
  /// gera ramificações específicas daquele material — rodando 100% local.
  static List<IdeaBranch> articleBranches(Article article) {
    final texts = <String>[article.title, article.content];
    final axes = _axes(texts);
    final seeds = _seedSentences([article.content]);
    String axis(int i) =>
        axes.isEmpty ? article.title.toLowerCase() : axes[i % axes.length];
    String seed(int i) =>
        seeds.isEmpty ? article.title : seeds[i % seeds.length];

    return [
      IdeaBranch(
        type: 'Fio central',
        icon: Icons.center_focus_weak,
        text: 'O artigo gira em torno de "${axis(0)}", puxado por "${axis(1)}" '
            'e "${axis(2)}". Se resumisse numa pergunta continua: '
            '"como ${axis(0)} muda quando ${axis(1)} entra na equação?"',
      ),
      IdeaBranch(
        type: 'Analogia do material',
        icon: Icons.bubble_chart,
        text: 'Imagina "${axis(0)}" como um sistema de água: '
            '"${axis(1)}" seria o fluxo, "${axis(2)}" a pressão. '
            'Onde o texto deixa vazar água sem ninguém notar?',
      ),
      IdeaBranch(
        type: 'Contra-ponto do texto',
        icon: Icons.swap_vert_circle,
        text: 'O material assume que "${axis(0)}" vem antes de "${axis(1)}". '
            'E se for o contrário? O trecho "${_trim(seed(0))}" '
            'sobreviveria a essa inversão?',
      ),
      IdeaBranch(
        type: 'Implicação em cadeia',
        icon: Icons.account_tree,
        text: 'Se "${axis(0)}" se confirmar, "${axis(1)}" deixa de ser detalhe '
            'e vira o novo foco — e "${axis(2)}" precisa ser relido do zero. '
            'A última da cadeia costuma ser: ${axis(3)}.',
      ),
      IdeaBranch(
        type: 'Detalhe de flecha',
        icon: Icons.low_priority,
        text: 'Frase discreta que abre portas: "${_trim(seed(1))}". '
            'O que ela pressupõe sobre "${axis(0)}" antes de ser dito?',
      ),
    ];
  }
}

class IdeaBranch {
  final String type;
  final IconData icon;
  final String text;

  const IdeaBranch({required this.type, required this.icon, required this.text});
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import 'divergent_engine.dart';

/// Sessão 4 — Ideias:
/// · IA local (divergente/ramificada, estilo TEA/TDAH) que lê o material
///   baixado e gera ramificações de pensamento — tudo no processador
/// · Baixar artigos/sites de dentro do app, sem sair dele
/// · Leitor dos artigos já baixados
class IdeiasPage extends StatefulWidget {
  const IdeiasPage({super.key});

  @override
  State<IdeiasPage> createState() => _IdeiasPageState();
}

class _IdeiasPageState extends State<IdeiasPage> {
  final _topicController = TextEditingController();
  bool _genBusy = false;
  List<IdeaBranch> _branches = [];
  bool _downloading = false;
  Article? _reading;

  /// Ramificações da IA do ÚLTIMO artigo baixado (processo automático).
  List<IdeaBranch>? _justProcessed;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  // ---------------- baixar artigo ----------------

  Future<void> _download() async {
    final state = context.read<AppState>();
    // URL primeiro — é pelo URL que o artigo entra.
    final url = await _ask('Baixar e processar', 'URL do site/artigo',
        keyboard: TextInputType.url);
    if (url == null || url.trim().isEmpty) return;

    setState(() => _downloading = true);
    final content = await _fetchText(url.trim());
    if (!mounted) return;
    setState(() => _downloading = false);
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não consegui baixar essa página. '
                'Verifique a URL e a rede.'),
            backgroundColor: Color(0xFF0E1F18),
          ),
        );
      }
      return;
    }

    final titleEntered = await _ask('Página baixada ✓',
        'Nome para guardar (deixe vazio p/ automático)');
    final auto = _firstSent(_firstLine(content), 60);
    final title = (titleEntered == null || titleEntered.trim().isEmpty)
        ? auto
        : titleEntered.trim();

    final article = Article(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      url: url.trim(),
      content: content,
      savedAt: DateTime.now(),
    );
    await state.addArticle(article);

    // ---------- IA divergente processa AGORA, 100% local ----------
    final processed = DivergentEngine.articleBranches(article);
    article.branches = processed.length;
    await state.updateArticle(article);
    if (!mounted) return;
    setState(() => _justProcessed = processed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Processado pela IA local: ${processed.length} ramificações '
              'prontas ✓'),
          backgroundColor: const Color(0xFF0E1F18),
        ),
      );
    }
  }

  static String _firstLine(String s) {
    for (final line in s.split('\n')) {
      if (line.trim().length > 12) return line.trim();
    }
    return s.split('\n').first.trim();
  }

  Future<String?> _ask(String title, String hint,
      {TextInputType? keyboard}) {
    return _Dialogs.ask(context, title: title, hint: hint, keyboard: keyboard);
  }

  /// Baixa a página e extrai o texto principal (sem depender de lib de HTML).
  Future<String> _fetchText(String url) async {
    try {
      final resp = await http
          .get(Uri.parse(url),
              headers: {'User-Agent': 'AuroraApp/1.0'})
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return '';
      var body = String.fromCharCodes(resp.bodyBytes);
      // extrai seções de texto prováveis
      final matcher = RegExp(
          r'<(article|main|p|div|h1|h2|h3|li)[^>]*>(.*?)</\1>',
          multiLine: true,
          dotAll: true);
      final buffer = StringBuffer();
      for (final m in matcher.allMatches(body)) {
        final inner = m.group(2) ?? '';
        final txt = _htmlToText(inner);
        if (txt.length > 40) {
          buffer.writeln(txt);
        }
      }
      var text = buffer.toString();
      if (text.length < 80) text = _htmlToText(body);
      return text;
    } catch (_) {
      return '';
    }
  }

  static String _htmlToText(String html) {
    return html
        .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();
  }

  static String _firstSent(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  // ---------------- IA ----------------

  Future<void> _generate() async {
    final state = context.read<AppState>();
    final topic = _topicController.text.trim();
    setState(() => _genBusy = true);
    // Assíncrono mas 100% local — deixa a UI respirar um frame.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _branches = DivergentEngine.branches(topic: topic, articles: state.articles);
      _genBusy = false;
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (_reading != null) return _reader(_reading!);

    Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // ---------- processamento automático do último download ----------
        if (_justProcessed != null) ...[
          Glass(
            strong: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'IA local: artigo processado — '
                        '${_justProcessed!.length} ramificações',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AColors.textSecondary),
                      onPressed: () => setState(() => _justProcessed = null),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final b in _justProcessed!)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _Branch(b: b),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        // ---------- IA divergente ----------
        Glass(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Ramificações divergentes'),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.psychology, color: AColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'IA no processador — lê seus artigos e ramifica o pensamento',
                      style: TextStyle(color: AColors.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topicController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Sobre o que pensar em cima? Um assunto, uma dúvida…',
                  hintStyle: const TextStyle(
                      color: AColors.textSecondary, fontSize: 13.5),
                  filled: true,
                  fillColor: AColors.glassFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    DivergentEngine.axesChips(_topicController.text, state.articles)
                        .map((a) => _Chip(label: a))
                        .toList(),
              ),
              const SizedBox(height: 14),
              Center(
                child: CapsuleButton(
                  label: _genBusy ? 'Pensando…' : 'Ramificar',
                  icon: Icons.account_tree,
                  onPressed: _genBusy ? null : _generate,
                ),
              ),
              const SizedBox(height: 6),
              for (final b in _branches)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _Branch(b: b),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---------- biblioteca ----------
        SectionTitle('Biblioteca offline'),
        const SizedBox(height: 10),
        if (state.articles.isEmpty)
          const Glass(
            child: Text(
              'Nenhum artigo baixado ainda. Baixe páginas para a IA ler e '
              'ramificar junto com você.',
              style: TextStyle(color: AColors.textSecondary, fontSize: 14, height: 1.4),
            ),
          )
        else
          ...state.articles.reversed.map((a) => _ArticleCard(
                article: a,
                onOpen: () => setState(() => _reading = a),
                onRemove: () async => state.removeArticle(a.id),
              )),
        const SizedBox(height: 16),
        Center(
          child: CapsuleButton(
            label: _downloading ? 'Baixando…' : 'Baixar artigo/site',
            icon: Icons.download_rounded,
            onPressed: _downloading ? null : _download,
          ),
        ),
      ],
    );

    return body;
  }

  Widget _reader(Article a) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _reading = null),
                  icon: const Icon(Icons.chevron_left,
                      color: AColors.textSecondary, size: 26),
                ),
                Expanded(
                  child: Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Glass(
              padding: const EdgeInsets.all(22),
              child: Text(
                a.content,
                style:
                    const TextStyle(fontSize: 16, height: 1.75, letterSpacing: -0.1),
              ),
            ),
            // Ramificações da IA divergente local sobre este material.
            const SizedBox(height: 14),
            SectionTitle('Ramificações da IA local'),
            const SizedBox(height: 10),
            ...DivergentEngine.articleBranches(a)
                .map((b) => _Branch(b: b)),
            if (a.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Fonte original: ${a.url}',
                  style: TextStyle(color: AColors.textSecondary, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- widgets ----------------

class _Branch extends StatelessWidget {
  final IdeaBranch b;
  const _Branch({required this.b});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AColors.glassFill,
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(b.icon, color: AColors.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                b.type.toUpperCase(),
                style: const TextStyle(
                  color: AColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(b.text, style: const TextStyle(fontSize: 14.5, height: 1.5)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AColors.accentSoft,
        border: Border.all(color: AColors.accent.withOpacity(0.35), width: 0.6),
      ),
      child: Text(label, style: const TextStyle(color: AColors.accent, fontSize: 12)),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _ArticleCard({
    required this.article,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        onTap: onOpen,
        child: Row(
          children: [
            const Icon(Icons.article, color: AColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    article.branches > 0
                        ? 'IA local · ${article.branches} ramificações · '
                            '${article.content.length ~/ 1000}k car.'
                        : '${article.content.length ~/ 1000}k caracteres · salvo',
                    style: TextStyle(color: AColors.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: AColors.textSecondary),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini diálogo local para a Sessão Ideias.
class _Dialogs {
  static Future<String?> ask(
    BuildContext context, {
    required String title,
    required String hint,
    TextInputType? keyboard,
  }) async {
    final controller = TextEditingController();
    String capture = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xF007140F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboard,
          textInputAction: TextInputAction.done,
          onChanged: (v) => capture = v,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AColors.textSecondary, fontSize: 13.5),
            filled: true,
            fillColor: AColors.glassFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ok',
                style: TextStyle(color: AColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    return capture.trim();
  }
}

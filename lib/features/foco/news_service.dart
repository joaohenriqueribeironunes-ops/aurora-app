import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_state.dart';

/// Busca resumos de notícias dos feeds RSS confiáveis do usuário.
/// Parsing por regex para funcionar sem dependência de XML.
class NewsService {
  static const _timeout = Duration(seconds: 12);

  static Future<List<NewsItem>> fetchAll(List<NewsSource> sources) async {
    final results = <NewsItem>[];
    final futures =
        sources.map((s) => _fetchSource(s).catchError((_) => <NewsItem>[]));
    final groups = await Future.wait(futures);
    for (final g in groups) {
      results.addAll(g);
    }
    return results;
  }

  static Future<List<NewsItem>> _fetchSource(NewsSource source) async {
    try {
      final resp = await http
          .get(
            Uri.parse(source.url),
            headers: {'User-Agent': 'AuroraApp/1.0 (rss reader)'},
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final body = utf8.decode(resp.bodyBytes, allowMalformed: true);
      final items = <NewsItem>[];

      // RSS 2.0 / Atom
      final blocks = _split(body, ['<item', '<entry']);
      int take = 0;
      for (final block in blocks) {
        if (take >= 6) break; // 6 manchetes por fonte — resumo enxuto
        final title = _clean(_firstTag(block, ['title']));
        final link = _firstTag(block, ['link']);
        var desc = _clean(_firstTag(block, ['description', 'summary', 'content']));
        if (title.isEmpty) continue;
        if (desc.length > 220) desc = desc.substring(0, 220).trimLeft() + '…';
        items.add(NewsItem(
          source: source.name,
          title: title,
          summary: desc,
          link: link.isEmpty ? source.url : link,
        ));
        take++;
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Divide o XML em blocos de `<item>` ou `<entry>`.
  static List<String> _split(String body, List<String> openers) {
    final out = <String>[];
    for (final opener in openers) {
      var idx = body.indexOf('<$opener');
      while (idx >= 0) {
        final end = _findClose(body, opener, idx);
        if (end < 0) break;
        out.add(body.substring(idx, end));
        idx = body.indexOf('<$opener', end);
      }
      if (out.isNotEmpty) break;
    }
    return out;
  }

  static int _findClose(String body, String tag, int from) {
    // `<item ...>` fecha com `</item>`; `<item/>` é vazio.
    final selfClosed = RegExp('<$tag[^>]*/>').hasMatch(body.substring(from, from + 400));
    if (selfClosed) return body.indexOf('/>', from) + 2;
    return body.indexOf('</$tag>', from);
  }

  static String _firstTag(String block, List<String> tags) {
    for (final tag in tags) {
      // `<link ...>url</link>` ou `<link href="url" />`
      final m = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true).firstMatch(block);
      if (m != null) return _stripTags(m.group(1)!);
      final mh = RegExp('<$tag[^>]*href="([^"]+)"').firstMatch(block);
      if (mh != null) return mh.group(1)!;
    }
    return '';
  }

  static String _stripTags(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trimLeft()
      .trimRight();

  static String _clean(String s) {
    var out = s;
    final entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&aacute;': 'á', '&eacute;': 'é', '&iacute;': 'í',
      '&oacute;': 'ó', '&uacute;': 'ú', '&acirc;': 'â',
      '&ecirc;': 'ê', '&ocirc;': 'ô', '&atilde;': 'ã',
      '&otilde;': 'õ', '&ccedil;': 'ç',
    };
    entities.forEach((k, v) => out = out.replaceAll(k, v));
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

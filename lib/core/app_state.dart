import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modos de "clima" do app (Sessão Ajustes).
enum WeatherMode { sunny, fog, aurora }

extension WeatherModeX on WeatherMode {
  String get label {
    switch (this) {
      case WeatherMode.sunny:
        return 'Ensolarado';
      case WeatherMode.fog:
        return 'Névoa';
      case WeatherMode.aurora:
        return 'Aurora';
    }
  }

  String get emoji {
    switch (this) {
      case WeatherMode.sunny:
        return '☀️';
      case WeatherMode.fog:
        return '🌫️';
      case WeatherMode.aurora:
        return '🌌';
    }
  }

  String get key => toString().split('.').last;
}

/// Compromisso (Sessão Foco) — com alarme agendado.
class Commitment {
  final String id;
  String title;
  String notes;
  DateTime dateTime;
  bool notify;

  Commitment({
    required this.id,
    required this.title,
    required this.notes,
    required this.dateTime,
    required this.notify,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'dateTime': dateTime.toIso8601String(),
        'notify': notify,
      };

  factory Commitment.fromMap(Map<String, dynamic> m) => Commitment(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: (m['notes'] ?? '') as String,
        dateTime: DateTime.parse(m['dateTime'] as String),
        notify: (m['notify'] ?? true) as bool,
      );
}

/// Artigo / página baixado dentro do app (Sessão Ideias).
class Article {
  final String id;
  final String title;
  final String url;
  final String content; // texto puro
  final DateTime savedAt;

  Article({
    required this.id,
    required this.title,
    required this.url,
    required this.content,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'content': content,
        'savedAt': savedAt.toIso8601String(),
      };

  factory Article.fromMap(Map<String, dynamic> m) => Article(
        id: m['id'] as String,
        title: m['title'] as String,
        url: (m['url'] ?? '') as String,
        content: (m['content'] ?? '') as String,
        savedAt: DateTime.parse(m['savedAt'] as String),
      );
}

/// Estado global do app, persistido em shared_preferences como JSON.
class AppState extends ChangeNotifier {
  static const _kWeather = 'aurora.weather';
  static const _kCommitments = 'aurora.commitments';
  static const _kArticles = 'aurora.articles';
  static const _kSimonBest = 'aurora.simonBest';

  WeatherMode weather = WeatherMode.sunny;
  List<Commitment> commitments = [];
  List<Article> articles = [];
  int simonBest = 0;

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    weather = WeatherMode.values.firstWhere(
      (m) => m.key == (_prefs.getString(_kWeather) ?? 'sunny'),
      orElse: () => WeatherMode.sunny,
    );
    commitments = _decode(_prefs.getString(_kCommitments))
        .map((m) => Commitment.fromMap(m))
        .toList();
    articles = _decode(_prefs.getString(_kArticles))
        .map((m) => Article.fromMap(m))
        .toList();
    simonBest = _prefs.getInt(_kSimonBest) ?? 0;
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(String key, Object value) async {
    if (value is String) await _prefs.setString(key, value);
    if (value is int) await _prefs.setInt(key, value);
    notifyListeners();
  }

  // ---------- Clima ----------
  Future<void> setWeather(WeatherMode mode) async {
    weather = mode;
    await _save(_kWeather, mode.key);
  }

  // ---------- Compromissos ----------
  Future<void> addCommitment(Commitment c) async {
    commitments.add(c);
    _sortCommitments();
    await _save(
        _kCommitments, jsonEncode(commitments.map((e) => e.toMap()).toList()));
  }

  Future<void> updateCommitment(Commitment c) async {
    await _save(
        _kCommitments, jsonEncode(commitments.map((e) => e.toMap()).toList()));
  }

  Future<void> removeCommitment(String id) async {
    commitments.removeWhere((e) => e.id == id);
    await _save(
        _kCommitments, jsonEncode(commitments.map((e) => e.toMap()).toList()));
  }

  void _sortCommitments() {
    commitments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Commitment> get upcomingCommitments {
    final now = DateTime.now();
    final upcoming =
        commitments.where((c) => c.dateTime.isAfter(now)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming;
  }

  // ---------- Artigos ----------
  Future<void> addArticle(Article a) async {
    articles.add(a);
    await _save(_kArticles, jsonEncode(articles.map((e) => e.toMap()).toList()));
  }

  Future<void> removeArticle(String id) async {
    articles.removeWhere((e) => e.id == id);
    await _save(_kArticles, jsonEncode(articles.map((e) => e.toMap()).toList()));
  }

  // ---------- Jogo ----------
  Future<void> setSimonBest(int score) async {
    if (score <= simonBest) return;
    simonBest = score;
    await _save(_kSimonBest, score);
  }
}

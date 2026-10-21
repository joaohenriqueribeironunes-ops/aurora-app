import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'core/app_state.dart';
import 'core/theme.dart';
import 'core/weather_background.dart';
import 'features/ajustes/ajustes_page.dart';
import 'features/foco/foco_page.dart';
import 'features/frisson/frisson_page.dart';
import 'features/ideias/ideias_page.dart';
import 'features/jogos/jogos_page.dart';

/// Serviço global de notificações (compromissos da Sessão Foco).
final NotificationsService notifications = NotificationsService();

/// Registro do último erro — aparece na Sessão Ajustes (diagnóstico).
class CrashStore {
  static String last = 'Nenhum erro registrado';
  static int failures = 0;
}

void main() {
  // Erros globais nunca derrubam o app — são registrados e exibidos nos Ajustes.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      CrashStore.failures++;
      CrashStore.last = '${details.exception}\n${details.stack ?? ''}';
      debugPrint('Aurora: erro de UI: ${details.exception}');
    };

    tzdata.initializeTimeZones();

    final state = AppState();
    try {
      await state.load();
    } catch (e) {
      CrashStore.failures++;
      CrashStore.last = 'state.load: $e';
    }

    runApp(
      ChangeNotifierProvider.value(
        value: state,
        child: const AuroraApp(),
      ),
    );

    try {
      await notifications.init();
    } catch (e) {
      CrashStore.failures++;
      CrashStore.last = 'notificações: $e';
    }
  }, (error, stack) {
    CrashStore.failures++;
    CrashStore.last = '$error';
    debugPrint('Aurora: erro de runtime: $error');
  });
}

class NotificationsService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Notificação imediata.
  Future<void> now(String title, String body) async {
    await _plugin.show(
      body.hashCode & 0x7fffffff,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aurora_foco',
          'Compromissos — Foco',
          channelDescription: 'Lembretes dos compromissos da sessão Foco',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF46E0A6),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Lembrete agendado no horário do compromisso.
  Future<void> schedule(String title, String body, DateTime when) async {
    final plugin = _plugin;
    await plugin.zonedSchedule(
      title.hashCode & 0x7fffffff,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aurora_foco',
          'Compromissos — Foco',
          channelDescription: 'Lembretes dos compromissos da sessão Foco',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      builder: (context, widget) {
        // Em vez de tela preta/vermelha, mostra um diagnóstico de vidro.
        ErrorWidget.builder = (details) {
          CrashStore.failures++;
          CrashStore.last = '${details.exception}\n${details.stack ?? ''}';
          return Container(
            color: const Color(0xFF060D0A),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro na interface — detalhes na Sessão Ajustes.\n'
              '> ${details.exception}',
              style: const TextStyle(
                  color: Color(0xFF46E0A6), fontFamily: 'monospace'),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: auroraText(),
        colorScheme: ColorScheme.dark(
          primary: AColors.accent,
          surface: AColors.glassFill,
        ),
      ),
      home: const HomeRoot(),
    );
  }
}

/// 5 sessões — barra inferior de vidro estilo iOS.
class HomeRoot extends StatefulWidget {
  const HomeRoot({super.key});

  @override
  State<HomeRoot> createState() => _HomeRootState();
}

class _HomeRootState extends State<HomeRoot> {
  int _tab = 0;

  static const _titles = ['Foco', 'Jogos', 'Frisson', 'Ideias', 'Ajustes'];
  static const _icons = [
    Icons.center_focus_strong,
    Icons.sports_esports,
    Icons.waves,
    Icons.psychology,
    Icons.tune,
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final pages = <Widget>[
      const FocoPage(),
      const JogosPage(),
      const FrissonPage(),
      const IdeiasPage(),
      const AjustesPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: WeatherBackground(
        mode: state.weather,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _titles[_tab],
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AColors.glassFillStrong,
                  border: Border.all(color: AColors.glassBorder, width: 0.6),
                ),
                child: Row(
                  children: List.generate(5, (i) {
                    final selected = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: selected
                                ? AColors.accentSoft
                                : Colors.transparent,
                          ),
                          margin: const EdgeInsets.all(7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _icons[i],
                                size: 21,
                                color: selected
                                    ? AColors.accent
                                    : AColors.textSecondary,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _titles[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AColors.accent
                                      : AColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

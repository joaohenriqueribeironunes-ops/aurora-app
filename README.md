# Aurora 🌌

App para pessoas neurodivergentes (TEA e TDAH), com 5 sessões:

| Sessão | O que tem |
|---|---|
| **Foco** | Resumo das manchetes das suas fontes confiáveis (feeds RSS que você escolhe) + próximos compromissos, com **notify/lembrete agendado por horário** na barra do sistema. |
| **Jogos** | Jogo da memória de sequência de cores (estilo Simon). Cada cor tem **um tom musical próprio** (resposta sensorial). Errou uma cor → **Game Over**. Recorde salvo. |
| **Frisson** | Controle de ondas binaurais: **Gama, Beta, Alfa, Teta, Delta, Épsilon, Ômega**, ruído **branco** e **marrom** (gerados localmente, em tempo real, no processador). Reproductor de **músicas do seu dispositivo** (escolha nos arquivos) + modo **Reinterpretação**: a música e a onda são alternadas com crossfade — uma recua enquanto a outra sobe, então **nunca ficam tocando juntas**. |
| **Ideias** | IA 100% local que roda no processador: lê o material baixado e gera **ramificações de pensamento divergente** (analogia, contra-ponto, ponte entre ideias, implicação em cadeia…). Inclui baixar artigos/sites de dentro do app e leitor offline dos textos. |
| **Ajustes** | Painel de design: **clima do app** — *Ensolarado* (orbes de luz flutuando), *Névoa* (fumaça passando) e *Aurora* (aurora boreal animada) — tudo sobre fundo **verde grafite** com efeito **liquid glass** estilo Apple. Também gerencia as fontes de notícias. |

Todas as telas usam o mesmo sistema visual: fundo verde grafite, cartões de
vidro com blur (BackdropFilter), borda de luz superior e tipografia suave.

---

## Como compilar (Android)

O projeto fica nesta pasta. Como o Flutter não estava instalado quando o
código foi escrito, você precisa gerar as pastas nativas do Android uma vez:

### 1. Instale o Flutter SDK (uma vez só)
- Baixe em https://docs.flutter.dev/get-started/install/windows
- Extraia em `C:\flutter`
- Adicione `C:\flutter\bin` ao PATH
- Rode `flutter doctor` e siga o que ele indicar (Android Studio + SDK do Android)

### 2. Gere as pastas nativas e instale os pacotes
Abra o terminal **dentro desta pasta** (aurora/) e rode:

```bat
flutter create . --platforms=android --org br.aurora --project-name aurora_app
flutter pub get
```

(`flutter create .` mantém todo o código `lib/` que já está aqui — ele só cria
as pastas `android/` e `ios/` que faltam.)

### 3. Permissões — edite `android/app/src/main/AndroidManifest.xml`
Deixe dentro do `<manifest>` (logo antes de `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

E dentro de `<activity>` … `</activity>` + `</application>`, **depois** do
bloco da activity, adicione para os lembretes exatos funcionarem:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"/>
```

### 4. Rodar / gerar APK

```bat
flutter run                  (no aparelho ligado em modo depuração)
flutter build apk --release  (gera build\app\outputs\flutter-apk\app-release.apk)
```

---

## Notas técnicas

- Os sons do jogo e as ondas binaurais são **sintetizados em Dart**
  (`lib/core/audio_engine.dart`) e tocados via `just_audio` — não há áudio
 ALLOC externo nenhum.
- A "IA" das ideias (`lib/features/ideias/divergent_engine.dart`) roda
  inteiramente no dispositivo: extrai eixos temáticos (TF) e monta as
  ramificações determinísticas a partir do texto — sem rede, sem nuvem.
- Suas escolhas (fontes, compromissos, artigos, clima, recorde) ficam
  persistidas localmente (`shared_preferences`).

# Aurora v1.4.0

> **Confirme a versão no app:** abra o Aurora e veja o chip verde no canto direito do título — deve dizer **v1.4.0**. Se outro número aparecer, o aparelho rodou um APK antigo.

## ❌ Campo de notícias removido
- A Sessão Foco agora é só **agenda de compromissos** — sem manchetes, sem feeds, sem configuração de fontes (removido também dos Ajustes).
- Menos poluição visual, menos espera por internet.

## ⏰ Compromissos como ALARME de verdade
- No horário, o lembrete abre **em tela cheia** (mesmo com o telefone travado) e toca com som e vibração máximos.
- Usa o modo `AlarmManager.setAlarmClock` do Android — o sistema trata como **despertador**: não é adiado pelo modo Doze nem pela otimização de bateria.
- Canal de notificação novo: "Alarme — Compromissos" (importância máxima).
- Cada compromisso agora tem botão **excluir** — que cancela o alarme agendado também.
- Ao agendar, o app pede a permissão de "alarmes e lembretes exatos" (Android 12+).

## 💚 Mantido das versões anteriores
- Verde grafite sólido na base; névoa e aurora visíveis como decoração de fundo.
- Vidro leve (sem blur real) — performance para 60 FPS em GPUs médias.
- Chip de versão visível no topo de todas as telas.

## 📥 Instalação
1. **Desinstale** o Aurora atual do celular.
2. Apague APKs antigos da pasta Downloads.
3. Instale **aurora-v1.4.0-arm64.apk** (20–21 MB) — aparelhos modernos. Se falhar, use **aurora-v1.4.0-universal.apk** (55 MB).
4. Se o Play Protect reclamar, toque em **"Instalar mesmo assim"**.
5. Abra o app → chip verde deve dizer **v1.4.0**.

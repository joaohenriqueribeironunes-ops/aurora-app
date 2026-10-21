# Aurora v1.5.0

> **Confira o chip verde no canto direito do título: deve dizer `v1.5.0`.**

## 🎨 Fundo com vida de novo
- O verde grafite sólido (que ficou "morto") voltou a ter um **gradiente suave** — escuro no topo passando pelo grafite até um verde quase preto embaixo. Vivo, mas sem exagero.

## 🧊 Vidro mais SUTIL
- Brilho das bordas reduzido a menos da metade, preenchimento e sombra mais discretos — acabamento sóbrio, não chamativo.

## ⏰ Alarme: agora dá para TESTAR
- Sessão Foco ganhou o botão **"Testar alarme (10 s)"**: agenda um alarme de verdade para daqui 10 segundos. toque, trave a tela do celular e espere — a tela cheia deve abrir com som e vibração no máximo.
- **Importante no primeiro teste:** se o Android pedir *Alarmes e lembretes* / *Aparecer por cima de outros apps*, conceda. Sem isso a tela cheia não abre.

## Mantido
- Foco = agenda de compromissos (sem notícias); excluir compromisso cancela o alarme.
- Compromissos disparam como despertador (AlarmManager.setAlarmClock) — imunes à otimização de bateria.
- Fundo a 30 fps + vidro sem blur — leve para GPUs médias.

## 📥 Instalação
Desinstale o Aurora atual, apague APKs antigos de Downloads, baixe **aurora-v1.5.0-arm64.apk** e, se o Play Protect perguntar, "Instalar mesmo assim".

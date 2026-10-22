# Aurora v1.5.1

> **Confira o chip verde: `v1.5.1`.**

## ⏰ Alarme: canal recriado de verdade
- **Bug silencioso corrigido:** se você atualizou o app por cima de uma versão antiga (sem desinstalar), o Android **não atualiza** as configurações de um canal de notificação já criado — o alarme continuava se comportando como aviso comum (sem tela cheia, sem som máximo). O canal do alarme agora tem **ID novo** e o antigo é apagado no abrir.
- **Guarde a instrução** para o teste na Sessão Foco: toque em **"Testar alarme (10 s)"**, trave a tela — se o Android pedir **"Alarmes e lembretes"** e **"Aparecer por cima de outros apps"**, conceda ambas.

## ❌ CI no GitHub consertado
- O workflow "Build APK" que aparecia **❌ em vermelho** em todas as releases agora funciona: os APKs `arm64` + `universal` são reconstruídos no GitHub com o nome certo da tag (nada de asset duplicado/confuso).

## Mantido
- Fundo com gradiente vivo + vidro sutil (v1.5.0).
- Foco = agenda de compromissos; excluir cancela o alarme agendado.

## 📥 Instalação
Desinstale o Aurora atual (importante para o canal novo valer), baixe **aurora-v1.5.1-arm64.apk**. Play Protect perguntou? "Instalar mesmo assim".

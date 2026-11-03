# TRIBES OF FIRE — INSTALADOR WINDOWS, SISTEMA MULTILÍNGUE E COMUNICAÇÃO MULTIPLAYER COMPLETA

## MISSÃO

Você é o engenheiro principal responsável por desenvolver, integrar, testar e finalizar três sistemas essenciais do jogo **Tribes of Fire**, criado por **felipealx**:

1. Instalador profissional para Windows, simples e multilíngue.
2. Sistema completo de idiomas dentro do jogo.
3. Sistema avançado de comunicação multiplayer por texto e voz.

O projeto está sendo desenvolvido em Godot 4.

**NÃO RECOMECE O JOGO DO ZERO.**

Preserve todas as funcionalidades existentes, incluindo sobrevivência, clima, construção, combate, tribos, multiplayer, inventário, animais e configurações gráficas.

Leia o repositório inteiro antes de modificar qualquer coisa.

Utilize a arquitetura existente e implemente os novos recursos de maneira modular.

Não entregue apenas demonstrações, botões falsos ou código sem integração.

---

# 1. INSTALADOR PROFISSIONAL PARA WINDOWS

Criar um instalador real para Windows, com extensão `.exe`, que permita instalar Tribes of Fire facilmente, sem precisar instalar Godot, Python, compiladores ou outras ferramentas de desenvolvimento.

O instalador deverá ser simples, rápido, visualmente agradável e confiável.

Nome sugerido:

**TribesOfFire-Setup-1.0.0.exe**

Utilizar preferencialmente Inno Setup ou outra solução madura de instalação para Windows.

## 1.1 Seleção de idioma do instalador

Ao abrir o instalador, mostrar uma janela para escolher o idioma.

Idiomas obrigatórios:

- Português (Brasil).
- English (United States).
- Español.
- Français.
- Deutsch.
- 日本語.

Traduzir corretamente:

- Boas-vindas.
- Termos de licença, se aplicáveis.
- Seleção de pasta.
- Opções de instalação.
- Criação de atalhos.
- Progresso.
- Conclusão.
- Mensagens de erro.
- Desinstalação.

Utilizar traduções nativas do instalador quando disponíveis e completar manualmente as mensagens necessárias.

Não utilizar traduções fictícias ou incompletas.

## 1.2 Etapas da instalação

O processo deverá ser:

**Etapa 1:** Escolher idioma.

**Etapa 2:** Tela de boas-vindas com nome e ícone do jogo.

**Etapa 3:** Escolher pasta de instalação.

**Etapa 4:** Escolher opções adicionais.

**Etapa 5:** Instalar.

**Etapa 6:** Finalizar, com opção de iniciar o jogo imediatamente.

Não exigir configurações técnicas desnecessárias.

## 1.3 Atalho na área de trabalho

**OBRIGATÓRIO: criar um atalho funcional na área de trabalho do Windows.**

O atalho deverá ter:

- Nome: Tribes of Fire.
- Ícone oficial do jogo.
- Destino correto do executável.
- Diretório de trabalho correto.

Adicionar também um atalho no menu Iniciar.

A criação do atalho da área de trabalho deverá estar marcada por padrão, mas poderá ser desativada pelo usuário.

Não criar atalhos quebrados.

## 1.4 Instalação e desinstalação

O instalador deverá:

- Detectar instalações anteriores.
- Permitir atualizar o jogo.
- Evitar duplicação desnecessária de arquivos.
- Criar desinstalador.
- Aparecer na lista de aplicativos instalados do Windows.
- Remover corretamente os arquivos do programa durante a desinstalação.
- Preservar salvamentos e configurações pessoais por padrão.
- Informar claramente se algum dado pessoal será removido.
- Evitar solicitar privilégios de administrador quando não forem necessários.

Preferir instalação por usuário em uma pasta apropriada, sem exigir elevação.

## 1.5 Interface

Criar uma aparência limpa e profissional, com:

- Nome Tribes of Fire.
- Ícone oficial.
- Tipografia legível.
- Layout organizado.
- Indicador de progresso.
- Mensagens claras.

Evitar excesso de etapas e janelas.

---

# 2. SISTEMA MULTILÍNGUE DENTRO DO JOGO

O idioma do instalador e o idioma do jogo são configurações independentes.

**Na primeira vez que o jogador abrir Tribes of Fire, deverá aparecer uma tela para escolher o idioma do jogo.**

Essa tela deverá aparecer antes do menu principal.

## 2.1 Idiomas disponíveis

Implementar inicialmente:

- Português (Brasil).
- Inglês.
- Espanhol.
- Francês.
- Alemão.
- Japonês.

Permitir adicionar outros idiomas futuramente.

Utilizar o sistema de internacionalização do Godot 4.

## 2.2 Primeira inicialização

Exibir uma tela com o título:

**Selecione seu idioma / Select your language**

Mostrar os idiomas em suas próprias línguas:

- Português (Brasil).
- English.
- Español.
- Français.
- Deutsch.
- 日本語.

Ao escolher, aplicar o idioma imediatamente.

Salvar a preferência localmente.

Não perguntar novamente em todas as inicializações.

## 2.3 Alteração posterior

Criar:

**Configurações → Idioma**

Permitir mudar o idioma a qualquer momento.

Sempre que tecnicamente possível, aplicar as traduções sem reiniciar o jogo.

## 2.4 Conteúdo traduzido

Traduzir:

- Menu principal.
- Configurações.
- Inventário.
- Fabricação.
- Construção.
- Tribos.
- Combate.
- Itens.
- Equipamentos.
- Mensagens de sobrevivência.
- Notificações.
- Mensagens de erro.
- Chat e configurações de voz.
- Tutoriais.
- Telas de carregamento.
- Informações de servidores.

Não traduzir automaticamente mensagens escritas pelos próprios jogadores.

Os nomes personalizados de jogadores, tribos e servidores devem ser preservados.

## 2.5 Qualidade

Utilizar fontes com suporte aos caracteres necessários, inclusive japonês.

Testar textos longos, caracteres especiais e diferentes resoluções.

Evitar textos cortados e botões pequenos demais.

---

# 3. SISTEMA DE CHAT DE TEXTO

Criar um sistema completo de chat multiplayer integrado ao jogo.

O chat deverá ser acessível durante a partida, sem interromper desnecessariamente a jogabilidade.

## 3.1 Canais obrigatórios

Implementar os seguintes canais:

### Chat global

Permite conversar com todos os jogadores conectados ao servidor.

### Chat local

Permite conversar somente com jogadores próximos.

O alcance deverá ser configurável pelo servidor.

### Chat da tribo

Permite conversar com todos os integrantes da mesma tribo, independentemente da distância.

### Chat privado

Permite enviar mensagens diretamente para um jogador específico.

### Chat de grupo

Permite criar conversas com vários jogadores selecionados.

O grupo não precisa necessariamente ser uma tribo.

### Chat entre tribos

Permite criar canais de comunicação entre duas ou mais tribos.

Exemplo: os líderes de duas tribos poderão abrir uma conversa diplomática.

O canal poderá ser restrito aos líderes ou permitir outros membros autorizados.

### Chat de aliança

Caso o sistema de alianças esteja implementado, permitir comunicação entre tribos aliadas.

Não criar dependências quebradas caso alianças ainda não estejam disponíveis.

## 3.2 Interface

Criar uma janela de chat com:

- Histórico de mensagens.
- Campo de digitação.
- Seleção de canal.
- Nome do remetente.
- Horário da mensagem.
- Indicador de mensagens não lidas.
- Notificações discretas.
- Rolagem.
- Opção de minimizar.
- Opção de ocultar.
- Ajuste de transparência.

Adicionar abas ou filtros para separar os canais.

Permitir selecionar jogadores diretamente na lista de participantes.

## 3.3 Comandos rápidos

Implementar comandos como:

`/global mensagem`

`/local mensagem`

`/tribo mensagem`

`/msg jogador mensagem`

`/grupo mensagem`

`/ajuda`

Permitir nomes de jogadores com espaços utilizando seleção por interface ou identificadores estáveis.

## 3.4 Segurança

O servidor deverá validar:

- Identidade do remetente.
- Permissão de acesso ao canal.
- Limite de tamanho das mensagens.
- Frequência de envio.
- Destinatários.
- Participação em grupos e tribos.

Adicionar proteção contra spam e mensagens excessivas.

Não confiar em identificadores enviados diretamente pelos clientes sem validação.

---

# 4. SISTEMA COMPLETO DE CHAT DE VOZ

**ESTE É UM DOS RECURSOS MAIS IMPORTANTES.**

Implementar comunicação por voz em tempo real entre jogadores conectados ao mesmo servidor.

Não criar apenas uma interface com botão de microfone.

O áudio precisa ser realmente capturado, transmitido, recebido e reproduzido.

## 4.1 Voz por proximidade

O canal principal de voz deverá funcionar por proximidade.

**Somente jogadores próximos poderão ouvir quem estiver falando.**

Conforme a distância aumenta, o volume diminui gradualmente.

Quando o jogador estiver distante demais, a voz ficará completamente inaudível.

### Configuração inicial de alcance

Usar como referência:

| Distância entre jogadores | Comportamento |
|---|---|
| 0–5 metros | Voz clara |
| 5–15 metros | Volume reduzindo |
| 15–25 metros | Voz baixa |
| 25–30 metros | Voz muito baixa |
| Acima de 30 metros | Inaudível |

Esses valores são sugestões iniciais e devem ser ajustáveis pelo servidor.

A atenuação deverá ser contínua, sem mudanças bruscas de volume.

Utilizar posições tridimensionais reais dos personagens.

A direção da voz também deverá ser percebida em estéreo quando o sistema de áudio permitir.

## 4.2 Áudio espacial 3D

Implementar reprodução posicional utilizando recursos apropriados do Godot.

A voz deverá parecer vir da posição do personagem que está falando.

Exemplos:

- Jogador à esquerda: voz percebida à esquerda.
- Jogador à direita: voz percebida à direita.
- Jogador distante: voz mais baixa.
- Jogador fora do alcance: nenhuma voz audível.

Evitar cortes bruscos e alterações artificiais de volume.

## 4.3 Canais adicionais de voz

Além do canal de proximidade, implementar:

**Voz privada:** conversa direta entre dois jogadores.

**Voz de grupo:** conversa entre vários jogadores selecionados.

**Voz da tribo:** comunicação entre integrantes da mesma tribo, independentemente da distância, como um canal de rádio virtual.

**Voz de aliança:** comunicação entre tribos aliadas, quando autorizada.

**Voz diplomática:** canal temporário entre líderes ou representantes de tribos diferentes.

### Regra fundamental

A voz de proximidade deve sempre respeitar a distância.

Os canais privados, de grupo e de tribo poderão funcionar independentemente da distância, mas deverão ser apresentados claramente como canais remotos, distintos da comunicação local.

Não permitir que um jogador escute conversas privadas ou de tribos das quais não participa.

O jogador deverá poder escolher seu canal ativo.

## 4.4 Push-to-Talk

Implementar dois modos:

- Pressionar para falar.
- Microfone aberto com detecção de voz.

O modo padrão será **Push-to-Talk**.

Tecla padrão sugerida: `V`.

Permitir remapear a tecla.

Adicionar indicador visual quando o microfone estiver transmitindo.

## 4.5 Configurações de áudio

Criar:

**Configurações → Áudio → Chat de voz**

Opções:

- Ativar/desativar chat de voz.
- Selecionar microfone.
- Selecionar saída de áudio, quando suportado.
- Volume das vozes.
- Sensibilidade do microfone.
- Testar microfone.
- Push-to-Talk.
- Ativação por voz.
- Supressão de ruído, quando viável.
- Cancelamento de eco, quando viável.
- Indicador de transmissão.
- Silenciar todos.
- Silenciar jogadores específicos.

O jogador deverá conseguir testar seu microfone antes de entrar em um servidor.

Não transmitir áudio sem autorização e ativação do usuário.

## 4.6 Tecnologia de transmissão

Investigar a melhor solução de voz em tempo real compatível com Godot 4.

Preferir:

- Codec Opus.
- Baixa latência.
- Compressão eficiente.
- Buffer de jitter.
- Tratamento de perda de pacotes.
- Transmissão por canal separado ou infraestrutura adequada.
- Uso eficiente de banda.

Não utilizar o mesmo fluxo confiável de eventos críticos do jogo para transportar áudio de maneira que cause travamentos ou atraso na movimentação.

Utilizar uma solução técnica mantida, compatível e devidamente documentada.

Se for necessária uma biblioteca externa, integrar e distribuir suas dependências corretamente.

Não implementar criptografia própria improvisada.

## 4.7 Desempenho

O chat de voz deverá ser otimizado para computadores modestos.

Evitar decodificar vozes que não serão ouvidas.

Priorizar a transmissão para jogadores autorizados e dentro do alcance.

Não sobrecarregar o servidor com streams desnecessários.

Não prejudicar FPS ou movimentação.

## 4.8 Segurança e privacidade

Implementar:

- Permissão explícita de microfone.
- Indicador de transmissão.
- Bloqueio de jogadores.
- Silenciamento individual.
- Controle de acesso aos canais.
- Proteção contra pacotes inválidos.
- Limites de banda.
- Validação de identidade.
- Proteção contra falsificação de remetente.

Não gravar conversas por padrão.

Não transmitir microfone enquanto o chat de voz estiver desativado.

---

# 5. INTERAÇÃO ENTRE JOGADORES

Adicionar uma interface de interação ao selecionar um jogador.

Opções:

- Enviar mensagem privada.
- Convidar para grupo.
- Convidar para tribo, quando autorizado.
- Iniciar chamada privada de voz.
- Silenciar voz.
- Bloquear mensagens.
- Consultar perfil público.
- Denunciar comportamento inadequado, caso exista sistema de moderação.

A chamada privada deverá exigir aceitação do destinatário.

Não ativar automaticamente o microfone ao receber uma chamada.

---

# 6. SISTEMA DE GRUPOS E CONVERSAS

Permitir criar grupos temporários de comunicação.

O jogador poderá:

- Criar grupo.
- Convidar participantes.
- Remover participantes, quando autorizado.
- Sair.
- Escolher nome do grupo.
- Utilizar chat de texto.
- Utilizar chat de voz.
- Ver participantes conectados.

Os grupos devem funcionar independentemente das tribos.

Um jogador poderá participar de conversas diferentes, mas a interface deverá impedir confusão sobre qual canal está ativo.

---

# 7. COMUNICAÇÃO ENTRE TRIBOS

Criar um sistema de comunicação diplomática.

Os líderes poderão solicitar conversas entre tribos.

Exemplos:

- Negociar alianças.
- Solicitar paz.
- Conversar sobre territórios.
- Organizar trocas.
- Negociar conflitos.

Implementar canais temporários com controle de participantes.

Permitir que o líder autorize representantes.

Não conceder automaticamente acesso ao chat interno de outra tribo.

---

# 8. MELHORIAS ADICIONAIS DE EXPERIÊNCIA

Implementar também:

## 8.1 Indicadores de voz

Mostrar um pequeno ícone de microfone próximo ao nome do jogador que está falando, quando ele estiver visível e sua transmissão puder ser percebida pelo usuário.

Não revelar jogadores ocultos ou fora do alcance por meio desses indicadores.

## 8.2 Indicador de canal

Mostrar discretamente o canal de voz ativo:

- Proximidade.
- Privado.
- Grupo.
- Tribo.
- Diplomacia.

## 8.3 Ajuste individual de volume

Permitir ajustar o volume de jogadores específicos.

Salvar preferências de silenciamento quando apropriado.

## 8.4 Reconexão

Se o jogador perder conexão, restaurar seus canais autorizados ao reconectar.

Não restaurar chamadas privadas encerradas sem nova confirmação.

## 8.5 Notificações

Criar notificações discretas para:

- Nova mensagem privada.
- Convite de grupo.
- Convite de voz.
- Convite diplomático.
- Falha de microfone.
- Desconexão do canal.

## 8.6 Acessibilidade

Adicionar:

- Tamanho ajustável da fonte do chat.
- Contraste adequado.
- Opção de desativar sons de notificação.
- Legibilidade em 720p.
- Navegação por teclado.
- Indicadores visuais de transmissão.

---

# 9. ARQUITETURA

Separar os sistemas em módulos.

Sugestões:

- InstallerBuild.
- LocalizationManager.
- TextChatManager.
- VoiceChatManager.
- VoiceChannelManager.
- VoiceProximityManager.
- CommunicationPermissions.
- AudioSettingsManager.
- PlayerCommunicationUI.

Os nomes podem ser adaptados à arquitetura existente.

Não concentrar toda a lógica em `Main.gd`.

O servidor deverá controlar autenticação, permissões, participação em canais e roteamento de mensagens.

O cliente deverá controlar captura de microfone, reprodução, interface e preferências locais.

---

# 10. TESTES OBRIGATÓRIOS

Criar e executar testes para:

## Instalador

- Instalação limpa.
- Instalação sobre versão anterior.
- Criação de atalho na área de trabalho.
- Criação de atalho no menu Iniciar.
- Funcionamento do atalho.
- Inicialização do jogo.
- Desinstalação.
- Preservação de salvamentos.
- Seleção de idioma.

## Idiomas

- Primeira inicialização.
- Salvamento da preferência.
- Alteração de idioma.
- Tradução dos menus.
- Suporte a caracteres japoneses.
- Textos longos.
- Persistência após reiniciar.

## Chat de texto

- Mensagem global.
- Mensagem local.
- Mensagem privada.
- Mensagem de grupo.
- Mensagem de tribo.
- Mensagem entre tribos.
- Bloqueio.
- Reconexão.
- Proteção contra spam.

## Chat de voz

- Captura de microfone.
- Transmissão.
- Recepção.
- Push-to-Talk.
- Ativação por voz.
- Atenuação por distância.
- Áudio espacial.
- Voz privada.
- Voz de grupo.
- Voz de tribo.
- Silenciamento.
- Desconexão.
- Reconexão.
- Tratamento de perda de pacotes.
- Consumo de CPU.
- Consumo de banda.

Testar com pelo menos dois clientes e um servidor.

Quando possível, testar com três ou mais clientes para validar grupos e canais.

Se o ambiente não possuir microfone ou saída de áudio, utilizar testes automatizados com sinais de áudio de teste e registrar que a validação com dispositivos físicos permanece pendente.

Não afirmar que um teste físico passou se ele não foi realizado.

---

# 11. ENTREGA

Gerar:

- Instalador Windows multilíngue.
- Executável Windows funcional.
- Atalho de área de trabalho configurado.
- Atalho do menu Iniciar.
- Desinstalador.
- Arquivos de tradução.
- Sistema de chat de texto.
- Sistema de chat de voz.
- Documentação dos canais.
- Documentação dos controles.
- Relatório de testes.

Atualizar:

- `README.md`
- `PROGRESS.md`
- `ARCHITECTURE.md`
- Documentação de instalação.
- Documentação multiplayer.

O instalador deverá incluir todos os arquivos necessários para o jogo funcionar.

Não exigir Godot ou compiladores no computador do jogador.

---

# 12. CRITÉRIOS DE CONCLUSÃO

Não considere este trabalho concluído enquanto:

- O instalador não estiver gerado.
- Os atalhos não estiverem configurados corretamente.
- A escolha de idioma não funcionar.
- As traduções obrigatórias estiverem incompletas.
- O chat de texto não transmitir mensagens reais.
- O chat de voz não transmitir áudio real.
- A voz de proximidade não respeitar a distância.
- As permissões dos canais não estiverem funcionando.
- O servidor não validar as comunicações.
- Os testes disponíveis não forem executados.

Se o ambiente não permitir validar alguma funcionalidade, registre exatamente a limitação e não declare essa parte como comprovadamente funcional.

---

# 13. ORDEM DE EXECUÇÃO

Siga esta ordem:

**Fase 1:** Auditoria do projeto e preservação do estado atual.

**Fase 2:** Implementação do sistema multilíngue.

**Fase 3:** Tela de seleção de idioma na primeira inicialização.

**Fase 4:** Sistema completo de chat de texto.

**Fase 5:** Sistema de grupos e comunicação entre tribos.

**Fase 6:** Captura, transmissão e recepção de voz.

**Fase 7:** Áudio espacial e atenuação por proximidade.

**Fase 8:** Canais privados, grupos, tribos e diplomacia.

**Fase 9:** Configurações de microfone, segurança e acessibilidade.

**Fase 10:** Integração, testes e otimização multiplayer.

**Fase 11:** Criação do instalador Windows multilíngue.

**Fase 12:** Testes de instalação, atualização e desinstalação.

Ao concluir cada fase, implemente, teste, corrija e continue.

Não interrompa o desenvolvimento apenas para apresentar planejamento.

---

# 14. INSTRUÇÃO FINAL

Quero que Tribes of Fire tenha a experiência de instalação e comunicação de um jogo multiplayer bem desenvolvido.

O instalador deverá ser simples e permitir escolher o idioma, criar um atalho na área de trabalho e iniciar o jogo imediatamente após a instalação.

Na primeira inicialização, o jogador deverá escolher o idioma do jogo.

O chat de texto deverá permitir comunicação global, local, privada, em grupo, na tribo e entre tribos autorizadas.

O chat de voz deverá possuir comunicação real por proximidade, com volume diminuindo gradualmente conforme a distância até ficar inaudível.

Também deverá permitir canais privados, grupos, tribos e diplomacia, com permissões e indicadores claros.

Tudo deverá ser integrado ao multiplayer existente, preservando a otimização para computadores antigos.

**COMECE AGORA. ANALISE O REPOSITÓRIO, IMPLEMENTE OS SISTEMAS REAIS, EXECUTE OS TESTES DISPONÍVEIS E GERE O INSTALADOR WINDOWS QUANDO ESTIVER PRONTO.**

Não entregue somente planejamento. Entregue código funcional, arquivos distribuíveis e evidências reais de funcionamento.
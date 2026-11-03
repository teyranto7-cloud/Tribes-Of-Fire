Prompt Mestre — Tribes of Fire
Créditos do projeto: felipealx
Este documento reúne em um só lugar os quatro prompts criados para o projeto: Parte 1 (situação atual e continuidade), Parte 2 (reconstrução e auditoria completas), Parte 3 (sistemas complementares) e Parte 4 (instalador para Windows).
Como usar: entregue o documento inteiro à IA. Ela deve ler a Parte 1 primeiro, reconstituir o estado real do repositório e só então seguir as demais partes, na ordem de prioridade: estabilidade e segurança, mecânicas, visual, produção e instalador. As referências a "seção N" ou "Passo N" dentro de cada parte valem para aquela parte. Quando houver sobreposição (por exemplo, o instalador aparece na Parte 2 e na Parte 4), vale a versão mais detalhada, a da Parte 4.
PARTE 1 — SITUAÇÃO ATUAL E CONTINUIDADE (retomar de onde parou)
0. LEIA PRIMEIRO: SITUAÇÃO ATUAL DO PROJETO
Você está assumindo o desenvolvimento do Tribes of Fire, um jogo de sobrevivência pré-histórico estilizado feito em Godot, com multiplayer, tribos, clima, construção e instalador para Windows. Outra IA trabalhou antes de você e foi interrompida no meio de uma revisão por limite de uso. Esta parte resume o que se sabe, o que foi dito e o que ainda precisa ser feito.
Repositório público: https://github.com/teyranto7-cloud/Tribes-Of-Fire (branch main)
Clone: git clone https://github.com/teyranto7-cloud/Tribes-Of-Fire.git
Versão publicada: 0.3.0-dev, com código, recursos, dependências, README, instalador Windows e ZIPs nos downloads do repositório.
0.1 O que a IA anterior afirmou ter feito (NÃO CONFIE SEM VERIFICAR)
Trate tudo abaixo como alegações não verificadas até você reproduzir por conta própria:
• Publicou o projeto na main do repositório (a primeira tentativa de criar o repositório falhou porque a rede bloqueava api.github.com com 403; depois o usuário criou o repositório público manualmente).
• Um commit anterior, 969024f ("build: resultado final"), tinha 203 arquivos e README.
• Disse ter confirmado: o clone, os hashes, a execução do pacote Linux e, no Windows, instalação, execução sem interface gráfica e salvamento.
• Arquivos mencionados como alterados na última publicação: Tools/Test-Windows.ps1, Tools/build.py, Tools/package.py.
• A entrega foi declarada como 0.3.0-dev. Ficaram pendentes e documentados: testes gráficos em Windows 10/11 e os requisitos restantes da versão 1.0.
0.2 Falhas reais encontradas na revisão (e que a IA anterior estava corrigindo)
Na revisão final, a IA anterior relatou ter encontrado falhas que os testes anteriores não cobriam:
1. Configuração inválida podia impedir a abertura do jogo (arquivo de configuração corrompido ou com valor fora do esperado).
2. Uma desconexão podia prender o jogador na tela de morte.
3. Equipamentos podiam recuperar durabilidade ao serem descartados (exploração de durabilidade).
4. Coleta de recursos através de paredes (falta de verificação de linha de visão e obstáculos).
5. Problemas de controles e de áudio (sem detalhes sobre quais).
Ela estava corrigindo isso e acrescentando testes que reproduzem cada caso antes de substituir os downloads publicados. O último registro mostra edições em pelo menos: Main.gd, Game/Runtime.gd e Networking/Session.gd (mais outros arquivos, num total aproximado de +199 e −40 linhas), e depois o trabalho parou por limite de uso.
0.3 O que isso significa para você
• As correções podem estar parcialmente aplicadas, não testadas, não commitadas ou não publicadas. Não assuma nada.
• Os downloads publicados provavelmente ainda são os da versão anterior, sem as correções.
• O instalador publicado foi testado apenas de forma limitada (sem interface gráfica). Nenhum teste gráfico em Windows real foi comprovado.
• A versão 0.3.0-dev não é uma versão 1.0 e não deve ser apresentada como pronta para o público.
1. REGRAS DE TRABALHO
1. Verifique antes de afirmar. Nunca diga que algo funciona sem ter visto funcionar. Se não conseguir testar (Windows gráfico, multiplayer real, hardware diferente), diga "não testado" e o motivo.
2. Reproduza antes de corrigir. Para cada bug, escreva primeiro um teste ou roteiro que o reproduza, veja falhar, corrija e veja passar.
3. Não publique nada quebrado. Só substitua os downloads do repositório depois que o build novo passar pelos testes.
4. Segredos: nunca cole tokens no chat, em arquivos ou em commits. O token do GitHub deve ficar como segredo GH_TOKEN do ambiente. Se a rede bloquear api.github.com ou o git push, avise o usuário para liberar o domínio nas configurações de rede, em vez de tentar contornar.
5. Trabalhe por etapas pequenas, com commits claros, e rode todos os testes após cada conjunto de mudanças.
6. Procure ativamente problemas que ninguém listou. A última revisão achou falhas graves que testes anteriores não viam; assuma que existem outras.
7. Priorize: (1) o jogo abrir e não corromper dados; (2) exploits e falhas de segurança; (3) mecânicas quebradas; (4) multiplayer; (5) visual e polimento.
8. Honestidade no relatório: separe sempre comprovado de pendente e de não testado.
9. Se a IA anterior deixou instruções ou arquivos de notas no repositório (README, docs/, listas de pendências), leia-os e atualize-os.
2. PASSO 1 — RECONSTITUIR O ESTADO REAL
Antes de qualquer mudança nova, faça um levantamento e apresente o resultado:
1. Clone o repositório (ou abra a cópia local, se o ambiente já tiver uma).
2. git status, git log --oneline -20, git diff --stat e git stash list: o que está commitado, o que está só na pasta de trabalho e o que está perdido.
3. Se houver mudanças não commitadas, revise-as linha a linha (git diff) antes de aceitá-las. Não as descarte sem avisar e não as aceite sem entender.
4. Compare a main remota com a local (git fetch, git diff origin/main).
5. Confira quais releases e downloads estão publicados, com versão, data e hashes, e se correspondem ao código atual.
6. Leia o README, os scripts de Tools/ (build.py, package.py, Test-Windows.ps1 e os demais) e entenda o pipeline: como o jogo é exportado, empacotado, testado e publicado.
7. Liste a estrutura do projeto: project.godot, cena principal, autoloads, Main.gd, Game/, Networking/, recursos, testes e instalador.
8. Rode o projeto e a suíte de testes existente. Registre o que passa e o que falha antes de qualquer alteração sua.
Entregue um relatório de estado curto: o que existe, o que está quebrado, o que está incompleto, o que as correções interrompidas já cobrem e o que falta nelas.
3. PASSO 2 — CONCLUIR E PROVAR AS CORREÇÕES INTERROMPIDAS
Para cada falha da seção 0.2, siga este roteiro e relate o resultado:
3.1 Configuração inválida que impede a abertura
• Reproduza com arquivos de configuração vazios, truncados, com formato inválido, com tipos errados, valores fora de faixa (resolução 0, volume negativo, preset inexistente, idioma inexistente, versão futura) e com o arquivo sem permissão de leitura.
• Comportamento correto: o jogo sempre abre. Valores inválidos são substituídos pelos padrões, o arquivo ruim é salvo como .bak e o jogador recebe, no máximo, um aviso discreto.
• Valide e limite (clamp) todos os valores lidos. Mantenha uma única fonte de verdade para as configurações.
• Reconfirme o bug dos presets gráficos: selecionar Baixo, esperar 2 minutos, selecionar Alto, entrar e sair de uma partida, fechar, reabrir; nada pode voltar sozinho.
• Aplique a mesma robustez aos arquivos de salvamento do mundo e do personagem: nunca travar na abertura; manter backup; recuperar.
3.2 Desconexão presa na tela de morte
• Reproduza: morrer, desconectar (cabo, fechar servidor, timeout), reconectar, morrer e sair, e servidor caindo durante a tela de morte.
• Comportamento correto: a tela de morte nunca bloqueia o retorno ao menu. Mensagem clara de conexão perdida, botão para voltar ao menu, limpeza total do estado (nós, timers e conexões antigas) e reconexão funcional.
• Verifique o que acontece no servidor com o jogador desconectado morto: itens, mochila de morte, estado e renascimento.
• Teste a sequência repetidamente (entrar, morrer, desconectar, voltar) para detectar vazamento de estado.
3.3 Durabilidade recuperada ao descartar equipamento
• Reproduza: usar uma ferramenta até desgastar, descartar, coletar de novo, e também guardar em baú, trocar com outro jogador, desmontar, dividir pilha, fabricar com ela e salvar e carregar.
• Comportamento correto: todo item preserva a durabilidade em qualquer caminho (descarte, baú, troca, morte, salvamento, rede). O servidor é a autoridade sobre a durabilidade.
• Audite todo o sistema de inventário por outras formas de duplicar ou regenerar itens e propriedades (qualidade, munição, combustível, validade).
3.4 Coleta através de paredes
• Reproduza: tentar cortar, minerar, colher, abrir baú e interagir com objetos atrás de paredes, telhados, rochas, no outro lado de rios e em cavernas.
• Comportamento correto: toda interação exige linha de visão válida e alcance verificados no servidor, e não só no cliente. Considere raycast do olho do jogador até o alvo, ignorando apenas o próprio alvo e objetos permitidos.
• Aplique o mesmo teste a ataques, construção, abrir baús, entrar em construções de outras tribos e dano de projéteis.
3.5 Controles e áudio
A IA anterior não especificou o que estava errado. Investigue por conta própria e documente:
• Controles: teclas que não respondem, ações duplicadas, conflitos entre teclas, entrada presa ao abrir ou fechar menus e inventário, cursor do mouse não capturado ou não liberado, foco perdido ao trocar de janela, entrada que continua ativa durante a tela de morte, comportamento em tela cheia e com layouts de teclado diferentes (ABNT2, US).
• Áudio: sons que não tocam, repetem em loop errado, ficam mudos depois de trocar de cena, volume que não respeita os sliders ou não é salvo, estouro de volume, falta de áudio no pacote exportado e falta de dispositivo de áudio (o jogo não pode travar sem placa de som).
• Corrija o que encontrar e acrescente testes sempre que for possível.
3.6 Testes de regressão
• Cada falha acima precisa ter um teste automatizado (ou roteiro manual documentado, quando não der para automatizar) que continue no repositório e rode no pipeline.
• A suíte inteira deve passar antes de qualquer publicação.
4. PASSO 3 — AUDITORIA ATIVA POR NOVAS FALHAS
A revisão anterior achou problemas graves que passaram despercebidos. Faça uma segunda varredura, com mentalidade de quem quer quebrar o jogo, e relate tudo o que encontrar, com gravidade (Crítico, Alto, Médio, Baixo) e correlação com o código.
• Estabilidade: abrir, fechar e reabrir o jogo 50 vezes; entrar e sair de mundos; trocar de presets; redimensionar a janela; alt-tab; minimizar; desligar o áudio; iniciar sem rede.
• Persistência: matar o processo durante o salvamento; disco cheio; pasta de saves somente leitura; saves de versões antigas; mundo com construções, baús e animais.
• Servidor autoritativo: examine cada RPC e mensagem de rede. Tente enviar dano falso, coleta falsa, itens falsos, posição impossível, comandos administrativos, mensagens fora de ordem, pacotes enormes ou malformados, remetente falso e spam. O servidor não pode confiar em nada do cliente.
• Duplicação e economia: inventário, baús, trocas, fabricação, fila, divisão de pilhas, desconexão durante a troca, salvamento no meio de uma ação.
• Exploits de física e mapa: atravessar paredes, sair do mundo, ficar preso no terreno, voar, pular sobre construções, nascer dentro de rocha ou água, cair no vazio.
• IA e animais: animais presos, animais atacando sem motivo, animais atravessando paredes, acúmulo de animais e atualização pesada.
• Clima e sobrevivência: 40 segundos de proteção inicial na chuva fria e 1 ponto de vida a cada 15 segundos depois; abrigo, fogueira, recuperação de vida; sincronização do clima; jogador comum não pode alterar clima, hora, vida, recursos ou posição.
• Interface: textos técnicos, instruções de controles fixas na HUD, textos cortados, traduções faltando, resoluções diferentes, tela cheia, janela e janela sem bordas.
• Desempenho: FPS por preset, uso de memória após 30 minutos, tempo de carregamento, quedas ao gerar regiões.
• Pacote: arquivos de desenvolvimento dentro do instalador, recursos faltando, caminhos dinâmicos quebrados, dados gravados em Program Files em vez de user://.
Corrija o que for reproduzível e consiga provar. Registre o resto como pendência, com explicação.
5. PASSO 4 — REBUILD, VALIDAÇÃO E PUBLICAÇÃO
Só comece depois de os passos 2 e 3 estarem verificados.
1. Defina a versão: suba a versão (por exemplo, 0.3.1-dev) em um único lugar que alimente jogo, instalador, pacotes e nome dos arquivos. Não sobrescreva silenciosamente uma versão publicada.
2. Gere os artefatos: pacote Windows, pacote Linux (se existir) e instalador, pelos scripts de Tools/.
3. Valide: suíte de testes, instalação limpa, execução, salvamento, reabertura, atualização sobre a versão anterior, desinstalação, e conferir hashes SHA-256 e o tamanho dos arquivos.
4. Teste de instalação limpa: sem Godot instalado, e com caminhos com espaços e acentos.
5. Idioma e atalho: o instalador oferece escolha de idioma e atalho opcional na área de trabalho, e o idioma escolhido vira o idioma inicial do jogo.
6. Commit e push: commits pequenos e claros, git push origin main. Se a rede bloquear github.com ou api.github.com, pare e avise o usuário; não tente contornar.
7. Release: crie uma release nova com notas de versão honestas (o que mudou, o que foi corrigido, o que ainda está pendente), anexe instalador e ZIPs, publique os hashes e confirme que o link de download funciona.
8. Confira o resultado publicado: clone o repositório de novo em uma pasta limpa, baixe o instalador da release e confirme que o hash é o esperado.
Se qualquer item falhar, não publique e explique.
6. PASSO 5 — CONTINUAR O DESENVOLVIMENTO (ROADMAP até a versão 1.0)
Depois de estabilizar e publicar, continue pelos requisitos da versão 1.0, que estão detalhados nas Partes 2, 3 e 4 deste documento. Cada item só entra como concluído depois de testado. Mantenha no repositório um arquivo de pendências (docs/PENDENCIAS.md ou equivalente), verificável e atualizado a cada etapa.
Estabilidade e segurança (primeiro)
• Servidor autoritativo completo (dano, coleta, construção, clima, persistência, comandos administrativos com autenticação no servidor).
• Salvamento atômico, versionado, com backup e migração.
• Remoção dos controles de depuração da versão pública.
Mundo e visual
• Mapa com pelo menos 600% da área original, geração procedural por seed e por chunks, biomas, rios, lagos, cavernas e ruínas, e persistência das alterações.
• Árvores, grama, terreno, água, iluminação, personagem e animais reconstruídos (nada de esferas verdes e triângulos simples).
Jogabilidade
• Coleta com itens físicos no chão e animação correta; construção modular com colisão, abrigo da chuva e persistência.
• IA dos animais (passivos, neutros e predadores); sobrevivência, fogo, alimentação.
• Tribos, chat, inventário completo, artesanato, caça, pesca, agricultura, domesticação e combate.
• Progressão e árvore de tecnologia.
Experiência do jogador
• Menu principal bonito com todas as opções, escolha de idioma na primeira abertura (salva), personalização de personagem, HUD limpa sem textos técnicos nem teclas fixas, tutorial discreto, mapa, bússola, controles remapeáveis, gamepad e acessibilidade.
• Presets gráficos funcionando e salvos; tela cheia, janela e janela sem bordas corretos no Windows.
• Áudio completo.
Produção
• Servidor dedicado com configuração e administração.
• Instalador testado em Windows real (10 e 11), incluindo tela cheia e multiplayer.
• Licenças, créditos (com felipealx), privacidade, notas de versão e material de divulgação.
7. LIMITAÇÕES CONHECIDAS (DECLARE-AS, NÃO ESCONDA)
• Testes gráficos em Windows 10/11 reais ainda não foram comprovados. Se seu ambiente não permitir, diga isso e entregue um roteiro curto para o usuário executar no PC dele, com o que observar e como reportar.
• Desempenho e compatibilidade em PCs diferentes dependem de hardware real, e não podem ser garantidos só por testes automatizados.
• Multiplayer real com várias máquinas e latência não foi comprovado pelo material disponível. Se não puder testar, descreva a limitação.
• O ambiente da IA anterior tinha restrição de rede (acesso a api.github.com bloqueado em um momento). Verifique se a rede está liberada antes de depender dela.
• O trabalho anterior foi interrompido por limite de uso. Trabalhe de forma que, se for interrompido de novo, o estado seja recuperável: faça commits frequentes (mesmo em branch de trabalho), mantenha as pendências escritas no repositório e nunca deixe mudanças longas só na pasta de trabalho.
8. RELATÓRIO FINAL OBRIGATÓRIO DA PARTE 1
A. Estado encontrado: o que havia no repositório, nas mudanças não commitadas e nos downloads publicados.
B. Correções concluídas: para cada falha (configuração inválida, tela de morte, durabilidade, coleta através de paredes, controles, áudio), causa, solução, arquivos alterados e teste de regressão.
C. Novas falhas encontradas na auditoria: lista com gravidade, o que foi corrigido e o que ficou pendente.
D. Testes executados: quais, em que ambiente, com que resultado e evidência (logs, hashes, números). Separe comprovado de não testado.
E. Publicação: versão, commit, link da release, hashes e confirmação do download limpo.
F. Funcionalidades implementadas nesta rodada: o que foi criado e onde.
G. Pendências e riscos: o que falta para a 1.0, o que depende de hardware real e qualquer item incompleto. Não apresente nada incompleto como se estivesse funcionando.
9. INSTRUÇÃO FINAL DA PARTE 1
Quero que o Tribes of Fire seja um jogo realmente estável, seguro, bonito e divertido, e que cada afirmação sobre o estado dele seja verdadeira.
Comece agora pelo Passo 1: reconstitua o estado real do repositório e dos arquivos modificados, rode os testes existentes e apresente o relatório de estado. Depois conclua e prove as correções do Passo 2, faça a auditoria do Passo 3, e só então rebuild e publique.
Mais importante: não confie no que a IA anterior disse, não declare nada pronto sem testar e não publique uma versão que você não validou.
Prompt de reconstrução e auditoria — Tribes of Fire
Créditos do projeto: felipealx
0. PAPEL E REGRAS DE TRABALHO
Você é um engenheiro sênior de jogos (Godot 4), artista técnico e especialista em multiplayer. Sua missão é transformar o Tribes of Fire de protótipo em um jogo de sobrevivência independente, bonito, estável e pronto para lançamento público, preservando a identidade original: mundo pré-histórico, estilo low-poly estilizado, personagens robustos de proporções levemente baixas, tribos, fogueiras, clima e sobrevivência.
Regras inegociáveis:
1. Implemente de verdade. Nada de pseudocódigo, scripts isolados, recursos fictícios ou sistemas que não estejam conectados às cenas reais do projeto.
2. Nunca marque um item como concluído sem executá-lo e verificá-lo. Se não foi testado, ele está pendente.
3. Não afirme resultados que você não observou (por exemplo, "instalador validado" sem instalar e abrir o jogo).
4. Trabalhe em etapas curtas. Após cada etapa: abra o projeto, procure erros no console, rode a cena principal e confirme que nada antigo quebrou.
5. Prioridade: (1) estabilidade e bugs que impedem o jogo de funcionar; (2) mecânicas; (3) segurança do multiplayer; (4) visual; (5) polimento.
6. Se algo não couber em uma etapa, mantenha uma lista verificável de pendências e continue de forma organizada.
7. Se o ambiente não permitir um teste (multiplayer real, instalador, capturas de tela), diga isso claramente em vez de fingir que testou.
8. Se encontrar um problema que eu não listei, corrija e registre no relatório. Você deve procurar ativamente defeitos, não apenas cumprir esta lista.
1. AUDITORIA INICIAL OBRIGATÓRIA (ANTES DE ALTERAR QUALQUER COISA)
Antes de escrever código novo, leia o projeto inteiro e produza um diagnóstico escrito contendo:
• Estrutura de pastas, cenas principais, autoloads, scripts e recursos.
• Versão do Godot, renderizador usado (Forward+, Mobile ou Compatibility), configurações de exportação.
• Mapa de dependências: qual cena carrega qual script, quais sinais estão conectados, quais nós são criados por código.
• Lista de todos os erros e avisos que aparecem no console ao abrir o projeto e ao jogar por cinco minutos.
• Código morto, scripts órfãos, cenas não utilizadas, recursos duplicados, caminhos quebrados, referências nulas, get_node frágeis, await sem tratamento, timers sem limpeza.
• Sistemas que parecem prontos, mas não estão ligados ao jogo real (por exemplo, um script de construção que nunca é chamado).
• Pontos onde o cliente decide algo que deveria ser decidido pelo servidor.
• Gargalos de desempenho: criação de nós a cada quadro, loops pesados em _process, malhas geradas sem cache, sombras excessivas, quantidade de objetos visíveis.
• Dados salvos hoje (o que é gravado, onde, em que formato, quando) e dados que se perdem.
Classifique cada problema encontrado como Crítico (impede jogar ou corrompe dados), Alto (quebra uma mecânica), Médio (incômodo ou inconsistência) ou Baixo (polimento). Só depois comece a corrigir, na ordem de gravidade.
2. ESTABILIDADE E QUALIDADE DO CÓDIGO
• O projeto deve abrir sem erros e sem avisos relevantes.
• Elimine referências nulas, sinais duplicados, conexões sem desconexão e vazamentos de memória.
• Substitua caminhos de nós frágeis por referências exportadas, grupos ou sinais.
• Separe responsabilidades: mundo, clima, jogador, inventário, construção, animais, rede, interface e configurações devem ser módulos independentes e comunicar-se por sinais ou interfaces claras.
• Use tipagem estática onde possível e comentários curtos nos pontos complexos.
• Centralize constantes de balanceamento (dano, tempos, custos, alcance) em recursos ou arquivos de configuração, e não espalhadas pelo código.
• Adicione um registro de log simples (nível, sistema, mensagem) que possa ser desligado na versão pública.
• Garanta que fechar o jogo, voltar ao menu e iniciar outro mundo não deixe nós, timers ou conexões de rede antigos ativos.
3. BUG PRIORITÁRIO: CONFIGURAÇÕES GRÁFICAS QUE VOLTAM SOZINHAS
Hoje os presets gráficos (Baixo, Médio, Alto e os demais) mudam sozinhos depois de alguns instantes. Este é o defeito mais importante da lista.
Investigue, no mínimo:
• Algum _process, Timer ou _ready que reaplica um preset padrão.
• Autoload ou cena que recarrega o arquivo de configuração e sobrescreve a escolha do jogador.
• Lógica de "qualidade automática" ou "ajuste dinâmico de desempenho" alterando o preset sem aviso.
• Ordem de carregamento: a configuração salva sendo lida antes de ser escrita, ou sendo escrita com valores padrão.
• Interface atualizando os controles (OptionButton, sliders) e disparando sinais de mudança que regravam o valor.
• Vários arquivos de configuração (por exemplo, user:// e res://) em conflito.
• Mudanças de tela cheia ou de resolução acionando a reaplicação de presets.
Correção esperada:
• Uma única fonte de verdade para as configurações (um autoload Settings), gravada em user://settings.cfg.
• A escolha do jogador nunca é sobrescrita automaticamente. Se existir qualquer ajuste automático, ele deve ser opcional, desativado por padrão e visível na interface.
• Ao selecionar um preset, aplique todos os parâmetros (sombras, qualidade de sombra, MSAA/FXAA, distância de visão, densidade de grama, densidade de árvores, qualidade da água, partículas, escala de renderização, SSAO, glow, névoa), salve imediatamente e atualize a interface sem disparar laços de sinais.
• Presets personalizados: se o jogador alterar uma opção individual, o preset passa a "Personalizado".
• Ao reabrir o jogo, as preferências são restauradas fielmente.
Teste obrigatório (executar de verdade): selecionar Baixo, esperar 2 minutos, confirmar que não mudou; selecionar Alto, esperar; entrar e sair de uma partida; fechar; reabrir; confirmar que tudo permanece. Repetir para todos os presets. Não considere o bug corrigido se as configurações voltarem a mudar automaticamente.
4. TELA CHEIA, RESOLUÇÃO E INTERFACE ADAPTÁVEL
• Suporte a Tela cheia, Janela e Janela sem bordas, com troca em tempo real e sem reiniciar.
• O jogo deve ocupar corretamente a tela no Windows, inclusive em monitores 1080p, 1440p, 4K, ultrawide e com escala de DPI diferente de 100%.
• Configure corretamente window/stretch (modo, aspecto e escala) para que a interface se adapte e nenhuma região importante seja cortada.
• Lista de resoluções detectada do monitor real, com opção de escala de interface.
• Mover a janela entre monitores não deve quebrar a resolução.
• Salve modo de janela e resolução junto das demais configurações.
• Teste os três modos e relate o que foi observado.
5. MAPA GRANDE E GERAÇÃO PROCEDURAL
5.1 Tamanho
Meça a área explorável do mapa atual (largura × profundidade, em metros ou unidades). O novo mapa deve ter pelo menos 600% da área original, ou seja, seis vezes o tamanho. Documente os números antes e depois.
5.2 Geração por semente
• Cada mundo novo recebe uma seed (aleatória ou digitada pelo jogador).
• Mesma seed = mesmo mundo, sempre. Seeds diferentes = terrenos claramente diferentes.
• Use ruído em camadas (relevo base, montanhas, vales, erosão) e mapas separados de umidade e temperatura para definir biomas.
• Biomas sugeridos: planícies, floresta densa, floresta clara, pântano, montanhas rochosas, tundra/neve, praia, desertos pequenos e regiões vulcânicas ligadas ao tema do fogo.
• Rios com nascente em regiões altas e foz em lagos ou no mar; lagos em depressões; praias nas bordas da água.
• Cavernas com entradas visíveis e interior real; ruínas e pontos de interesse com distribuição variável e baús ou recursos.
• Zonas de início seguras (sem animais agressivos próximos) e variadas por mundo.
• Geração em chunks carregados e descarregados por distância, com geração fora da thread principal quando possível, para evitar quedas de desempenho.
• Sem barreiras invisíveis inesperadas, buracos no terreno, regiões ausentes ou costuras entre chunks.
• Limites do mundo com transição natural (oceano, montanhas intransponíveis) em vez de uma parede invisível.
5.3 Persistência
• A seed e todas as alterações do jogador (construções, recursos removidos, baús, fogueiras, tribos) são salvas.
• Reiniciar o servidor ou o jogo não gera outro mapa.
• Salve apenas o delta em relação ao mundo gerado pela seed, para manter os arquivos pequenos.
• Salvamento automático periódico e ao sair, com arquivo temporário e troca atômica, para evitar corrupção; mantenha ao menos um backup anterior.
• Versionamento do formato de salvamento, com migração para versões antigas.
6. RECONSTRUÇÃO VISUAL COMPLETA
O visual atual usa formas primitivas (esferas verdes como copas, cones isolados como grama). Reconstrua tudo mantendo o estilo low-poly estilizado, mas com aparência de jogo bem produzido.
6.1 Árvores
• Diversas espécies: carvalho, pinheiro, bétula, árvore frutífera, palmeira de praia, árvore seca/queimada, árvore caída.
• Troncos com forma irregular, raízes, galhos e copas formadas por vários volumes ou cartões foliares com variação de cor, escala e rotação.
• Variação por instância (escala, rotação, tom de verde) e balanço suave ao vento.
• LOD e uso de MultiMesh ou instanciamento para manter o desempenho com florestas densas.
• Colisão apenas no tronco.
6.2 Grama e vegetação
• Substitua os triângulos simples por tufos densos e variados, com cor misturada ao terreno, movimento de vento e densidade controlada pelo preset gráfico.
• Arbustos, flores, samambaias, juncos na beira da água, pedras pequenas, troncos e cogumelos.
• Vegetação coerente com o bioma.
6.3 Terreno
• Texturas ou shaders por altitude e inclinação (grama, terra, rocha, areia, neve), com transições suaves.
• Detalhes: trilhas de terra, manchas de cor, rochas grandes, penhascos.
6.4 Água
• Shader com transparência, reflexo, ondas suaves, espuma na margem, cor variando com a profundidade e efeito de nado/entrada na água.
• Rios com fluxo visível; lagos calmos; som de água.
6.5 Iluminação e atmosfera
• Sol e lua com ciclo dia/noite, céu procedural com gradiente, nuvens, estrelas, névoa volumétrica ou de distância, sombras suaves e tonemapping equilibrado.
• A melhoria não pode vir somente da iluminação: os modelos também precisam ser reconstruídos.
• Efeitos de fogo (partículas, luz tremeluzente) nas fogueiras e tochas; chuva, neblina e relâmpagos nos eventos climáticos.
6.6 Personagem e animais
• Personagem com modelo melhor (cabeça, tronco, braços, pernas, mãos, cabelo, roupas de peles e couro), proporções robustas e levemente baixas, esqueleto e animações: parado, andar, correr, pular, cair, nadar, atacar, cortar árvore, minerar, coletar, construir, comer, sofrer dano e morrer.
• Animais com modelos próprios (veado, coelho, lobo, javali, urso, mamute, aves, peixes), animações de andar, correr, pastar, atacar e morrer.
• Pegadas, sons e partículas leves para dar vida ao mundo.
7. ANIMAIS E INTELIGÊNCIA ARTIFICIAL
Corrija o comportamento de animais que atacam indiscriminadamente.
• Classifique as espécies: passivas (fogem), neutras (só atacam se provocadas) e predadoras (caçam presas ou jogadores dentro de um raio, com perda de interesse).
• Máquina de estados: ocioso, vagar, pastar, fugir, perseguir, atacar, retornar, dormir.
• Percepção por distância, visão e som; memória curta do alvo.
• Navegação no terreno procedural (NavigationMesh por chunk ou direcionamento com raycast), evitando andar sobre a água e atravessar obstáculos.
• Rotina diária (dormir à noite, caçar ao amanhecer) quando fizer sentido.
• Reprodução ou reaparecimento controlados, com limite de população por região.
• No multiplayer, o servidor controla a IA e sincroniza posição, estado e animação de forma eficiente (interpolação no cliente).
• Teste cada espécie e confirme que o comportamento corresponde à classificação.
8. COLETA DE RECURSOS
• Cortar uma árvore faz a madeira realmente aparecer no chão como objeto físico coletável, com animação de queda da árvore e tempo de rebrota.
• Coletar um item exige a animação correta antes da transferência para o inventário.
• Mesma lógica para pedras, minérios, fibras, frutas, carne, peles e ossos.
• Ferramentas com tipo e durabilidade (machado, picareta, lança, faca) afetando velocidade e rendimento.
• Esgotamento e renascimento de recursos, sem duplicação.
• Feedback visual discreto (ícone flutuante, brilho, som) em vez de frases grandes no centro da tela.
• O servidor valida alcance, ferramenta, tempo e quantidade.
9. CONSTRUÇÃO
• Sistema modular: fundação, parede, porta, janela, telhado, escada, cerca, fogueira, cama/abrigo, baú e bancada de trabalho.
• Pré-visualização fantasma (verde válido / vermelho inválido), encaixe em grade, rotação e verificação de terreno.
• Os recursos são consumidos e exibidos no custo.
• Todas as estruturas possuem colisão e são visíveis para os outros jogadores.
• O telhado realmente protege da chuva (verificação por raycast ou volume de abrigo).
• Construções persistem no salvamento e voltam após o reinício.
• Integridade estrutural simples e dano a construções, se aplicável.
• O servidor valida posição, recursos e permissões.
• Teste: construa uma casa pequena com paredes, porta e telhado e confirme todos os pontos acima.
10. SOBREVIVÊNCIA, CLIMA E FOGO
10.1 Estatísticas
Vida, fome, sede, energia e temperatura corporal, com barras discretas e limpas na HUD. Alimentação com valores nutricionais, cozimento da carne e perigo de comer cru ou estragado.
10.2 Clima automático e compartilhado
• O clima é controlado exclusivamente pelo servidor, por um sistema natural de transições (limpo, nublado, chuva, tempestade, neblina, neve em biomas frios).
• Todos os jogadores de um servidor veem o mesmo clima, sincronizado.
• Remova da versão pública qualquer botão, atalho ou comando que permita ao jogador comum alterar o clima.
10.3 Dano da chuva fria
• O jogador tem 40 segundos de proteção inicial sob chuva fria.
• Depois desse período, perde 1 ponto de vida a cada 15 segundos enquanto estiver exposto.
• Abrigos (telhados, cavernas, tendas), roupas e o calor de fogueiras interrompem ou reduzem a perda.
• Recuperação de vida em condições adequadas (alimentado, aquecido, abrigado).
• Fogueiras aquecem em um raio, consomem combustível, apagam na chuva se desprotegidas e permitem cozinhar.
• Teste: proteção de 40 s, dano a cada 15 s, recuperação, abrigo e fogueira.
11. TRIBOS E MULTIPLAYER
• Criação de tribo, convite, hierarquia (líder, membros), recursos e construções compartilhados, território e regras aplicadas de forma consistente.
• Chat com canais (global, local, tribo) e proteção básica contra spam.
• Lista de servidores, entrada por endereço, senha opcional e servidor dedicado sem interface.
• Sincronização de movimento (interpolação e correção de erro), animações, combate, construções, animais, clima e hora do dia.
• Reconexão e tratamento de queda de rede sem travar o jogo.
• Desempenho de rede: envie apenas o que mudou, em taxa adequada, e agrupe mensagens.
12. SEGURANÇA E ANTI-TRAPAÇA
Não confie exclusivamente nos dados enviados pelo computador do jogador. O servidor deve ser a autoridade.
• Validar dano, alcance, cadência de ataque e vida.
• Validar coleta de recursos, construções, fabricação e movimentação (velocidade máxima, teletransporte impossível).
• Controlar clima, hora e alterações persistentes do mundo.
• Impedir geração ilimitada de recursos por manipulação de mensagens (RPCs com validação de remetente, limites de taxa e verificação de parâmetros).
• Impedir duplicação de itens (transações atômicas de inventário, troca e baús).
• Comandos administrativos só com autenticação e autorização verificadas no servidor; jogadores comuns nunca os executam.
• Revisar todos os @rpc e confirmar quem pode chamar o quê (any_peer apenas quando realmente necessário e sempre validado).
• Registrar tentativas suspeitas.
13. REMOÇÃO DE CONTROLES DE DEPURAÇÃO
Remova da versão pública:
• Alteração manual do clima e do horário.
• Geração arbitrária de recursos.
• Alteração manual da vida.
• Teletransporte de teste.
• Ferramentas internas de desenvolvimento.
• Textos de depuração e instruções de controles na HUD durante o jogo.
Se forem necessárias para manutenção, deixe-as somente em build de desenvolvimento (OS.is_debug_build() ou flag de exportação) ou em interface administrativa autenticada pelo servidor.
14. INTERFACE (HUD, INVENTÁRIO E FEEDBACK)
• HUD limpa e profissional: vida, fome, sede, temperatura, hora e bússola discretas. Sem textos técnicos, sem lista permanente de teclas cobrindo a tela.
• Dicas de controles aparecem apenas em um tutorial curto, ou em uma tela de ajuda acessível pelo menu.
• Inventário bonito, funcional e intuitivo: organizar, usar, dividir pilhas, mover, equipar e descartar; ícones próprios, descrições, quantidades e peso, se existir.
• Barra de atalhos, menu de fabricação com receitas e requisitos, e painel de tribo.
• Feedback discreto ao coletar, fabricar ou concluir construções.
• Interface adaptável a qualquer resolução e escala; suporte a teclado, mouse e, se possível, controle.
15. EXPERIÊNCIA DO JOGADOR
Menu principal
Menu bonito com a identidade de Tribes of Fire, animações discretas e cenário de fundo inspirado no próprio mundo. Opções: Jogar, Multiplayer, Criar mundo, Entrar em servidor, Personalizar personagem, Configurações, Créditos, Sair.
Primeira inicialização
O jogador escolhe o idioma ao abrir o jogo pela primeira vez; a escolha é salva e não é solicitada novamente. Preserve e conclua os idiomas já planejados e garanta que nenhum texto fique sem tradução ou cortado.
Personalização de personagem
Cabelo, cor do cabelo, olhos, cor dos olhos, tom de pele, rosto, altura dentro de limites apropriados e roupas iniciais, mantendo a aparência pré-histórica estilizada. A aparência é sincronizada para os outros jogadores.
Áudio
Trilha ambiente por bioma e hora, sons de passos por superfície, ferramentas, animais, clima, fogo e interface; controles de volume por categoria.
16. DESEMPENHO E OTIMIZAÇÃO
• Meta: 60 FPS estáveis em hardware intermediário no preset Médio; preset Baixo utilizável em máquinas modestas.
• Use MultiMesh, LOD, culling por distância e oclusão quando útil; agrupe materiais e reduza chamadas de desenho.
• Sombras em cascata ajustáveis, distância de visão por preset, pooling de objetos (itens, partículas, projéteis).
• Meça FPS, uso de memória e tempo de geração de chunks antes e depois, e relate os números.
• Verifique o tempo de carregamento e o consumo após longas sessões (vazamento de memória).
17. INSTALADOR E EXPORTAÇÃO PARA WINDOWS
• Exporte o jogo como executável independente (com modelos de exportação instalados), sem exigir Godot ou ferramentas de desenvolvimento.
• Instalador simples (por exemplo, Inno Setup ou NSIS) com escolha de idioma e criação opcional de atalho na área de trabalho, desinstalador e ícone do jogo.
• Confirme que o pacote inclui cenas, modelos, texturas, sons, fontes, traduções e bibliotecas de rede necessárias.
• Verifique os filtros de exportação (recursos não importados, arquivos .import, cenas carregadas por caminho dinâmico).
• Teste o jogo instalado, abrindo-o, jogando e conectando a um servidor. Não afirme que o instalador foi validado sem realizar uma instalação e execução de teste reais.
18. VERIFICAÇÃO OBRIGATÓRIA POR SINTOMA
• Se o mapa gera terrenos diferentes, mas perde construções depois do reinício, o salvamento está incorreto.
• Se os animais continuam atacando indiscriminadamente, a IA não foi corrigida.
• Se os botões de clima desaparecem, mas jogadores ainda alteram o clima por comandos, o problema não foi resolvido.
• Se a interface continua exibindo informações de depuração e instruções de controles, a reformulação está incompleta.
• Se o jogo abre em janela que não ocupa a tela corretamente, o problema de resolução continua.
• Se os gráficos melhoram só pela iluminação e os modelos continuam sendo formas primitivas, a reconstrução visual está incompleta.
• Se as árvores ainda parecem esferas verdes ou a grama ainda são triângulos simples, a reconstrução falhou.
• Se um preset gráfico muda sozinho depois de alguns minutos, o bug principal não foi corrigido.
Não marque nenhum requisito como concluído sem verificá-lo. Se alguma implementação estiver incompleta, continue trabalhando nela antes de considerá-la finalizada.
19. TESTES OBRIGATÓRIOS
Execute testes práticos reais e relate o resultado de cada um.
1. Visual: árvores sem aspecto de esfera, grama melhor, personagem e animais aprimorados, iluminação natural, água melhorada, vegetação variada, HUD organizada, sem instruções de controles na tela, sem ferramentas de clima para jogadores comuns. Gere capturas de tela comparativas, se possível.
2. Tamanho do mapa: meça a área original e a nova; confirme pelo menos 600% e exploração sem barreiras, regiões ausentes ou quedas de desempenho.
3. Geração procedural: crie três mundos; confirme seed própria, terrenos, rios, florestas, cavernas e ruínas diferentes; mesmo mundo para todos os jogadores; reinício sem mudar o mapa; construções preservadas.
4. Coleta: madeira aparece no chão ao cortar a árvore; animação correta ao coletar; repetir com pedras, minérios, frutas e carne.
5. Construção: casa com paredes, porta e telhado; recursos consumidos; colisão; proteção da chuva; visível para outros jogadores; persiste após o reinício.
6. Clima: como jogador comum, não é possível alterar o clima; mudanças naturais sincronizadas; 40 s de proteção e 1 de vida a cada 15 s; recuperação, abrigos e fogueiras.
7. Configurações gráficas: passo a passo da seção 3, repetido para todos os presets.
8. Tela cheia, janela e janela sem bordas: resolução correta, interface adaptada, nada cortado.
9. Multiplayer: duas ou mais instâncias; movimentação, coleta, combate, construção, clima, chat, animais e persistência. Se não for possível, informe a limitação.
10. Segurança: tente explorar o próprio servidor (mensagens forjadas, dano falso, recursos falsos, comandos admin) e confirme que são rejeitados.
11. Longa duração: deixe o jogo rodando 30 minutos e verifique estabilidade, memória e FPS.
12. Instalador: instale, abra, jogue, desinstale.
20. RELATÓRIO FINAL OBRIGATÓRIO
A. Funcionalidades implementadas: o que foi realmente alterado e em quais arquivos.
B. Problemas corrigidos: causa de cada problema e solução, especialmente o bug das configurações gráficas.
C. Melhorias visuais: terreno, árvores, grama, água, personagens, animais e iluminação.
D. Testes executados: quais foram realmente feitos, resultados e evidências (logs, números de FPS, capturas).
E. Problemas novos encontrados na auditoria: lista classificada por gravidade, indicando o que foi corrigido e o que ficou pendente.
F. Funcionalidades pendentes: o que não foi concluído e por quê. Não apresente recursos incompletos como se estivessem funcionando.
21. INSTRUÇÃO FINAL
EU QUERO QUE O TRIBES OF FIRE DEIXE DE PARECER UM PROTÓTIPO E PASSE A PARECER UM JOGO DE SOBREVIVÊNCIA INDEPENDENTE BEM PRODUZIDO.
Mapa grande, bonito e procedural; florestas densas, árvores melhores, grama natural, animais agradáveis, água bonita, cavernas, ruínas e lugares que incentivem a exploração; personagens com boas animações; coleta, construção, alimentação e sobrevivência funcionais; clima automático e compartilhado, sem opções públicas de alteração; interface limpa e profissional; presets gráficos que permanecem salvos; tela cheia funcionando no Windows.
Mais importante: quero que tudo seja implementado de verdade, testado e integrado às cenas reais do projeto, não apenas descrito.
Comece agora pela auditoria da seção 1, apresente o diagnóstico com os problemas encontrados e então siga corrigindo por ordem de gravidade, verificando após cada etapa.
Créditos do projeto: felipealx.
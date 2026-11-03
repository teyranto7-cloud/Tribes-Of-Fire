Prompt complementar (Parte 2) — Tribes of Fire
Créditos do projeto: felipealx
Este prompt complementa o prompt principal de reconstrução e auditoria. Tudo o que está lá continua valendo (regras de trabalho, auditoria inicial, bug dos presets gráficos, mapa 6×, geração procedural, segurança, testes e relatório). Aqui entram os sistemas, a profundidade de jogabilidade e a camada de produção que faltam para o jogo parecer completo. As seções continuam a numeração a partir da 22.
22. REGRAS ADICIONAIS DESTA PARTE
1. Antes de começar, leia o relatório da auditoria da Parte 1 e confirme o que já foi corrigido. Não refaça o que já funciona e não quebre o que já foi testado.
2. Cada sistema novo precisa estar conectado ao jogo real: aparecer nas cenas, ter interface, ser salvo, ser sincronizado no multiplayer e passar por teste prático.
3. Todo valor de balanceamento (tempos, danos, custos, taxas) fica em arquivos de dados (recursos .tres ou JSON), nunca espalhado pelo código.
4. Todo texto vai para o sistema de tradução. Não deixe frases fixas no código.
5. Ao terminar cada seção, rode o jogo, confira o console e atualize a lista de pendências.
6. Se um sistema for grande demais para a etapa, entregue uma versão mínima funcional e registre o restante como pendência. Nunca entregue casca vazia.
7. Continue procurando defeitos por conta própria. Tudo o que encontrar e não estiver nesta lista entra no relatório com gravidade.
23. PROGRESSÃO E ÁRVORE DE TECNOLOGIA
O jogo precisa de um motivo para continuar jogando. Crie uma progressão coerente com o tema pré-histórico.
• Eras da tribo: Sobrevivência (mãos nuas, galhos, pedras), Pedra Lascada, Fogo e Cerâmica, Ossos e Peles, Metal Primitivo (cobre e bronze, se couber no tema), cada uma liberando receitas, construções e ferramentas.
• Conhecimento por uso: o jogador aprende fazendo (cortar madeira melhora a eficiência com machado, cozinhar desbloqueia receitas), com experiência por habilidade: coleta, caça, construção, cozinha, combate, artesanato, resistência ao frio.
• Pesquisa da tribo: locais como a fogueira central ou o totem permitem investir recursos para liberar tecnologias para todos os membros.
• Árvore visível na interface, com requisitos, custo e descrição, salva por jogador e por tribo.
• Balanceamento: uma sessão de 30 minutos deve mostrar progresso real (primeira ferramenta, primeira fogueira, primeiro abrigo), e uma sessão de 10 horas deve ter metas novas.
• O servidor valida experiência, desbloqueios e custos.
24. ARTESANATO E ECONOMIA DE RECURSOS
• Receitas organizadas por categoria (ferramentas, armas, roupas, comida, construção, decoração), com ingredientes, tempo, estação exigida (bancada, fogueira, forja de pedra, curtidor) e resultado.
• Fabricação com barra de progresso e animação do personagem, cancelável sem perder recursos.
• Fila de fabricação em bancadas, com resultado entregue no inventário ou em um compartimento de saída.
• Qualidade de itens (comum, bom, excelente) influenciada pela habilidade, e durabilidade com desgaste e reparo.
• Itens decompostos em materiais, quando fizer sentido, sem permitir loops infinitos de lucro de recursos.
• Peso e capacidade do inventário, bolsas e mochilas que ampliam espaço, baús com capacidade limitada.
• Itens perecíveis (carne e frutas estragam, comida cozida dura mais, sal e defumação conservam).
• Mapa completo de recursos por bioma, para que cada região tenha algo valioso e incentive a exploração e o comércio entre jogadores.
• Auditoria: verifique que nenhuma receita fica impossível por falta de recurso no mundo gerado, e que nenhum item pode ser duplicado por trocas, fila de fabricação ou salvamento.
25. CAÇA, PESCA, AGRICULTURA E DOMESTICAÇÃO
25.1 Caça
• Armas de caça (lança, arco primitivo, funda, armadilhas de cova e de laço) com alcance, dano e ruído diferentes.
• Rastros e pegadas que levam aos animais, e animais que reagem ao cheiro, ao barulho e à luz de fogueiras.
• Abate rende carne, pele, ossos, tendões e gordura, com esfolar e processar como ação própria com animação.
• Rastreamento de animal ferido e fuga com sangue no chão.
25.2 Pesca
• Pesca com lança, anzol de osso e rede, com minijogo curto e opcional, peixes por bioma e por hora do dia.
• Peixes visíveis na água com animação e comportamento próprio.
25.3 Agricultura simples
• Coleta de sementes, canteiros, crescimento por tempo e clima, rega pela chuva, colheita e replantio.
• Plantas que morrem no frio extremo ou em seca, e cercas contra animais.
25.4 Domesticação
• Animais passivos podem ser alimentados e domesticados (cão-lobo, cabra, javali jovem), com lealdade, fome e carga.
• Companheiros seguem, ajudam a carregar, alertam sobre perigos e podem ser guardados em currais.
• Dados salvos e sincronizados no multiplayer; o servidor controla a IA.
26. COMBATE
• Combate corpo a corpo com golpe leve e pesado, bloqueio, esquiva, resistência (stamina) e recuo, com janelas de acerto claras e animação coerente com a arma.
• Armas à distância com trajetória real, queda e munição recuperável.
• Tipos de dano (cortante, perfurante, contundente, fogo, frio) e armaduras de couro, pele e osso com resistências diferentes.
• Sangramento, fratura e ferimentos graves com tratamento (bandagem de fibra, talas, ervas), sem tornar o jogo punitivo demais.
• Câmera e áudio de impacto, números de dano discretos (opcionais) e indicador de direção do ataque.
• PvP configurável por servidor (ligado, desligado, apenas entre tribos em guerra).
• Servidor valida alcance, cadência, linha de visão e dano. Latência compensada de forma simples e justa.
• Morte: perda parcial de itens configurável por servidor, mochila de morte no local, renascimento em cama, fogueira ou ponto de tribo, com tempo de espera curto.
• Teste: duelo entre dois clientes, combate contra cada tipo de animal e verificação de que o dano não pode ser forjado.
27. ESTAÇÕES, TEMPERATURA E AMBIENTE
• Ciclo de dia e noite com duração configurável e transições suaves (amanhecer e entardecer).
• Estações do ano opcionais (verão, outono, inverno, primavera) com mudança visual de folhagem, neve, disponibilidade de comida e animais migratórios.
• Temperatura ambiente por bioma, hora, clima e altitude, com resistência por roupas, abrigo, fogueira e comida quente.
• Efeitos de frio e calor com sintomas progressivos (tremor, visão, lentidão), sempre respeitando as regras já definidas para a chuva fria: 40 segundos de proteção inicial e 1 ponto de vida a cada 15 segundos depois.
• Eventos naturais raros e dosados: tempestade de neve, neblina densa, seca, chuva forte, aurora, eclipse e erupção distante nas regiões vulcânicas, todos decididos e sincronizados pelo servidor.
• Cavernas com temperatura própria, escuridão real (exigindo tochas) e morcegos, ecos e gotejamento.
• Fogo avançado: propagação limitada em grama seca e madeira, controlada por configuração do servidor, e apagada pela chuva.
28. TRIBOS EM PROFUNDIDADE, NPCs E MUNDO VIVO
• Papéis na tribo (líder, caçador, construtor, curandeiro) com permissões e bônus pequenos.
• Território da tribo marcado por totem, com construções protegidas e regras de acesso.
• Diplomacia entre tribos: paz, aliança, guerra e comércio, com efeitos reais em PvP e acesso a territórios.
• Baú compartilhado da tribo, registro de ações e proteção contra abuso de membros novos.
• NPCs opcionais: acampamentos de tribos neutras ou hostis espalhados pelo mundo procedural, com rotina (cozinhar, patrulhar, dormir), troca de itens e reação à aproximação do jogador.
• Pontos de interesse únicos por mundo: santuários, cavernas com pinturas rupestres, cemitérios antigos, ruínas misteriosas, com recompensas e história curta contada por pinturas e objetos, sem textos longos na tela.
• Cada ponto de interesse deve parecer feito à mão, com variação de peças, e não repetir o mesmo molde de forma óbvia.
29. TUTORIAL, ONBOARDING E OBJETIVOS
• Tutorial curto e opcional, integrado ao mundo, com dicas contextuais discretas que desaparecem sozinhas (por exemplo, ao chegar perto de uma árvore pela primeira vez).
• Nada de painel fixo de teclas na HUD. As teclas ficam em uma tela de ajuda do menu.
• Objetivos suaves de longo prazo: construir o primeiro abrigo, acender a primeira fogueira, sobreviver à primeira tempestade, domesticar um animal, explorar uma caverna, fundar uma tribo.
• Diário do jogador com receitas conhecidas, descobertas, mapa explorado e conquistas, com ícones próprios.
• Conquistas locais (sem dependência de plataforma externa) e estatísticas básicas.
30. MAPA, BÚSSOLA E NAVEGAÇÃO
• Mapa do mundo que se revela conforme o jogador explora, desenhado a partir do terreno real do mundo procedural, com biomas, rios, marcadores e fogueiras visitadas.
• Marcadores personalizados, com nome e cor, e compartilhados com a tribo.
• Bússola discreta na HUD, com pontos de interesse apenas quando descobertos.
• Viagem rápida opcional apenas entre fogueiras da tribo, com custo e tempo de espera, desligável por servidor.
• O mapa precisa funcionar para o tamanho novo (6×), sem travar nem consumir memória demais.
31. CÂMERA, CONTROLES E ACESSIBILIDADE
• Câmera em terceira pessoa com colisão contra terreno e paredes (sem atravessar), suavização, zoom e opção de primeira pessoa.
• Controles totalmente remapeáveis, salvos nas configurações, com detecção de conflito entre teclas.
• Suporte a controle (gamepad) com zonas mortas ajustáveis e interface navegável sem mouse.
• Sensibilidade do mouse, inversão de eixo, campo de visão e balanço de câmera configuráveis, incluindo opção de desativar balanço e tremores.
• Acessibilidade: tamanho de texto, contraste alto, opções para daltonismo, legendas para sons importantes e redução de efeitos de flash.
• Idiomas: verifique que cada texto aparece traduzido e cabe nos botões em todos os idiomas, inclusive os mais longos.
32. ÁUDIO E MÚSICA
• Barramentos separados (geral, música, efeitos, ambiente, vozes e interface) com sliders salvos.
• Música dinâmica por bioma, hora, perigo e clima, com transições suaves e silêncios intencionais.
• Sons de passos por superfície (grama, terra, pedra, areia, neve, madeira, água), de ferramentas, combate, animais, fogo, chuva (mais abafada sob telhado), vento, rios e cavernas.
• Áudio espacial com atenuação e reverberação em cavernas.
• Garanta que nenhum som toque em loop errado, estoure o volume ou fique mudo depois de trocar de cena.
33. SERVIDORES, ADMINISTRAÇÃO E MULTIPLAYER AVANÇADO
• Servidor dedicado sem interface, iniciado por linha de comando, com arquivo de configuração (porta, nome, senha, máximo de jogadores, seed, PvP, perda ao morrer, duração do dia, taxa de recursos, dificuldade).
• Painel e comandos administrativos acessíveis apenas com autenticação e autorização verificadas no servidor (lista de administradores por identificador, não por nome), com expulsar, banir, silenciar, salvar, reiniciar, ver jogadores e alterar regras do servidor, e registro de tudo o que foi feito.
• Lista de servidores com nome, jogadores, ping e versão, e bloqueio de entrada por versão diferente.
• Salvamento automático do servidor, com backups rotativos e restauração testada.
• Reconexão, tempo limite de inatividade e proteção contra entrada duplicada.
• Limites de taxa de mensagens e de chat, filtro simples de spam e denúncia de jogadores.
• Ping, FPS do servidor e uso de banda visíveis apenas para administradores.
• Teste de carga: simule pelo menos 8 a 16 clientes (ou o máximo possível) e relate FPS do servidor, uso de banda e atraso percebido.
34. SALVAMENTO, MIGRAÇÃO E ROBUSTEZ
• Formato de salvamento versionado, com migração automática de saves antigos para o novo formato.
• Gravação atômica (arquivo temporário e troca) com backup do anterior, para nunca corromper o mundo em queda de energia ou fechamento forçado.
• Verificação de integridade ao carregar e mensagem clara de recuperação em vez de travar.
• Salvar apenas diferenças em relação à seed, com compressão, para que mundos grandes não gerem arquivos gigantes.
• Teste: matar o processo durante o salvamento e confirmar que o mundo carrega; carregar um save da versão anterior e confirmar a migração.
• Relatório de falha: capture erros inesperados em um arquivo de log local, sem enviar dados para fora sem consentimento.
35. OTIMIZAÇÃO PROFUNDA E PERFIL DE DESEMPENHO
• Use o profiler e o monitor do Godot para encontrar os maiores custos (física, script, renderização, rede, geração de chunks).
• Mova a geração procedural e a construção de malhas para threads ou tarefas, sem travar a thread principal.
• Cache de malhas e de colisões por chunk, descarregamento por distância e reaproveitamento de objetos (pooling).
• Física com camadas e máscaras corretas e colisões simples (caixas e cápsulas) em vez de malhas complexas.
• IA com atualização escalonada: animais distantes atualizam menos vezes por segundo, e somem da simulação detalhada quando longe de todos os jogadores.
• Reduza alocações por quadro, evite get_node e buscas em _process, e remova print pesado na versão pública.
• Orçamento por preset: informe o alvo de FPS, a distância de visão e a quantidade de objetos de cada um, e comprove com medições.
• Teste em máquina fraca (ou simule com escala de renderização baixa) e relate o resultado honestamente.
36. QUALIDADE: TESTES AUTOMÁTICOS, LINTER E CHECKLIST DE BUILD
• Crie testes automáticos onde forem viáveis (por exemplo, com GUT): geração por seed repetível, serialização de salvamento, cálculo de dano e de frio, receitas, inventário sem duplicação, validações do servidor.
• Cena de teste de fumaça que carrega o mundo, anda, coleta, constrói e salva, executável por linha de comando.
• Verificação de recursos ausentes e caminhos quebrados, e checagem de que nenhuma cena de debug é referenciada na exportação final.
• Checklist de build: versão, número de build, ícone, nome do executável, configurações de exportação, remoção de recursos de teste e conferência dos tamanhos.
• Registro de mudanças (changelog) legível para jogadores, e versão exibida no menu.
37. PREPARAÇÃO DE LANÇAMENTO: LICENÇAS, PRIVACIDADE E DISTRIBUIÇÃO
• Licenças: liste todos os recursos de terceiros (modelos, texturas, sons, músicas, fontes, plugins) com fonte e licença. Remova ou substitua qualquer coisa sem direito claro de uso. Não use material copiado de outros jogos.
• Tela de créditos completa, com felipealx como crédito do projeto, e um arquivo LICENSES ou THIRD_PARTY dentro do pacote.
• Privacidade: o jogo não deve coletar dados pessoais sem aviso e consentimento. Se houver qualquer telemetria ou relatório de falha, ela deve ser opcional, anônima e explicada em linguagem simples.
• Idioma de termos de uso e política de privacidade nos idiomas suportados, caso o jogo seja distribuído em lojas.
• Material de divulgação: capturas de tela limpas, ícone, banner, descrição curta e longa, lista de recursos e requisitos mínimos e recomendados medidos de verdade.
• Assinatura do executável e do instalador, se houver certificado disponível, e aviso honesto sobre alertas do Windows caso não haja.
• Verificação do instalador em Windows limpo (máquina virtual, se possível) sem Godot instalado, incluindo atualização sobre uma versão anterior e desinstalação sem deixar lixo.
38. REVISÃO FINAL DE PRODUÇÃO
Antes do relatório, faça uma revisão como se fosse um jogador novo.
1. Instale o jogo do zero e escolha o idioma.
2. Crie um personagem e um mundo novo.
3. Jogue por 30 minutos sem pausar: colete, fabrique, construa, cace, sobreviva a uma chuva e a uma noite.
4. Saia, reabra e continue o mesmo mundo.
5. Entre em um servidor com outro jogador e repita as ações principais.
6. Anote tudo o que parecer confuso, feio, lento, quebrado, injusto ou chato, e corrija ou registre.
As perguntas finais são: o jogo parece um protótipo? Há texto técnico na tela? Alguma tecla ainda aparece fixa na HUD? Existe algum caminho para trapacear? Algum sistema anunciado não aparece de verdade no jogo?
39. TESTES OBRIGATÓRIOS DESTA PARTE
• Árvore de tecnologia: desbloquear uma era e confirmar que receitas e construções novas aparecem e persistem.
• Artesanato: fabricar com fila, cancelar, reparar, e tentar duplicar item (deve falhar).
• Caça, pesca e agricultura: um ciclo completo de cada (obter, processar, consumir, replantar).
• Domesticação: domesticar um animal, salvar, reabrir e confirmar que ele continua leal.
• Combate: duelo entre dois clientes, defesa, esquiva, morte e renascimento.
• Estações e eventos: forçar apenas em ambiente de desenvolvimento e confirmar sincronização entre clientes; em build público, nenhum jogador comum consegue acionar.
• Mapa: explorar uma região, abrir o mapa, marcar um ponto, compartilhar com a tribo.
• Controles: remapear teclas, usar controle e confirmar que tudo é salvo.
• Acessibilidade: ativar contraste alto, texto grande e legendas.
• Servidor dedicado: iniciar por linha de comando, entrar, banir, reiniciar e conferir que o mundo continua.
• Salvamento: interromper durante a gravação e migrar um save antigo.
• Desempenho: tabela com FPS por preset e por situação (floresta densa, cidade grande, caverna, tempestade).
• Licenças: conferir que todos os recursos estão listados nos créditos.
40. RELATÓRIO FINAL DESTA PARTE
Acrescente ao relatório da Parte 1:
G. Sistemas novos implementados: o que foi criado, em quais arquivos e como se conecta ao jogo.
H. Balanceamento: valores escolhidos, onde ficam e por que, com observações de jogo real.
I. Medições de desempenho: FPS, memória, rede e tempo de geração, antes e depois.
J. Segurança e administração: o que foi validado no servidor, como foi testado e o que ainda é um risco.
K. Produção e lançamento: licenças, créditos, instalador, privacidade e estado de cada item.
L. Pendências e limitações: o que não foi feito ou testado e por quê, sem apresentar nada incompleto como funcionando.
41. INSTRUÇÃO FINAL DA PARTE 2
Quero que o Tribes of Fire tenha profundidade de jogo de sobrevivência de verdade: progressão, artesanato, caça, pesca, agricultura, domesticação, combate, estações, tribos vivas, exploração e um mundo que dê vontade de percorrer.
Quero também a camada de produção que separa um protótipo de um jogo publicável: servidor administrável, salvamento robusto, desempenho medido, acessibilidade, licenças em ordem e instalador testado.
Mais importante: tudo implementado, conectado às cenas reais, testado e relatado com honestidade. Não afirme que algo funciona sem ter visto funcionar.
Continue trabalhando por etapas, verificando após cada uma, e mantenha a lista de pendências atualizada até o fim.
Créditos do projeto: felipealx.
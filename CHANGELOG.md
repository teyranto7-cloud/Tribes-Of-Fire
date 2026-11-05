# 0.9.0-dev — Fase 4

- 39 peças modulares, seis materiais, catálogo/favoritos, fantasmas e sockets.
- Tiers/reparo, aparência/nome/acesso, recolocação e demolição com revisão e restituição atômica.
- Cimento com areia; concreto com agregados; kits restituem ingredientes proporcionais.
- Cache por chunk separado dos registros; IDs persistidos e teste de 3.000 estruturas.
- Corrigidos cultivo perdido ao descarregar, porta bloqueada pela própria colisão,
  dupla aplicação de altura no encaixe e colisão ainda não atualizada no mesmo tick.
- Folha de porta encaixável, abertura para longe do jogador e proteção do vão.
- Degraus e rampas com transição de colisão contínua para caminhar sem pular.
- Menus evitam notificações/chat sobre os controles da construção.
- Bancadas vazias desconectadas mantêm índice, orientação e revisão ao mover/recarregar.

# 0.8.0-dev

- Conserva faces ao unir malhas indexadas/não indexadas; corrige partes invisíveis.
- Melhora menu, HUD, mapa, 17 oficinas e pickups por família.
- Adiciona energia fluvial, cabos, postes, luzes, motores, esteiras e receitas correspondentes.
- Adiciona trocas com consentimento/atomicidade, canal de aliados e pings privados da equipe.
- Preserva saves antigos, saúde/chuva, crafting, rede e pacotes anteriores.
- Testes de atualização nativa entre versões e matriz de pedidos/pendências.

# Mudanças — Tribes of Fire

## 0.7.1-dev — auditoria de regressão das Fases 1–3

- Recibos persistidos para operações de bancada e cancelamento identificado por job.
- Corrigidos desbloqueios, capacidade de entrada e comandos antigos ao carregar.
- Controles existentes exibem motivo de bloqueio sem adicionar sistemas ou catálogo.
- Testes de dois ciclos em rede, cancelamento entre mouse-down/up, chat/áudio
  sintético em três distâncias, 50 startups e comparação de desempenho.
- Catálogo, gerador, modelos e recursos publicados preservados.

## 0.7.0-dev — itens, receitas, coleta e bancadas

Catálogo de 100 itens e 89 receitas em JSON, 17 bancadas com buffers persistidos,
coleta por dureza/ferramenta, stacks e peso. Fabricação e entrega atômicas com
deduplicação, cancelamento integral e retomada após desconexão/reinício.
Dois ciclos reais e evidências em Docs/PHASE3_REPORT.md.

## 0.6.0-dev — continuidade das Fases 1 e 2

Gerador 3 preservando saves anteriores, streaming de todo o mapa e transição de
terreno por chunks instalados; vale com travessias/cascata, regiões e trilhas.
Mochila, split/descarte físico, baús com durabilidade, atalhos 1–9, minimapa e
navegação com zoom/pan. Evidências e limites em Docs/CONTINUITY_REPORT.md.

Criado por **felipealx**.

## 0.5.0-dev — mundo ampliado e progressão jogável

- Corrige faces invertidas de modelos, golpe frontal, troca entre ferramenta e
  construção, percentuais de ações e prazo CLI de execução após inicialização.
- Novo inventário em abas, busca, custos, motivos de bloqueio e fila de produção.
- Recursos com fontes de obtenção, plantas, medicina, materiais processados e
  equipamentos de prata/ouro com receitas reais.
- Gerador de 1536 × 1536 m, oito monumentos regionais, 96 animais, floresta distante,
  flores/vegetação e rio navegável. Saves antigos mantêm o gerador anterior.
- Jangada conduzível, escavação superficial persistente e três máquinas produtivas.
- Diplomacia entre líderes, alianças/paz/guerra e trégua após romper aliança.
- Suíte completa: 564 verificações, 0 falhas; seis verificações dos exports Linux.
  Confira Docs/PLAYABILITY_REPORT.md para evidências e limitações da prévia.

## 0.4.0-dev — reconstrução em validação

A reconstrução parte da0.3.1 preservada em Downloads. O relatório de execução
identifica quais mudanças foram integradas e testadas; a existência desta seção
não declara aprovação de todos os requisitos.

- Empacotamento de fontes passa a respeitar arquivos ignorados e excluir perfis,
  credenciais e chaves, inclusive se adicionados ao Git por engano.
- Documentação de privacidade, componentes de terceiros e estado de lançamento
  acompanha os pacotes. Relatórios/imagens de auditoria são excluídos do PCK.
- QA Windows seleciona pacotes por versão e valida descritores de mundo/schema4.
  Atualização entre versões distintas e migração no Windows ainda precisam execução real.

Consulte PROGRESS.md para as alterações de jogabilidade, gráficos, mundo,
segurança e resultados observados nesta revisão.

## 0.3.1-dev

Correções de movimento após morte, durabilidade de itens descartados, oclusão de
coleta, cozimento com inventário cheio, configurações malformadas, LOD e fechamento
no carregamento. Fortalecimento de saves/identidades, relógio monotônico e fila de
voz. Suíte de372 verificações e seis checks dos binários Linux; execução Windows
headless aprovada. Voz sob carga, gráficos Windows e hardware alvo não certificados.

## 0.3.0-dev

Primeira entrega integrada de personagens personalizáveis, seis idiomas, inventário
com espaços, equipamentos, sobrevivência, animais, mineração, combate, tribos,
texto/voz opt-in, perfis gráficos e instalador multilíngue. Mundo128×128m com seed
fixa; versão de desenvolvimento, requisitos1.0 incompletos.

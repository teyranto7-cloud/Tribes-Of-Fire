# Entrega 0.7.0-dev — 04/11/2026

Criado por **felipealx**. A base atual do GitHub (634f07e) foi preservada, incluindo
100 itens, 89 receitas, 17 bancadas, gerador 3, navegação e progressão da Fase 3.

Correções desta revisão: pacotes tardios de rede/áudio ignorados ao sair, pickup
mais próximo acessível junto de baú, contexto do baú mantido ao atualizar canais,
tradução inglesa e viewport adaptado à janela real.

Suíte completa: **4209 checks / 0 falhas**. As nove regressões novas passaram;
ENet com dois clientes, replay, reconexão e reinício passou; binários Linux/servidor
passaram seis checks. GUI: 34 checks, sete capturas reais e três resoluções.
Instalador e ZIPs são vinculados ao recibo de fontes/binários; resultados de pacote
extraído e QA Windows estão em [Docs/DELIVERY_0.7.md](Docs/DELIVERY_0.7.md).

O histórico abaixo é preservado. Esta entrega não conclui 1.0, arte final,
energia/esteiras, hardware físico ou carga de 100 jogadores.

# Progresso — 0.5.0-dev

Criado por **felipealx**. Continuação da 0.4.0-dev no mesmo projeto Godot 4.6.3.
Histórico anterior preservado em Docs/verification/0.4.0-dev/PROGRESS.md.

## Correções e implementações

- Malhas esculpidas estavam com normais/faces invertidas: reprodução comparou
  BoxMesh (+0,5) com malha original (-0,661). A ordem dos triângulos foi corrigida;
  personagens, animais e vegetação passam a renderizar suas faces externas.
- Passos com transição mais suave, golpe frontal corrigido, pose de remar e
  máquinas com engrenagem animada. Padrão da roupa menos ruidoso.
- Inventário em abas, busca, receitas por progressão, custos com quantidades
  atuais, motivo de bloqueio, fila/cancelamento e dicas de obtenção.
- Equipar uma ferramenta limpa a construção antes selecionada. Progresso visual
  da ação foi corrigido para exibir percentuais intermediários.
- Catálogo com fontes de obtenção: ervas/flores, terra/argila/areia, água coletável,
  tábuas, cordas, tecido, tijolos, vidro, prata/ouro refinados e receitas associadas.
  Curativo, chá e kit medicinal consomem itens e curam; arma/armadura novas usam
  prata/ouro/minério raro em progressão real. Recursos históricos mantêm seus IDs.
- Novo gerador 2 de 1536 × 1536 m, seed aleatória por mundo (ou explícita), oito
  monumentos regionais, caverna/ruínas, relevo e margens acessíveis. Geradores 0/1
  continuam preservados para saves antigos. Horizonte e floresta distante usam LOD;
  terreno/colisão seguem chunks. Até 16 mil registros de árvores e 96 animais novos.
- Flores decorativas e plantas coletáveis; vegetação, animais, clima e relógio
  continuam ativos. Dia 30 min/noite 15 min; iluminação de lua/fogo/tocha/lamparina.
- Jangada física construída na água: embarque, remo/direção autoritativos,
  bloqueio de terra/obstáculos, desembarque e persistência. Respawn libera a jangada.
- Pá e escavação superficial persistente (máximo 4 m), com atualização de colisão,
  altura, material recebido, durabilidade e validação pelo servidor. Samplers
  alterados são substituídos por cópias imutáveis para não disputar com workers.
- Serraria/tear/britador: entrada, tempo e saída, abastecimento e retirada atômicos,
  propriedade e persistência. Replicação preserva os nós em vez de recriar a
  engrenagem a cada snapshot. Estado interno é filtrado para outros jogadores.
- Tribos com solicitações/aceite de alianças/paz, guerra, aviso global, bloqueio
  aliado e trégua de uma hora ao romper aliança. PvP opcional war; proteção anterior
  de 300 s foi preservada. Relações são validadas e persistidas.
- Headless evita as malhas cosméticas de horizonte/vegetação distante e reutiliza
  sons por espécie. Isso reduz trabalho de inicialização; não é benchmark de GPU.

## Validação

Tests/test_playability.gd acrescenta verificações de faces, catálogo obtenível,
mapa/rio, UI, cura/craft, terreno e colisão, fábrica/conservação, jangada/respawn,
diplomacia/trégua, dia/noite e salvamento: **106 verificações, 0 falhas**.
Suíte final completa: **564 verificações, 0 falhas**, Godot 4.6.3. Três exports
gerados (Windows, Linux e dedicado Linux), vinculados ao recibo de fontes/binários.
Cliente Linux, dedicado e reinício passaram **6 verificações**, sem editor.
Servidor e dois clientes passaram movimento/coleta compartilhada e persistência.
Logs e recibo em Docs/verification/0.5.0-dev; detalhes em Docs/PLAYABILITY_REPORT.md.
As 50 aberturas/continuações reais passaram em 178,36 s, sem erro/leak observado.
ZIP de fontes passou importação e jogo/save em diretório limpo (2 checks).
Cliente Linux exportado abriu graficamente por 5 s em llvmpipe. Instalador NSIS
e quatro ZIPs foram gerados e verificados com manifesto SHA256. QA Windows nativo
0.5 aprovado: https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41560599160 .
Instalação/atalhos/runtime headless/restauração/reinstalação/uninstall passaram
em 24 verificações. Prévia v0.5.0-dev publicada com cinco downloads fixados no
commit b8bedca; todos responderam HTTP 200 com tamanho correto. Fase 0 do novo
plano concluída no escopo observado; próxima fase tecnicamente liberada,
sem execução automática.
Não transferir automaticamente resultados 0.4 para uma revisão modificada.

A inspeção gráfica usou display virtual Mesa llvmpipe; imagens reais de personagem,
craft, rio/jangada, horizonte e dia/noite. Isso confirma renderização observada,
sem certificar arte final ou desempenho do hardware alvo.

Um fixture antigo esperava 12 animais, mas novos mundos têm 96; a asserção foi
atualizada preservando validação das seis espécies e serialização. Outro fixture
usava teardown manual e detectou WAV pendente sob carga: passou a exercitar o
shutdown real com liberação verificada do mixer. Nenhuma asserção foi removida.
Um cenário multiplayer sob tarefas simultâneas falhou no prazo; repetição isolada
passou após reduzir trabalho cosmético em headless. Um teste de export detectou
que o prazo CLI incluía a inicialização; corrigido para contar tempo real após
GAME_READY. A repetição dos seis checks de export passou. Isso não prova carga.

## Ainda falta

Não há promessa de 100% ou versão 1.0. São MVPs: escavação de superfície, jangada,
três máquinas, diplomacia básica. Faltam catálogo integral proposto, esteiras/
energia/automação complexa, navios, mundo volumétrico, cercos/territórios completos,
arte e animações finais, revisão linguística, QA amplo de hardware/dispositivos,
carga de 8–100 jogadores, 30 min prolongados e recursos restantes em Docs/PENDENCIAS.md.
O espaço para oito tribos é uma decisão de mapa, não um resultado de teste de carga.

Guia para jogar em Docs/PLAYABILITY.md. Nenhum asset de Roblox foi copiado.

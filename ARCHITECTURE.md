# Atualização de arquitetura — 0.5.0-dev

Mesma cena Main e módulos da 0.4, sem troca de engine. Godot executado: 4.6.3
padrão. project.godot conserva a compatibilidade histórica 4.3 e GL Compatibility.

## Entrada, cena e dados

`Scenes/Main.tscn` contém um Node com `Main.gd`. A maior parte da árvore 3D/UI é
criada por código: World (chunks, recursos, árvores, ambiente e estruturas),
Session, Runtime, câmera de menu, HUD/painéis, chat, overlay e jogadores.
O único autoload é `Settings → Settings/Manager.gd`. Não há plugin de editor ou
extensão nativa externa no inventário atual. As cenas geradas não são cenas
estáticas separadas que precisem ser recriadas.

Main coordena ciclo/rede/persistência; Runtime valida comandos de gameplay;
World apresenta e consulta espaço/terreno; Inventory/Vitals/Catalog/Balance,
Tribes e Factory mantêm regras/estado. UI transmite intenções e apresenta
resultados. `Data/Balance.json` centraliza receitas/estações/progressão nova;
catálogos legados ainda precisam de centralização adicional.

Session emite `peer_joined`, `peer_left`, `intent_received`, `action_received`,
`command_received`, `state_received`, `failed` e `admin_requested`. Main conecta
esses sinais; apenas a autoridade executa a fila de comandos e simulação. Um
cliente envia intenção/ID, nunca define seu próprio inventário ou dano. Snapshots
filtram inventários, máquinas e campos privados conforme proprietário/permissão.

Saves schema 4 contêm descritor de gerador/seed, jogadores, relógio/clima e módulos
validados. Novos campos opcionais preservam leitura de saves anteriores. Dois
slots alternados, SHA256, temporário verificado e lock recusam corrupção e escrita
concorrente. Preferências/identidade ficam em user://, fora dos pacotes.

Assets originais usam geometria procedural, shaders e 20 WAV sintetizados. A fonte
externa é Noto CJK; manifesto/licenças em THIRD_PARTY.md e LICENSES. Exports release
Windows/Linux/dedicado excluem testes, ferramentas, documentos, perfis e segredos.
O empacotamento exige recibo de fontes/binários; NSIS e ZIPs incluem atribuições.

## Incrementos 0.5

- Terrain: gerador 2 tamanho 1536, preservando 0/1. Edits de altura em malha 4 m são
  copiados para novo sampler imutável. Chunks e colisão são reconstruídos após
  alteração. Horizonte/floresta distante são visuais e não substituem física.
- Mining: 158 IDs estáveis, 22 originais preservados, recursos/ervas/flores adicionais,
  visibilidade por terreno carregado, rebrota e ações de servidor.
- Factory: estado input/output/progress validado, receitas fixas, produção em
  servidor ativo, transferências atômicas e filtro de inventário por proprietário.
- Building/Piece: jangada, tocha e lamparina. Jangada movimentada por intenções
  validadas no Player, com limites de água/obstáculos. Replicas atualizam posição
  sem recriar geometria. Não há simulação hidrodinâmica avançada.
- Tribes: relações por par, pedido/aceite, guerra/paz, trégua UTC 3600 s, proteção
  aliada. Proteção de saída/expulsão 300 s permanece. Dados são autoritativos.
- UI: abas Mochila/Fabricação/Construir, busca, custos, motivos e fila; painéis
  de máquina e diplomacia. Novos textos PT/EN; revisão dos seis idiomas pendente.
- Persistence: schema 4 mantido com descritor 0/1/2 e campos novos opcionais
  validados. Saves 0.4 não mudam de mapa. Crescimento de catálogo não altera IDs
  históricos. Escavação/máquinas/jangada/alianças são salvos em snapshots existentes.

Não há WAL/fsync nem garantia contra queda de energia. Rede ainda ENet experimental,
sem capacidade 100 jogadores comprovada ou autenticação comercial. Limites completos
em PROGRESS.md e Docs/PENDENCIAS.md. A arquitetura anterior está no histórico Git.


## Continuidade da entrega 0.7

A base GitHub 634f07e permanece fonte de verdade para gerador, itens, receitas,
estações e APIs da Fase 3. Runtime prioriza pickups acessíveis mais próximos de
estruturas; atualizações de canais conservam o baú aberto. Após Main.quitting,
snapshots/eventos/playback são descartados antes de acessar emissores liberados.
O viewport acompanha o tamanho real da janela. Tests/test_delivery_regressions.gd
reproduz esses limites; Tools/capture_delivery.gd verifica entrada real e produção.


## Correções da auditoria 0.7.1

Pedidos da UI de crafting/estação têm request_id; Session valida metadados opcionais.
Runtime deriva recibos por operação, usando o histórico persistido de 128 pedidos
por jogador. Activities dá uid estável aos jobs, migra filas antigas e cancela pelo
uid, inclusive quando o índice mudou. O botão guarda o uid mostrado em button_down,
evita cancelar outro job em mouse-up e envia a intenção à autoridade.
station_reason/recipe_unlock_reason são a única validação de pré-condições para
UI e operação; transferência real continua atômica. A projeção de capacidade usa
uma cópia de Inventory. _begin_authority limpa comandos anteriores ao snapshot.
Não houve alteração de gerador, catálogo, renderer, voz ou modelos nesta auditoria.


## Continuidade 0.8.0-dev

Energy/Grid é o grafo autoritativo de geradores/aparelhos/cabos/motores; Presentation
mantém colisões e modelos, com hash de topologia separado dos timers de esteira.
Building/Automation transfere buffers completos em passos de um item/s, validando
receita/permissões/capacidade; Runtime avança somente na autoridade. Trading/Exchange
publica ofertas imutáveis só aos participantes e efetiva ambas as cópias de inventário
juntas. Ofertas/pings expiram; inventários e energia/rotas persistem na versão 4.
Communication/TeamPings e Channels filtram relações, células descobertas e bloqueio.
World/Shapes normaliza malhas antes do batching para conservar todas as faces.
Ver Docs/SETTLEMENT_REPORT.md para integração, contratos e limites.

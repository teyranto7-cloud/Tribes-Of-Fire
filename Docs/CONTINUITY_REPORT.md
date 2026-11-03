# Continuidade — Fases 1 e 2 — 0.6.0-dev

Fonte preservada: `teyranto7-cloud/Tribes-Of-Fire222222222`, commit
`3a2d32ed192225e65d639b6009163b8dd93dd51b`. Trabalho no repositório sem números.
O histórico remoto disponível não continha os arquivos inéditos descritos na
conversa anterior. A continuidade foi reconstruída sobre a 0.5 disponível.

## Mundo

Novos mundos usam gerador 3, seed por entropia quando não informada e descrição
1536 × 1536 m. O servidor escolhe a seed; configuração administrativa explícita
continua tendo prioridade. Geradores 0, 1 e 2 permanecem separados, sem migração
silenciosa de terreno. Persistem seed, recursos colhidos, estruturas, itens e
escavação. O streaming agora usa o limite real do mundo, em vez dos antigos 320 m.
O terreno distante só é ocultado depois de existir o chunk detalhado.

Vale fluvial contínuo escavado antes da vegetação, largura/corrente variáveis,
lago conectado, quatro travessias com colisão, afluente com cascata, trilhas,
clareiras, margens férteis e distribuição regional de recursos. Regras em
[Data/Biomes.json](../Data/Biomes.json). Gruta, ruína e oito marcos regionais
permanecem limitados. Árvores têm silhuetas por espécie; vegetação e floresta
distante usam instancing, LOD e culling. O renderer Compatibility foi preservado.

## Interface

I ou Tab abre a mochila. Grade de 36 slots com ícones vetoriais por família,
contagens, busca/filtros, tooltips, comparação de ataque/proteção, equipar,
desequipar, organizar e dividir pilha. Shift + arrastar move metade. Arrastar para
fora do menu cria um pickup físico no servidor; equipamentos e itens valiosos
pedem confirmação. Slots obsoletos são rejeitados para não operar outro item.
Pickups voluntariamente descartados são públicos: qualquer jogador próximo pode
recolhê-los; regras de alcance e autoridade continuam aplicadas.

Baús permitem clique rápido, pilha inteira e arraste entre grades. Acesso exige
proximidade, visão e propriedade/permissão tribal. Equipamento guarda durabilidade,
sem conserto gratuito ao transferir. Metadados do conteúdo não entram em snapshots
públicos. Barra 1–9 configurável pela mochila, com vínculos persistidos nas opções.

Mapa M: terreno da seed, contornos de altura, água, trilhas descobertas, zoom,
pan, coordenadas opcionais, orientação, respawn, estruturas importantes e pontes
exploradas. Waypoints próprios e compartilhados com a tribo persistem. A neblina
continua ocultando terreno não explorado; grutas e minérios secretos não são
marcados automaticamente. Minimap opcional em Configurações.

Crafting mantém fila/cancelamento e busca: cada material mostra possuído/exigido,
verde/vermelho e símbolos +/!, motivo de bloqueio e estação necessária. Idioma,
acessibilidade, atalhos e minimapa usam o armazenamento existente de preferências.
Protocolo multiplayer 5: todos os peers devem usar esta revisão.

## Evidências e limites

Suíte principal final: **3.358 verificações, zero falhas, 19 runners**.
Três exportações geradas; seis verificações dos binários Linux passaram.
Os cinco artefatos em Downloads/0.6.0-dev tiveram tamanho e SHA256 conferidos.
O install_script salvo foi reexecutado com sucesso e dependências existentes.

- `Tests/test_frontier.gd`: 2.758 verificações; três seeds, 300 spawns com colisão,
  travessias, streaming remoto e reload de seed/recursos/construção/escavação.
- `Tests/test_phase2.gd`: 36 verificações; três arrastes, split, descarte/coleta,
  rejeição de operação obsoleta, confirmação valiosa, baú/durabilidade, atalhos,
  crafting, waypoint e reload sem duplicação.
- `Tools/capture_phase2.gd`: 24 verificações gráficas; mochila/craft/mapa em
  1280×720, 1920×1080 e 960×540, com screenshots reais.
- [Capturas e desempenho](verification/0.6.0-dev/): nove vistas de três seeds e
  nove vistas de interface. O JSON registra FPS, p95, memória, draw calls e chunks.
- Testes de rede e reconexão são executados separadamente da suíte principal;
  os logs desta revisão acompanham o diretório de evidências.

Medições em Mesa llvmpipe são renderização por CPU, com amostras curtas; não
certificam 60 FPS nem desempenho em GPU física. A criação inicial do mundo ainda
possui trabalho síncrono de alguns segundos; chunks de exploração são assíncronos.
Gruta/ruínas e parte da arte continuam transitórias e procedurais, sem alegação
de arte final. Não houve validação de Windows gráfico ou dispositivos físicos
nesta máquina Linux. Gerar um instalador Windows não certifica sua instalação.
Não foi simulada uma rede externa com perda/latência: ENet confiável, autoridade,
checagens de estado, testes de reconexão e reload reduzem erros, sem prometer
impossibilidade de qualquer bug sob todas as condições.

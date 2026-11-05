# Continuidade e correção de qualidade — 0.8.0-dev

Tribes of Fire · criado por **felipealx**. Base `185a463`/0.7.1-dev preservada.
Este incremento fecha caminhos jogáveis de indústria e social e corrige uma falha
visual reproduzível. Não conclui o roteiro completo da conversa.

## CONCLUÍDO E TESTADO

- **Geometria:** `Shapes.consolidate()` descartava da lista de índices as faces
  de malhas autorais ao juntá-las com primitivas indexadas. Normalizar com
  `SurfaceTool.deindex()` antes do append e reindexar o lote conserva 188/188
  triângulos nas duas ordens (antes: 108/188). Teste dedicado de oito checks.
  A suíte anterior não verificava essa conservação; passar os testes de regras
  não havia certificado a integridade visual de cada modelo.
- **Apresentação:** menu original ilustrado, HUD de vida/resistência/fome/sede,
  custos suficientes/insuficientes e progresso da bancada, mapa quadrado com
  comandos ao lado, silhuetas das 17 oficinas e pickups por família. Atalhos
  reconhecem kits de construção definidos pelos dados, incluindo a roda-d'água.
- **Energia:** geração depende da posição/corrente/profundidade de um rio real;
  cabos até 18 m custam um fio a cada 6 m; aparelhos têm dono/permissões, switches,
  demanda e sobrecarga. Motor instalado consome 40 W e acelera produção automática
  em 50%; sem energia, pausa e conserva os materiais. Produção manual anterior
  continua disponível. Luminária consome 6 W. Luzes próximas têm orçamento por preset.
- **Esteiras:** custam um kit; conectam oficinas compatíveis a até 8 m por caminho
  desobstruído. A origem precisa de motor energizado. Um item/s sai do output e
  entra no input do destino; ausência de energia/material/espaço pausa a rota.
  A cadeia serraria → carpinteiro produz kit de parede e preserva as sobras.
- **Trocas:** oferta imutável, até 6 m e com visão livre; aceite só pelo destinatário,
  transferência de ambos os inventários ou nenhuma, capacidade e desgaste verificados.
  Expira em 90 s. Sem escrow não persistido: desconexão/reinício cancela a oferta
  sem perder itens; trocas concluídas são salvas com os inventários.
- **Social:** sétimo canal de texto, aliados; pings de 20 s para tribo/aliança,
  só em células descobertas a até 250 m. Relações/bloqueios são reavaliados na
  autoridade. Ofertas e pings recebem snapshots específicos por destinatário.

## Integração e arquivos reais

| Arquivo | Métodos/nós e responsabilidade |
|---|---|
| `World/Shapes.gd` | `consolidate()` conserva faces/atributos e lotes por material |
| `Building/WorkshopVisuals.gd`, `Workshop.gd` | Montagens das 17 oficinas; `Node3D` de engrenagens, materiais consolidados, um rótulo por bancada |
| `Items/WorldPickup.gd` | Modelos por família; ferramentas, feixes, ervas, lingotes e equipamentos deixam de ser a mesma esfera |
| `Energy/Grid.gd` | `placement`, `wheel_current`, `link_ports`, `evaluate`, `valid`; grafo autoritativo e schema compatível |
| `Energy/Presentation.gd` | `StaticBody3D`, roda animada, cabos, luzes próximas e payload visual das esteiras; hash de topologia não inclui o timer de cada item |
| `Building/Automation.gd` | `add`, `advance`, `remove`, `valid`; buffers/timers conservados e autorização contínua |
| `Trading/Exchange.gd` | `create`, `accept`, `cancel`, `expire`; cópias de inventário antes do commit conjunto |
| `Communication/TeamPings.gd`, `Channels.gd` | Expiração/cooldown/alcance/exploração; roteamento de aliados sem enviar a inimigos |
| `Game/Runtime.gd`, `Main.gd`, `Networking/Session.gd` | Comandos validados, recibos recentes, tick de fábrica/rede/rotas, snapshot filtrado e persistência |
| `Persistence/SaveSchema.gd` | Campos opcionais `energy_grid` e `automation`; saves anteriores continuam válidos |
| `UI/TradePanel.gd`, `EnergyPanel.gd`, `StationPanel.gd` | Controles reais de oferta/aceite, cabo/switch/motor e esteira; recusas não debitam itens |
| `UI/MenuBackdrop.gd`, `VitalsOverlay.gd`, `HUD.gd`, `WorldMap.gd` | Ilustração, barras e menus responsivos; posição no mapa e controles com proporção preservada |
| `Data/Items.json`, `Balance.json`, `Assets/UI/Items/*.svg` | Cinco itens/receitas/ícones originais: roda, poste, lâmpada, motor, esteira; 105 itens/94 receitas/17 estações no total |
| `Tools/Test-Windows.ps1`, `.github/workflows/windows-qa.yml` | Exercita atualização real de 0.7.1 para a nova versão, além da reinstalação da mesma versão |

Fluxo: UI → pedido com ID → Session → fila de Main → Runtime → Grid/Automation/
Exchange/Inventory → snapshot/save. Nenhum comando aceita custo, dano ou inventário
enviado pelo cliente como fonte de verdade. Deduplicação de pedidos preserva o limite
existente de 128 recibos recentes por jogador; ofertas/cabos/motores/rotas também
possuem validações de existência que impedem cobrança/entrega duplicada.

Saves versão 4 recebem os campos opcionais; posições da rede são normalizadas
na precisão de Vector3 ao recarregar. Pings/ofertas pendentes são transitórios. Migrações v1–3 descartam extensões
que essas versões nunca validaram, evitando repassar campos malformados ao runtime.
Não há avanço industrial enquanto o processo do servidor estiver desligado.
O armazenamento continua sendo snapshots alternados validados/com lock; não é WAL/fsync.

## Evidências e reprodução

Resultados finais e logs desta revisão: `verification/0.8.0-dev`.

| Verificação | Resultado observado |
|---|---|
| Importação, regras, integração e processos | **4.372/0**, 25 runners |
| Integridade do batching | **8/0**; antes duas falhas, depois todas as faces conservadas |
| Indústria/troca/social/migração de legado | **59/0 + 4/0** |
| GUI automatizada, janela real | **37/0**, 12 capturas + 12 frames de ação articulada |
| Mochila com arrastar/soltar nativo | **17/0**; três stacks movidos, split, descarte físico, coleta, confirmação e reload sem duplicação |
| ENet: cadeias de coleta/processamento anteriores | **372 + 8**, sem falhas, dois clientes + reinício |
| ENet: cadeia industrial, troca, pings, aliança e reconexão | Três clientes + reinício passaram; materiais/posições de fixture |
| Movimento/recurso compartilhado | Dois clientes móveis e servidor dedicado, PASS |
| Chat anterior/voz sintética | Três clientes, canais privados/grupo/reino/diplomacia e ganho por distância, PASS |
| Abrir/salvar/continuar | **50/0**, processos independentes |
| Binários Linux/servidor/reinício | **6/0** na build final, após a correção de migração de legado |
| Soak de 30 minutos | Repetição: **273/0** no servidor + **3/0** após reinício; três clientes conectados, 1.801 s observados. Primeira execução com prazo de 5 s permanece FAIL |
| ZIP de fontes extraído/importação/jogo/save | **2/0** |
| Windows nativo: instalador/reinstalação/desinstalação/upgrade 0.7.1→0.8 | **34/0**, runtime headless |
| Windows gráfico exportado, fora do editor | **PASS**; gameplay 3D capturado após autosave válido, janela 960×650, encerramento normal. VM com ANGLE/driver por software |
| Downloads públicos fixados no commit da build | **5/0**, HTTP 200/tamanho correto e hashes verificados no Windows |


```sh
python3 Tools/build.py
python3 Tools/test_settlement_network.py
python3 Tools/test_settlement_network.py --soak-seconds=1800
python3 Tools/test_phase3_network.py
python3 Tools/test_communication.py --keep-logs builds/settlement/communication
python3 Tools/render_check.py --script res://Tools/capture_settlement.gd --log builds/settlement/gui.log --virtual-display --timeout 420
python3 Tools/render_check.py --script res://Tools/capture_inventory_acceptance.gd --log builds/settlement/inventory-input.log --virtual-display --timeout 180
python3 Tools/compare_audit_performance.py --baseline 185a463 --output builds/settlement/performance --warmup-seconds 5 --sample-seconds 12
python3 Tools/test_startup_stability.py --keep-logs builds/settlement/startup-50
python3 Tools/test_exports.py
python3 Tools/package.py
python3 Tools/test_source_package.py
```

Godot 4.6.3 e Python 3; NSIS para instalador; Xorg/dummy para `--virtual-display`.
Remover essa opção usa display local. O teste de rede usa três clientes reais e
servidor dedicado, com materiais/posições de fixture para isolar as transações.
A coleta sem concessão de recursos continua sendo testada separadamente na Fase 3.
Capturas GUI são pixels reais; galeria/cena industrial usam fixtures, não são
apresentadas como uma sessão humana de progressão integral.

As três falhas da primeira captura de UI vieram de fixture sem criação do segundo
personagem e de coordenadas calculadas antes de o layout se estabilizar. O teste
passou a criar o personagem pela API e esperar o layout antes do clique; verificações
não foram removidas. A primeira fixture de esteira tinha caminho fisicamente
obstruído; o harness agora busca um trecho livre no terreno real, mantendo a
validação espacial do servidor. Sessões anteriores com falhas não contam como soak aprovado. A primeira sessão
de 30 min teve uma ação fora do prazo de 5 s durante concorrência com builds;
os três clientes permaneceram conectados. Repetição isolada usa prazo de 15 s e
registra tempos por comando; esse prazo não é uma promessa de latência aceitável.
Na repetição, 197 respostas medidas tiveram mediana de 17 ms, p95 de 37 ms e
máximo de **4.501 ms**. Não houve nova falha de prazo, perda de conexão ou
divergência de inventário nos checks; os picos de vários segundos continuam
uma limitação observada, sem causa isolada nem aprovação de latência de produção.
As amostras do servidor mantiveram 5.847 nós, 96 chunks e três jogadores;
memória estática foi de 126.337.349 para 126.370.649 bytes (+33.300 bytes).
O relógio passou de dia para noite. A fixture mantém posições fixas e os materiais
de teste; a cadeia industrial termina seu lote inicial. Isso não equivale a 30 min
de jogadores em movimento, produção contínua de uma cidade ou carga de 100 pessoas.
Os seis logs de peers/servidor, métricas e recibo de fontes estão em
`verification/0.8.0-dev/soak-isolated`; o primeiro FAIL permanece em `soak-contended`.
O teste isolado de World apresentou uma corrida de teardown do mixer sob carga;
a fixture agora chama o cleanup real e verifica WeakRefs liberadas, em vez de
confiar em espera fixa de 0,2 s. As verificações de gameplay foram preservadas.

## Desempenho comparável

Baseline 185a463 e fontes atuais, seed 718991, Very Low, 1280×720 e câmera fixa.
Segunda medição: 5 s de aquecimento e 12 s por cenário, em Xorg/Mesa llvmpipe.
A primeira amostra curta teve concorrência com processos de QA e foi conservada
como `performance-contended`; não é usada como conclusão de desempenho.

| Cena | FPS antes → depois | p95 ms antes → depois | Draw calls antes → depois |
|---|---|---|---|
| day | 5.97 → 6.18 | 184.70 → 174.54 | 436 → 435 |
| station | 6.02 → 5.82 | 183.10 → 197.36 | 427 → 419 |
| night | 6.57 → 6.29 | 167.94 → 177.37 | 436 → 435 |
| storm | 6.30 → 6.32 | 174.71 → 178.05 | 437 → 436 |

Nesta amostra curta, FPS variou de aproximadamente −4,2% a +3,5%; memória estática
subiu cerca de 1,0–1,25 MB (<1%). Corrigir faces ausentes também aumenta a geometria
que de fato aparece. Não há aprovação de 60 FPS, GPU física ou ausência de regressão
em todos os cenários. CPU inclui o renderer por software; tempo de GPU indisponível.

A medição e o início do soak antecedem somente a filtragem de campos de extensão
em saves legados v1–3. Esse ramo não executa nos mundos v4 medidos; o build final e
os testes de migração cobrem a correção. Não se reutilizam resultados para código
novo de produção industrial ou renderização não exercitado.

## IMPLEMENTADO MAS NÃO TESTADO

Microfone físico e permissões do sistema, PTT/qualidade audível entre duas máquinas,
latência/perda externa, interação humana com a UI no Windows, Windows 10/11 físicos e hardware
alvo. O guia de 60 minutos ainda precisa de playtest humano cronometrado.

## PARCIAL

Arte/animacões permanecem procedurais em desenvolvimento; não são modelos finais
individuais para todos os 105 itens. A oficina tem nova silhueta, mas não um pacote
artístico comercial. Durabilidade ainda é conservadora por tipo, não por cópia.
Automação tem rotas ponto a ponto: sem splitters, filtros logísticos complexos,
redes de alta tensão, baterias ou produção com servidor desligado. Troca direta
não equivale a mercado/NPCs. Moderação de texto não cobre todo conteúdo ofensivo.
Persistência não oferece garantia de WAL/fsync contra interrupção elétrica.
Respostas ocasionais de vários segundos no soak impedem declarar latência estável.

## NÃO IMPLEMENTADO

Steamworks/loja, cercos/catapultas e guerra territorial completos, continente de
12 km e túneis volumétricos, navios/oceano completos, arte e animações finais,
certificação de 100 jogadores/60 FPS. Nenhum marco A–D integralmente aprovado.

Rastreabilidade de todos os grupos de pedidos e limites: [REQUEST_TRACEABILITY.md](REQUEST_TRACEABILITY.md).


## Publicação e atualização Windows

Código e cinco pacotes: commit `2926caabf64c63254f3ea5264b59a35de06f4fda`, enviado
normalmente a main. [Workflow Windows](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41957403530)
executou as etapas de checksum e instalação: 34 verificações passaram, incluindo
instalar 0.7.1, criar perfil/mundo, atualizar para 0.8, preservar todos os campos do
jogador/seed/gerador e avançar o snapshot. Também houve cliente isolado exportado,
reinício do dedicado, reinstalação e desinstalação preservando dados. Runtime headless.
A [prova gráfica nativa](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41959712491)
instalou o mesmo EXE, abriu o jogo exportado e capturou personagem, terreno,
vegetação e HUD após o primeiro autosave válido; encerrou com código zero.
O driver da VM não oferece OpenGL 3.3: o Godot usou seu fallback automático ANGLE/
Direct3D11 com Microsoft Basic Render Driver. O renderizador do projeto foi mantido.
Captura/log/relatório em `verification/0.8.0-dev/windows-graphics-gameplay`.
Não foi um teste humano de controles nem um teste de GPU física.

O primeiro probe capturou somente a tela de carregamento; seus arquivos permanecem
em `windows-graphics-loading` e não provam gameplay 3D. O segundo probe esperava
`GAME_READY` em log que o executável release só descarregou ao sair: o harness
falhou, apesar de o jogo iniciar. Foi preservado em `windows-graphics-log-wait`.
O probe aprovado agora espera um snapshot automático válido, além de conferir o
log final; nenhuma verificação de integridade do jogo foi retirada.

Os documentos dentro dos pacotes antecedem os testes pós-publicação; os resultados
confirmados ficam neste relatório e na pasta de evidências do repositório.

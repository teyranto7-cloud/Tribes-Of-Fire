# Auditoria de regressão — Fases 1–3 / 0.7.1-dev

Tribes of Fire · criado por **felipealx**. Escopo: corrigir regressões e contratos
existentes; nenhum novo sistema de jogo, item, receita, estação ou asset foi adicionado.

Checkpoints: `8c0555f` (baseline anterior às Fases 1–3), `cb36efd` (continuidade
mundo/UI), `634f07e` (Fase 3) e `d77dbc1` (última entrega antes desta auditoria).
O catálogo permanece com **100 itens, 89 receitas e 17 bancadas**.

## Resumo da execução

- **4.255 checks, 0 falhas, 22 runners**, incluindo **46** regressões específicas.
- **50** processos independentes de abrir/salvar/continuar, sem falhas.
- **39** verificações GUI, oito capturas reais, 1280×720 / 1920×1080 / 800×600.
- Servidor dedicado e dois clientes: **372 checks no ciclo + 8 no reinício**;
  coleta real, dois fluxos, replay, cancelamento atrasado e reconexão passaram.
- Três clientes de comunicação: seis canais e áudio sintético passaram; sem captura física.
- Exports Linux/servidor/reinício: **6/0**; fontes extraídas/importação/jogo/save: **2/0**.
  Instalador NSIS e quatro ZIPs gerados e conferidos por SHA256. QA Windows nativo
  desta revisão: **24/0**, com execução headless; cinco downloads públicos conferidos.

## CONCLUÍDO E TESTADO

| Caso | Antes da correção | Depois / evidência |
|---|---|---|
| Importação, cena inicial, movimento e colisões | Base existente | PASS: suíte completa e 50 processos abrir/salvar/continuar |
| Mundo por seed, chunks e reload | Base existente | PASS: test_frontier, test_world, snapshots e reinício; gerador 3 preservado |
| Inventário, stacks, obtenção e receitas por dados | Base existente | PASS: test_phase2, test_phase3 e test_playability |
| Dois ciclos: coleta → parede/baú; cobre → ferramenta que minera ferro | Base existente | PASS: servidor dedicado + dois clientes ENet; sem concessão de matérias-primas |
| Repetição identificada de abastecimento/retirada | Contrato ausente para comandos de estação | PASS: uma cobrança; replay tardio não retira outro lote; recibos sobrevivem a reconexão/reload/reinício |
| Desbloqueio na seleção de receita de estação | FAIL: seleção não conferia `unlocks` | PASS: seleção e abastecimento usam a mesma validação de desbloqueio |
| Cancelamento após mudança da fila | FAIL: índice podia apontar para outro trabalho | PASS: UID persistido identifica o trabalho; mouse-down preserva a intenção até mouse-up |
| Mochila cheia, restituição e múltiplos outputs | Base com cobertura parcial | PASS: nenhuma entrega parcial; pedido recusado pode ser repetido depois de liberar espaço |
| Capacidade de entradas da bancada | FAIL em buffer legado válido com oito tipos | PASS: tentativa de incluir nono tipo é recusada antes do débito; save continua válido |
| Intenções pendentes ao carregar snapshot | FAIL: fila de comandos anterior permanecia | PASS: `_begin_authority` descarta essas intenções antes de restaurar o estado |
| UI com teclas/cliques reais | Base existente | PASS: fabricação, cancelamento entre pressionar/soltar, mochila e mapa em três resoluções; capturas reais |
| Chat global/local/privado/grupo/reino/diplomacia | Base existente | PASS: três clientes, autorização, bloqueio, privacidade e reprodução de áudio sintético |
| Voz sintética por proximidade | Base existente | PASS de transporte/ganho: perto ~4 m = 0,80; médio ~15 m = 0,287; fora >30 m não recebe pacotes |
| Instalador Windows e runtime exportado | Pacote novo desta revisão | PASS: 24 verificações nativas de instalação, atalhos, runtime headless, save/reinício, reinstalação e desinstalação |
| Pacotes públicos | — | PASS: cinco URLs fixadas no commit da build, HTTP 200 e tamanho igual ao manifesto; SHA256 validado pelo CI Windows |
| Comparação de scripts | — | PASS: nenhum GDScript/cena/shader apagado desde o baseline; catálogo, Assets e World inalterados pela auditoria |

`unlocks` está vazio nas receitas atuais; o teste de contrato injeta temporariamente
um requisito em memória e o restaura. Isso valida a regra sem criar uma nova árvore
tecnológica nem alterar as receitas publicadas.

O teste de 50 processos ainda esperava gerador 2, embora o gerador publicado seja 3.
A fixture foi corrigida para exigir **seed 718991, gerador 3 e tamanho 1536**, mantendo
as verificações de checksum, sequência, jogador, estruturas e liberação do lock.
Nenhuma mecânica ou verificação de conservação foi removida para fazer o teste passar.

## Arquivos e integração reais

| Arquivo | Integração |
|---|---|
| `Main.gd` | `request_crafting_command()` atribui ID ao pedido da UI; `_begin_authority()` limpa intenções do estado anterior |
| `Networking/Session.gd` | `valid_command()` valida `request_id` e `job_uid` opcionais; transporte/autoridade existentes preservados |
| `Game/Runtime.gd` | `command()` verifica/guarda recibos; `recipe_unlock_reason()` e `station_reason()` concentram as regras; `_factory_command()` efetua a transferência atômica |
| `Crafting/Activities.gd` | `restore()` migra jobs antigos; `enqueue()` cria UID; `cancel()` encontra o trabalho certo; histórico recente de recibos permanece persistido |
| `Core/Inventory.gd` | `can_add_many()` projeta o resultado numa cópia para a UI, sem modificar o inventário real |
| `UI/InventoryPanel.gd` | Botões de receita/cancelamento usam pedidos identificados; `button_down` guarda o UID mostrado antes de a fila mudar |
| `UI/StationPanel.gd` | Controles existentes ficam desabilitados com motivo quando falta material, espaço, acesso ou desbloqueio |
| `Localization/pt_BR.po` | Mensagens de falha dos controles existentes |
| `Tests/test_station_transactions.gd` | Regressões de replay, cancelamento, capacidade, legado, conexão e reload |
| `Tests/test_phase3_network.gd` | Dois ciclos reais, replay de estação, cancelamento atrasado, reconexão e reinício |
| `Tests/test_communication_peer.gd` | Três clientes; sinal ADPCM sintético em distâncias próxima/média/fora do alcance |
| `Tools/test_startup_stability.py` | Fixture do gerador atual sem relaxar a validação dos saves |

Fluxo: `Scenes/Main.tscn` → Main → UI/Session → fila de comandos → Runtime →
Inventory/Activities/Factory → snapshot filtrado por destinatário. O cliente envia
intenções, não inventários, custos ou resultados. Não houve troca de engine/renderizador.

IDs novos de jobs são opcionais nos saves antigos e são gerados uma vez ao restaurar.
Pedidos sem metadados continuam compatíveis com as APIs anteriores; a UI atual envia
os identificadores. Deduplicação cobre os **128 pedidos recentes por jogador**,
conservados na persistência; não é uma garantia ilimitada nem uma prova formal de segurança.

## IMPLEMENTADO MAS NÃO TESTADO

- Captura por microfone físico, permissão real do sistema, qualidade audível,
  latência externa e PTT em dois computadores. Existem AudioStreamMicrophone,
  AudioEffectCapture, IMA ADPCM, ENet e AudioStreamGenerator reais, mas os testes
  desta auditoria **não capturaram a voz de ninguém**.
- Windows gráfico e jogo pelo atalho com mouse/teclado em máquina física;
  QA automático Windows usa execução headless.
- Upgrade entre versões diferentes instalado numa máquina real com perfil antigo.

## PARCIAL

- **Voz:** transporte/roteamento/ganho/mute/bloqueio sintéticos testados. Uso humano
  permanece **PENDENTE**. Não há Opus, eco cancelado ou supressão de ruído certificados.
  Codec = 325 bytes por 40 ms, ~8.125 bytes/s por emissor antes de overhead e fanout.
  Não usa serviço pago obrigatório; hospedagem, CPU e banda do servidor têm custo.
- **Social:** canais de reino e diplomacia por convite existem. Não há canal
  automático de todos os aliados; limites de tamanho/antispam/bloqueio e texto
  literal não equivalem a moderação completa de conteúdo ofensivo.
- **Modelos:** bancadas e pickups têm lógica real, mas várias bancadas compartilham
  geometria procedural transitória; `Items/WorldPickup.gd` usa uma família visual
  simples. Isso não é o conjunto final de modelos/artes/animações de produção.
- **Equipamentos:** desgaste conservador compartilhado por tipo, herdado dos saves;
  não há durabilidade independente para cada cópia.
- **Base/cidade e 60 minutos iniciais:** ferramentas, água, bancada, baú, paredes,
  portas/telhados e metal possuem caminhos implementados. O roteiro 0–60 minutos
  é uma recomendação ainda sem sessão humana cronometrada, divertida e aprovada.
- **Mapa/social:** marcadores persistentes compartilháveis dentro da tribo e
  neblina existem; isso não equivale a pings temporários e navegação completa de aliados.
- **Performance:** diagnóstico curto e comparável em GPU emulada; hardware alvo,
  memória por sessão longa e cargas de 8–100 jogadores não certificados.

## NÃO IMPLEMENTADO

Pings temporários de equipe; rede completa de roda-d'água/fiação/energia/esteiras;
comércio completo e cidade industrial; guerra territorial/cercos completos;
Steamworks/publicação Steam; catálogo/arte final do jogo inteiro. Componentes
mecânicos/elétricos fabricáveis não fornecem eletricidade gratuitamente.

Nenhum dos marcos A–D é declarado integralmente aprovado nesta auditoria.

## Desempenho antes/depois

Mesma seed 718991, câmera, Very Low, resolução 1280×720, Xorg/Mesa llvmpipe;
espera pelos chunks, 1 s de aquecimento e 4 s de amostra por cenário. Relógio
fixado e IA/física ativas. Ferramenta: `Tools/compare_audit_performance.py`.

| Cena | FPS antes → depois | p95 ms antes → depois | Draw calls antes/depois |
|---|---|---|---|
| Dia | 7,98 → 8,09 | 130,37 → 130,46 | 436 / 436 |
| Bancada aberta | 7,34 → 7,65 | 147,06 → 148,36 | 427 / 427 |
| Noite | 7,87 → 8,31 | 138,24 → 125,59 | 436 / 436 |
| Tempestade | 7,96 → 8,00 | 130,54 → 134,27 | 437 / 437 |

Memória estática Godot: diferença de aproximadamente +86–100 KB, abaixo de 0,1%.
O monitor de processo na bancada variou 127,84 → 141,21 ms (+10,5%) numa amostra;
isso inclui trabalho do renderer por software e não isola o custo da lógica.
FPS/draw calls não evidenciaram degradação material nessa comparação curta.
**Não há certificação de 60 FPS, GPU física ou ausência de regressão em todos os cenários.**
A medição antecede somente a limpeza adicional de comandos ao carregar; essa mudança
não executa no estado estável medido. Tempos de GPU não estavam disponíveis.

## Reprodução e evidências

```sh
python3 Tools/build.py
python3 Tools/test_phase3_network.py
python3 Tools/test_communication.py --keep-logs builds/audit/communication
python3 Tools/test_startup_stability.py --keep-logs builds/audit/startup-50
python3 Tools/render_check.py --script res://Tools/capture_audit.gd --log builds/audit-gui.log --virtual-display
python3 Tools/compare_audit_performance.py
python3 Tools/test_exports.py
python3 Tools/package.py
python3 Tools/test_source_package.py
```

Git, Godot 4.6.3, Python 3; NSIS para gerar o instalador; Xorg com driver dummy
para `--virtual-display`. Omitir essa opção usa um display existente. A comparação
antes/depois exige checkout Git com o commit d77dbc1. Perfis de testes são isolados.

Logs/matriz final e capturas: `Docs/verification/0.7.1-dev`. A sequência GUI desliga
somente o desenho 3D durante cliques repetidos; a captura de mundo reativa o 3D.
As fixtures de UI fornecem itens para inspecionar controles; o teste ENet coleta
os recursos de verdade, sem concessão de matérias-primas. Não confundir os métodos.

As URLs de referência fornecidas foram consultadas: a página Tool Cupboard respondeu
200 e foi lida; as demais devolveram 402/403 neste ambiente, sem tentativa de contorno.
Disponibilidade registrada em `references.json`. Nenhum asset dessas referências ou
da Poly Haven foi importado; o catálogo de dependências/licenças existente permanece.

## Publicação e Windows confirmados

Código e cinco pacotes enviados para `main` no commit
`06fd9f386f429bd14133a841e90a47eb60dd10e0`, preservando o histórico anterior.
[Prévia 0.7.1-dev](https://github.com/teyranto7-cloud/Tribes-Of-Fire/releases/tag/v0.7.1-dev)
com instalador Windows, ZIP Windows/Linux, servidor Linux e ZIP de fontes.

[QA Windows desta revisão](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41941392492):
as etapas de checksum e execução do instalador realmente executaram; todas as
**24 verificações passaram**. A reinstalação testada é da mesma versão. O runtime
foi executado em Windows nativo, em modo headless, sem comprovar gameplay gráfico,
permissões de microfone ou instalação interativa nos seis idiomas.

JSON/CSV e logs em `verification/0.7.1-dev/windows-native`; URLs e tamanhos em
`downloads.json`. Os documentos dentro dos pacotes registram o estado anterior
ao QA Windows; esta confirmação posterior fica no repositório. Os binários não
foram alterados depois dos testes, e o manifesto identifica as fontes da aplicação.

## Próximo incremento reduzido — apenas proposta

Playtest humano cronometrado: uma seed, uma cabana com porta/telhado/baú, água,
comida e primeiro metal, salvando e retomando após 20 minutos. Registrar obstáculos
reais antes de ampliar construção. Esse próximo incremento não foi implementado aqui.

# Fase 4 — construção modular — 0.9.0-dev

Tribes of Fire · criado por **felipealx**. Continuação de `53809a2` / 0.8.0-dev;
checkpoint local `checkpoint/pre-phase4-53809a2`. Godot 4.6.3 / Compatibility,
inventários, receitas, servidor autoritativo e saves anteriores preservados.

## Escopo implementado

`Data/Building.json` define 39 peças e seis materiais. O catálogo inclui fundação
quadrada/triangular, piso, parede, meia parede, janela, marco, folha de porta,
porta integrada legada, portões pequeno/grande/de fortaleza, telhado plano/inclinado,
teto, coluna, escada, rampa, corrimão, cerca, paliçada, ponte, plataforma, sacada,
suporte, viga, escotilha, cerca de fazenda, baú, cama, mesa, cadeira, vaso e
estandarte, além de canteiro, tocha, lamparina, jangada e totem existentes.
As 17 bancadas existentes também aparecem no menu; conservam o sistema industrial.

Integração: `Main.gd`/`Networking/Session.gd` encaminham `build`, `structure_edit`
e `station_move` para `Game/Runtime.gd` → `Building/Service.gd`. `World/World.gd`
materializa `Piece.gd`; `Persistence/SaveSchema.gd` valida o grafo e os campos.
`UI/BuildPanel.gd` serve tanto o atalho B como o inventário. `Geometry.gd` e
`Data/Building.json` concentram modelos, colisões e progressão de materiais.
Cliente e servidor precisam usar 0.9.0-dev; protocolo atual 7.

| Material | Integridade máxima | Custo-base por unidade de peça |
|---|---:|---|
| Palha/galhos | 60 | 4 gravetos + 4 fibras |
| Madeira | 100 | 4 madeiras; custos legados específicos preservados |
| Madeira reforçada | 220 | 4 tábuas + 2 pregos |
| Pedra/tijolo | 400 | 6 pedras + 2 tijolos |
| Metal | 650 | 4 lingotes de ferro + 2 pregos |
| Concreto armado | 1000 | 4 concretos + 2 lingotes de ferro |

O multiplicador de cada peça e os materiais permitidos também são dados.
Portão grande custa mais que meia parede. A aparência muda: madeira com juntas
verticais, reforços, alvenaria em fiadas, metal com cintas e painéis de concreto.
Tinturas cosméticas oferecem seis estilos persistidos; não há cadeia de corantes.

## Como usar

- **B** abre catálogo/gerenciamento; também disponível em **I → Construir**.
- Buscar, escolher categoria/material e marcar favoritos. Preferências usam a seção
  `building` do ConfigStore, preservando as demais opções do jogador.
- Selecionar peça; **R** gira 90°, **PgUp/PgDn** ajusta a altura em 0,25 m,
  **G** alterna grade, **T** alterna encaixe e **H** espelha peças compatíveis.
- Clique confirma a prévia. **Esc** cancela. Fantasma usa geometria da peça;
  bancadas usam o volume simplificado de colisão. Verde/vermelho e motivo explicam
  custo, terreno, alcance, personagem, colisão, suporte e permissão.
- Em **Gerenciar base**, selecionar uma peça até 9 m, reparar, aprimorar, renomear,
  alterar aparência/acesso, mover ou solicitar demolição. Atualizar renova a revisão.
- Folha de porta exige marco; a interação **E** seleciona a folha, abre para longe
  do jogador e protege o vão contra fechamento sobre personagens. Porta integrada
  anterior permanece válida. Escotilha possui folha e colisão móveis.

Proprietário e líder da tribo gerenciam movimento/demolição/aparência. Membros
autorizados constroem, reparam e aprimoram. Aliados recebem interação somente
quando o proprietário permite; isso não concede edição. Destrancar permite uso
por estranhos. O totem mantém a restrição territorial de 16 m.

## Cadeia de cimento

1. Extrair calcário e areia pelo sistema de recursos existente; obter argila.
2. Forno: 2 calcários + 1 argila + 1 areia → 2 cimentos, em 3 s.
3. Misturador: 1 cimento + 2 areias + 2 cascalhos + 1 água → 2 concretos,
   devolvendo 1 recipiente vazio, em 3 s.
4. Construir muro/fundação de concreto armado, consumindo concreto e ferro.

A cadeia foi testada com ingredientes de fixture, estações reais, reserva,
tempo de fabricação, saída, retorno do recipiente e consumo ao construir.
Os testes de coleta/progressão anteriores continuam separados.

## Autoridade, segurança e suporte

- `Building/Service.gd`: `preview`, `build`, `edit`, `toggle`, `move_station`.
  Cliente envia intenção; custo, estado e permissão são calculados no servidor.
- Cada peça tem ID persistente e revisão. Pedidos recentes recebem recibos;
  versão obsoleta não move, debita, renomeia ou restitui novamente.
- Recolocação mantém o original até a validação final; não entrega um kit gratuito.
  Conteúdo de baú/canteiro, ocupantes e peças dependentes bloqueiam o movimento.
  Esvaziar primeiro utiliza as transferências existentes.
- Bancada vazia mantém índice, orientação e revisão. Conteúdo, filas, cabos,
  esteiras ou motor instalado bloqueiam sua mudança. Bancadas não são demolidas
  por este fluxo; não se reindexa uma rede industrial ao remover uma estação.
- Demolição pede confirmação de IDs **e revisões de todo o conjunto**. Mudança
  posterior de dependentes cancela a operação. Até 24 peças por confirmação;
  conjuntos maiores devem ser desmontados em grupos menores.
- Restituição de 50% por material, arredondada para baixo. Kits registram os
  ingredientes da receita como base da restituição; não geram outro kit inteiro.
  Reparo não aumenta o valor restituído. Mochila cheia impede remover qualquer peça.
  Peças antigas sem custo registrado não recebem restituição estimada.
- `structural_support` no JSON do servidor ou checkbox do anfitrião ativa o modo
  estrito. Telhados elevados exigem suporte; vãos têm limite. O modo casual padrão
  preserva construções anteriores e permite suporte simplificado. Não se demole
  retroativamente uma base antiga ao habilitar a regra.

## Persistência e streaming

`Building/Registry.gd` mantém registros canônicos em células de 32 m; nós de
`Building/Piece.gd` são cache de física/visual. Alcance de carga 72 m, retenção 96 m
e oito instalações distantes por frame. Colisores até 12 m dos jogadores/locais de
construção são materializados antes da interação. A validação canônica cobre o
intervalo anterior à atualização física, impedindo sobreposição no mesmo tick.

Limite atual: **8.192 peças**, IDs até 1.000.000, com contador persistido que nunca
reutiliza IDs demolidos naquele mundo. Saves v4 ganham campos opcionais; validação
confere tiers, limites, referências e ciclos de suporte. Clientes recebem estruturas
até 96 m, com conteúdo privado filtrado. O dedicado conserva registros distantes.
Cultivos continuam crescendo sem o nó carregado e recuperam a aparência ao voltar.
O snapshot em disco continua global; o índice por chunk é reconstruído na carga.
Não há backend separado de arquivos/transações por região nesta revisão.

O teste de 3.000 registros é uma fixture técnica distribuída em centenas de chunks;
verifica escrita/leitura, IDs, streaming e cache limitado. Não representa uma cidade
construída por jogadores nem comprova FPS com milhares de peças visíveis.

## Evidências e reprodução

Resultados finais: `verification/0.9.0-dev`. Conferir a matriz e os logs; nenhuma
aprovação da 0.8 substitui os testes desta revisão.

### CONCLUÍDO E TESTADO

| Verificação | Resultado observado nesta revisão |
|---|---|
| Importação/regras/integração/processos | **4.705 checks, 0 falhas**, 28 runners |
| Catálogo, autoridade, peças, cimento, restituição, crop e 3.000 registros | **312/0** |
| Marco/folha, E real, abertura segura, JSON e metades triangulares | **15/0** |
| Caminhada física sem salto por escada/rampa | **4/0**; subida até ~23 m a partir de piso de fixture em 20 m |
| Construção ENet compartilhada e bancada | **36/0** no dedicado + **6/0** após reinício; três clientes e cliente reconectado, **52/0 por execução** |
| Cadeias anteriores de coleta/fabricação em ENet | **372 + 8**, zero falhas; dois clientes/reconexão/reinício |
| GUI e teclado/mouse | **27/0**, seis capturas reais, 1280×720/1920×1080/800×600 |
| Binários Linux/dedicado/reinício | **6/0**, executados fora do editor |
| Comunicação e áudio sintético | Repetição com diagnóstico PASS: três clientes, canais/ganho/privacidade/bloqueio; nenhum microfone |
| Instalador Windows/upgrade 0.8→0.9 | PENDENTE do workflow desta build |
| Windows gráfico exportado | PENDENTE da prova gráfica desta build |
| ZIP de fontes extraído | **2/0**, importação e execução/save do projeto extraído |

Fonte de aplicação congelada:
`cce57b58456d106b8afb8356e9d832ae1d8aa9762cbac518835669c37528e00a`.

A galeria fixa por software (llvmpipe), com simulação congelada, mediu 9,95 FPS,
p95 107,07 ms, 242 draw calls e ~157,4 MB de memória estática em quatro segundos.
Esse número não representa gameplay, GPU física ou o hardware alvo; não aprova 60 FPS.

Falhas reproduzidas e corrigidas: kit restituía zero por arredondar uma unidade
inteira; ID de suporte em JSON precisava de normalização; construção podia
anteceder o collider; cultivo era apagado ao descarregar; altura era aplicada
duas vezes no socket; porta bloqueava a própria interação; costura triangular
era recusada por contato; escada/rampa impediam caminhar sem pular. Os testes de
regressão preservam esses casos. A fixture antiga de reconstrução passa a pedir
materialização explícita de loot distante e contar registros canônicos; mantém
as verificações de seed, IDs, propriedade, geometria, posição e persistência.

No primeiro teste de comunicação, C recebeu uma das quatro amostras diplomáticas
e falhou o critério mínimo de duas. A repetição instrumentada, mantendo os critérios,
recebeu quatro/quatro e confirmou roteamento autorizado/filas vazias. O primeiro
FAIL foi preservado; sua causa não foi isolada. Transporte de voz é UDP ordenado
sem retransmissão; esta amostra não certifica qualidade/latência de voz humana.

```sh
python3 Tools/build.py
python3 Tools/test_phase4_network.py
python3 Tools/test_phase3_network.py
python3 Tools/render_check.py --script res://Tools/capture_phase4.gd --log builds/phase4/gui.log --virtual-display --timeout 240
python3 Tools/test_exports.py
python3 Tools/package.py
python3 Tools/test_source_package.py
```

Testes específicos: `Tests/test_phase4.gd`, `test_phase4_doors.gd` e
`test_phase4_walk.gd`. O teste ENet usa três clientes/dedicado, materiais e posições
de fixture; verifica construção compartilhada, inimigo recusado, replay, revisão,
baú, bancada, restituição, reconexão e reinício. Capturas são framebuffers reais;
a galeria de materiais é uma cena de apresentação identificada como fixture.
Escadas e rampas usam transição de colisão contínua. A fixture de travessia mantém
o CharacterBody3D real, comandos de movimento sem salto e frames de física normais.

## IMPLEMENTADO MAS NÃO TESTADO

Playtest humano de uma base grande, clientes em rede externa, GPU física e
desempenho no Ryzen 4600G. A medição da galeria usa llvmpipe e simulação congelada;
não certifica 60 FPS ou latência de produção.

## PARCIAL

Arte procedural em transição; não há pacote final de modelos/texturas para todas
as peças. Suporte é grafo com validação de vão, sem solver físico de cargas.
Snapping usa módulos de 4 m, rotações de 90° e triângulos retângulos. Bancadas
continuam limitadas a 32 e não fazem parte do streaming de milhares de peças.
Máquina com motor instalado precisa permanecer no lugar. Integridade/reparo/tier
não constituem um sistema completo de dano e cercos contra construções.
Snapshots alternados/checksum/lock persistem; não é armazenamento WAL/fsync.

## NÃO IMPLEMENTADO

Colapso físico animado, demolição/reembolso industrial, retirada de motor, sistema
completo de deterioração/ataques de cerco e certificação de 100 jogadores.
O roteiro integral e os marcos A–D continuam sem aprovação completa.

Os documentos dentro dos pacotes antecedem os testes pós-publicação no Windows.
O relatório e as evidências do repositório registram os resultados confirmados.

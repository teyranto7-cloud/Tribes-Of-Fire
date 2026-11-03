# Fase 3 — coleta, itens, receitas e bancadas — 0.7.0-dev

O projeto permanece Godot 4.6.3, com autoridade no servidor. A fonte numerada
continua preservada; esta entrega está no repositório `Tribes-Of-Fire`.

## Conteúdo orientado a dados

[Data/Items.json](../Data/Items.json) define 100 itens, 89 receitas e 17 bancadas.
Cada item tem ID permanente, nomes localizados, tipo, raridade, peso em kg,
empilhamento, ícone, modelo de pickup, durabilidade, estatísticas, tags e descrição.
Slots de equipamento e efeitos de consumo também vêm do catálogo. O inventário
mostra peso e aplica stacks declarados; slots antigos acima do limite permanecem
legíveis para não destruir saves existentes. Durabilidade continua compartilhada
por tipo de equipamento, compatível com os saves anteriores; esta revisão não
introduz qualidade ou desgaste independente de cada cópia.

Receitas usam `inputs`, `outputs`, `station`, `time`, `era`, `unlocks` e categoria.
O campo `cost` da API é apenas uma adaptação dos inputs para módulos antigos.
Não há uma segunda tabela de receitas em Balance.json. IDs antigos de itens e
receitas foram preservados, incluindo receitas antigas a carvão mineral. Variantes
novas permitem combustível vegetal, múltiplos outputs e processamento em oficinas.

`resource_nodes` mantém a ordem dos IDs de recursos já salvos: nunca reordene ou
reutilize uma posição; recursos novos são acrescentados ao fim. Dureza, ferramenta,
nível mínimo, regeneração e rendimento estão em `gathering`; regras das árvores
estão em `trees`. O machado inicial mantém três golpes. Picareta de pedra alcança
cobre/estanho; cobre alcança ferro; ferro alcança os depósitos avançados.

Categorias incluem madeira/troncos/tábuas/gravetos, minerais, fibras/cordas/tecidos,
alimentos/sementes/frutas, água/recipientes, peles/ossos, combustíveis, minérios e
metais, ferramentas, armas, armaduras, construção, mecânica, elétrica, móveis,
decoração e consumíveis. Ícones e pickups usam famílias visuais originais; modelos
de bancadas ainda são procedurais e transitórios, sem promessa de arte final.

## Bancadas e interface

Fogueira de produção com inventário, bancada simples, carpinteiro, pedreiro,
serraria, fornalha, bigorna, curtume, tear, cozinha, bancada de ervas, oficina
mecânica, bancada elétrica, misturador de concreto, fundição, oficina avançada e
britador. A fogueira anterior de aquecimento permanece disponível.

Cada estação tem alcance definido nos dados, propriedade/permissão tribal,
entradas/saídas persistidas e receitas selecionáveis. E abre a oficina; escolha
uma receita, abasteça 1 ou 5 ciclos, retire produtos ou cancele/devolva as entradas.
Produção de estação continua com o dono desconectado enquanto o servidor roda.
Não há produção retroativa durante o período em que o servidor está desligado.
Máquinas antigas sem receita selecionada preservam a configuração legada.

A mochila mostra todos os inputs possuídos/exigidos, símbolos e cores de falta,
estação, tempo e todos os outputs, inclusive subprodutos. Há busca por nome,
material/estação/categoria, filtro por categoria e guia de progressão no painel.
Selecione kits fabricados e use **Posicionar** para colocar bancadas, paredes e baús.
O caminho antigo de construção direta permanece compatível; kits têm prioridade
no custo de colocação. Recipientes vazios são transformados em água coletada na
fonte e retornam ao beber ou nas receitas que usam água.

## Dois ciclos verificados

1. Coletar madeira/pedra/fibra → fabricar machado e bancada → tábuas e cordas →
   bancada de carpinteiro → kits de parede e baú → estruturas físicas colocadas.
2. Fabricar picareta de pedra → minerar cobre → fogueira e carvão vegetal →
   fornalha e lingotes → bigorna → picareta de cobre → minerar ferro com ela.

O fluxo seguinte está disponível por dados: ferro, ferramenta de ferro, serraria,
mecânica, fios/circuitos, concreto e oficina avançada. A bancada de ervas produz
medicina a partir de ervas/tecido, sem introduzir magia ou nova árvore tecnológica.

## Atomicidade e persistência

A fila pessoal reserva inputs em uma transação única. Um ID de pedido repetido
não cobra nem cria outro trabalho; o histórico recente de 128 pedidos é salvo por
jogador e restaurado ao reconectar. Outputs múltiplos são entregues em uma única
transação: se algum não couber, nenhum é entregue e o trabalho aguarda espaço.
Cancelar só remove a fila depois de devolver todo o escrow. Pedidos cancelados
não podem ser repetidos com o mesmo ID. ENet mantém transporte confiável.

Inventários de estação atualizam entradas e saídas juntos no servidor. Se faltam
materiais ou espaço, não há produção parcial. Entrada restante pode ser devolvida
integralmente; tempo ocioso sem materiais não vira crédito de produção instantânea.
Pickups congelam quando seu chunk sai do streaming e voltam à física quando o
terreno retorna, evitando queda para fora do mundo e falha no save.

## Verificação

Suíte final: **4.200 checks, zero falhas, 20 runners**. Os 804 casos específicos
da Fase 3 passaram; os seis checks dos binários Linux/servidor e quatro capturas
reais de UI também passaram. O teste ENet confirmou os ciclos, replay, reconexão
e reinício limpo.

- `Tests/test_phase3.gd`: catálogo, dois ciclos com coleta real, colocação, ferramenta
  superior, falta de material, ferramenta errada, pedido duplicado, inventário
  cheio, múltiplos outputs, cancelamento, alcance/propriedade, buffers e reload.
- `Tools/test_phase3_network.py`: servidor e dois clientes ENet reais, comandos de
  coleta/crafting/construção, replay, desconexão real e reinício limpo preservando
  ciclos e fila paga. O cenário controla posição e avanço de tempo; não concede
  matérias-primas. Não mede latência ou carga em uma rede externa.
- A suíte geral mantém regressões de árvores de três golpes, gameplay, chuva,
  exploração, persistência, multiplayer e interfaces anteriores.
- Evidências desta entrega ficam em [verification/0.7.0-dev](verification/0.7.0-dev).

Modelos finais, balanceamento por sessões longas, redes externas com perda/lag,
redes elétricas funcionais, esteiras/automação e validação gráfica em GPU física
continuam fora desta entrega de itens e bancadas. Ter componentes elétricos não
equivale a já possuir uma rede elétrica completa.

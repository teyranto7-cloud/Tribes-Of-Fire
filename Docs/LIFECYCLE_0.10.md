# Continuidade — 0.10.0-dev

Tribes of Fire · criado por **felipealx**. Continuação do commit `71b2317`, com
checkpoint `checkpoint/pre-0.10-71b2317`. Mesmo Godot 4.6.3 / Compatibility,
cena e saves v4. A revisão fecha lacunas industriais e de dano da Fase 4;
não representa a conclusão do roteiro integral do jogo.

## CONCLUÍDO E TESTADO

Resultados finais e hashes: `verification/0.10.0-dev` (matriz atualizada após os testes).

| Verificação nesta revisão | Resultado |
|---|---|
| Importação, regras, integração e processos | **4.778 checks / 0 falhas**, 31 runners |
| Ciclo industrial/elétrico, IDs, replays, capacidade e disco | **34/0** |
| Combate, diplomacia, colapso, conteúdo/desgaste e reload | **32/0** |
| ENet: dedicado e reinício | **23/0 + 5/0**, dois clientes; 19/0 e 14/0, reconectado após reinício 18/0 |
| GUI com mouse/teclado, confirmações, combate e fragmentos | **21/0**, cinco capturas reais e três resoluções |
| Regressão ENet Fase 3 | **372/0 + 8/0**, coleta/fabricação, reconexão e reinício |
| Regressão ENet Fase 4 | **36/0 + 6/0**, três clientes e **52/0 por execução** |
| Binários Linux/dedicado fora do editor | **6/0**, saves, reinício e liberação de locks |
| ZIP de fontes extraído | **2/0**, importação nova e execução/save reais |
| Windows nativo/upgrade e gráfico | Pendente do CI dos pacotes desta revisão |

Fonte congelada de aplicação:
`756008ee311ddce9378d7c20bba7e5b57cde85bede091ad267b626b93978e345`.
Resultados de instaladores antigos não substituem o QA dos novos pacotes.

- Retirada confirmada de motor, devolvendo exatamente um motor; cabos e esteiras
  precisam ser desconectados primeiro. Mochila cheia impede a ação inteira.
- Demolição confirmada de bancada vazia, sem motor, filas, cabos, esteiras ou
  personagens no volume. Restitui 50% do custo registrado, arredondado para baixo.
  Bancadas antigas sem custo registrado não recebem uma estimativa de materiais.
- Recolocação com prévia e demolição de roda-d'água, poste e lâmpada. O servidor
  verifica alcance, território, proprietário/líder, caminho livre, água/terreno,
  colisão, ligações, revisão e espaço para restituição.
- IDs industriais não mudam quando outra máquina é removida. O slot removido
  permanece como registro inativo sem malha, collider ou produção; nunca é
  reutilizado. Novas bancadas recebem um slot novo. Há 32 bancadas ativas e até
  256 registros históricos por mundo. Não são 256 máquinas ativas certificadas.
- Replays e revisões obsoletas não devolvem outro motor/material nem atingem uma
  nova bancada no lugar da antiga. Saves rejeitam motores/esteiras referenciando
  máquinas removidas, conteúdo oculto em slots inativos e metadados inválidos.
- Ataques existentes chegam ao dano estrutural por raycast da arma no servidor;
  nenhum comando aceita dano ou alvo arbitrário do cliente. Alcance, cooldown,
  resistência física, durabilidade e dano derivam do combate existente.
- PvP desligado protege construções de jogadores. Modo guerra exige declaração;
  tribo, aliança, proteção de 300 s e trégua de uma hora também protegem as peças.
  Peças do próprio jogador usam o gerenciamento confirmado para demolição.
- Dano/integridade e revisão persistem. No modo estrutural estrito, perder o
  último suporte derruba os dependentes; suportes alternativos conservam a peça.
  No casual, remove-se a referência quebrada sem colapso obrigatório.
- Baú cheio destruído vira um único contêiner de destroços no chão, destrancado,
  sem colisão, sem restituição de construção e sem aceitar novos depósitos.
  Contagens e desgaste são conservados até o saque. O contêiner some somente
  após a última retirada bem-sucedida; sobrevive a save/reload.
- Fragmentos físicos cosméticos colidem com o cenário, sem dano nem colisão com
  jogadores: no máximo seis efeitos/36 fragmentos vivos, duração de três segundos.
  Servidor headless não cria fragmentos cosméticos.

## Como usar

1. **B → Gerenciar base**: selecione a bancada. Retire produção; cancele/devolva
   entradas; termine/cancele filas. Remova esteiras e cabos pelas telas existentes.
2. Clique **Retirar motor**, confirme e aguarde a atualização do estado. Depois
   pode mover a bancada ou clicar **Demolir bancada** e confirmar a restituição.
3. Use **E** no aparelho elétrico. Após desconectar cabos, **Recolocar aparelho**
   abre a prévia à frente; clique confirma e Esc cancela. **Demolir aparelho**
   exige outra confirmação. A posição é escolhida a quatro metros à frente;
   roda-d'água ainda precisa de corrente válida. Não se movem cabos conectados.
4. Ataque uma peça inimiga usando o combate normal; as regras PvP do servidor
   determinam se o golpe pode causar dano. Colete destroços de baú com **E**.

Os controles industriais atualizam após mudanças replicadas. Confirmações guardam
ID e revisão; o servidor verifica novamente ao receber. Cliente e servidor devem
usar **0.10.0-dev / protocolo 8**.

## Arquivos e integração

| Arquivo | Responsabilidade real |
|---|---|
| `Building/Industry.gd` | `edit`, `reason`, `edit_device`, `preview_device`: autoridade e transações industriais |
| `Building/Workshop.gd` | registro inativo, limites e `valid_building`; remoção de malha/collider/produção |
| `Building/Destruction.gd` | `strike`, `allowed`, `collapse_ids`, `destroy`: raycast, diplomacia, grafo e destroços |
| `Building/Debris.gd` | fragmentos físicos cosméticos limitados e liberados por tempo |
| `Game/Runtime.gd` | comandos `industry_edit`/`device_edit`, integração ao combate, transferência e notificações |
| `Networking/Session.gd` | protocolo 8, validação estrita e recibos das novas ações |
| `UI/BuildPanel.gd`, `UI/EnergyPanel.gd`, `Main.gd` | gerenciamento, diálogos, atualização e prévia de recolocação |
| `Persistence/Store.gd`, `SaveSchema.gd`, `Energy/Grid.gd` | compatibilidade e referências válidas dos registros persistentes |
| `World/World.gd`, `Building/Piece.gd` | aparência/colisão correta do baú destruído em clientes e reload |

```sh
python3 Tools/build.py
python3 Tools/test_lifecycle_network.py
python3 Tools/test_phase4_network.py
python3 Tools/test_phase3_network.py
python3 Tools/render_check.py --script res://Tools/capture_lifecycle.gd --log builds/lifecycle/gui-final.log --virtual-display --timeout 240
python3 Tools/test_exports.py
python3 Tools/package.py
python3 Tools/test_source_package.py
```

Testes locais específicos: `Tests/test_industry_lifecycle.gd` e
`Tests/test_structure_combat.gd`. Rede: dois clientes ENet reais e dedicado,
reinício e identidade persistente, com materiais/posições de fixture. GUI usa
eventos de mouse/teclado, diálogos reais e framebuffers em três resoluções.
O primeiro teste GUI clicava nas coordenadas locais do popup como se fossem da
janela principal: dois critérios falharam. A correção é no harness de coordenadas;
os mesmos critérios passaram na repetição, sem emitir sinais de confirmação
diretamente. A primeira fixture industrial encerrava a árvore sem o fechamento
de áudio do jogo e registrou recursos ainda ativos; agora usa `quit_game`, com
fechamento normal e sem leaks na suíte final. O primeiro log foi preservado.

## IMPLEMENTADO MAS NÃO TESTADO

Clientes em redes externas, playtest humano prolongado, microfone/alto-falantes,
acessibilidade completa e desempenho no Ryzen 4600G/GPU física. Capturas na nuvem
usam llvmpipe/VM e não certificam 60 FPS. Testes sintéticos de voz não certificam
latência ou qualidade audível entre pessoas.

## PARCIAL

Suporte é um grafo, sem solver físico de cargas. Os fragmentos têm física, mas o
prédio não se torna uma malha rígida deformável. Para impedir máquinas cheias
flutuando, suportes de aparelhos industriais param em 1 HP até os aparelhos serem
esvaziados e recolocados. Isso é uma proteção explícita desta implementação,
não um sistema completo de raide industrial. Jangadas continuam usando o sistema
de navegação existente e não participam desses ataques estruturais.

A arte continua procedural em transição. O índice de peças é por chunk; disco
continua com snapshots JSON globais, checksum, recuperação e lock existentes.
Não há WAL/fsync nem garantia de queda de energia. O limite de 8.192 peças continua;
a fixture de 3.000 da Fase 4 não comprova uma cidade grande jogada em GPU física.

## NÃO IMPLEMENTADO

Ataque/destruição do conteúdo industrial completo, cargas/deformação estrutural,
catapultas e cercos completos, deterioração, túneis volumétricos/navios oceânicos,
automação com roteadores/splitters, NPCs/mercados, durabilidade por cópia, todos os
assets/animações finais, continente de 12 km, validação de oito grandes tribos,
carga de 100 jogadores, Steamworks/loja e assinatura comercial do instalador.
Marcos A–D e a versão 1.0 continuam sem aprovação integral. A matriz histórica de
pedidos está em `REQUEST_TRACEABILITY.md`; não se converte ausência de testes ou
um recurso de transição em conclusão do jogo inteiro.

Os documentos empacotados antecedem o QA Windows pós-publicação. O relatório e as evidências do repositório contêm os resultados finais.

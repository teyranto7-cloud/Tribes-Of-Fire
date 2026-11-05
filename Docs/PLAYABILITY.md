# Guia adicional — 0.8.0-dev

**Energia e indústria:** I → Fabricação, busque roda/motor/poste/esteira. As receitas
pedem oficina mecânica e materiais processados, sem energia grátis no início.
Fabrique o kit, selecione na mochila e clique Posicionar (ou vincule à barra 1–9).
Roda só aceita corrente profunda do rio; margem/obstáculo inválido aparece na prévia.
Postes/luzes ficam em chão livre. E abre o aparelho: conecte outro aparelho próximo
com fios (18 m; um fio/6 m), ligue/desligue ou retire um cabo para recuperar fios.

Na serraria/tear/britador/misturador, instale um motor (consome um item). Abra a conexão
elétrica da máquina e ligue por fios à geração. Motor = 40 W; lâmpada = 6 W. Se faltar
potência ou houver sobrecarga, a produção automática pausa sem perder os materiais.
Máquinas anteriores sem motor continuam operando na velocidade manual original.

Configure uma oficina de destino com receita que use o output da origem. Abasteça
os outros ingredientes, aproxime até 8 m e deixe o trajeto da esteira livre. No painel
da origem energizada, escolha produto/destino e conecte usando um kit de esteira.
Um item/s é transferido entre buffers reais. Serraria → tábuas → carpinteiro com
corda → kit de parede é uma cadeia possível. Retirar a esteira devolve seu kit.

**Trocas:** Esc → Trocar com um jogador próximo; escolha destinatário, item e
quantidade de cada lado. A oferta expira em 90 s; os inventários mudam juntos só
quando o destinatário aceita. Fiquem até 6 m/sem parede. Recusar/desconectar não perde
itens. Conferir espaço na mochila; materiais não ficam reservados durante a oferta.

**Equipe:** no chat, Aliados inclui sua tribo e alianças aceitas. M → clique num
local descoberto a até 250 m → Enviar ping. Dura 20 s e não revela o terreno inimigo.
A roda do mouse aproxima o mapa; botão direito arrasta. Marcadores antigos persistem.

O guia anterior e os controles de sobrevivência continuam abaixo.

# Jogar — 0.5.0-dev

Tribes of Fire, criado por **felipealx**. Continuação do projeto Godot existente.
As referências Roblox orientam composição e sistemas; não foram copiados assets,
mapas, personagens ou áudio daqueles jogos.

## Começar

1. Abra o instalador Windows, ou extraia o ZIP e execute TribesOfFire.exe.
2. Nova jornada: deixe a seed vazia para um mundo aleatório ou informe sua seed.
3. WASD move, mouse olha, Shift corre e Espaço pula. Tab abre a mochila; Esc abre o menu.
4. Derrube uma árvore com três golpes próximos de machado. Os materiais caem no
   chão: aproxime-se e pressione E para recolher. Aguarde a conclusão de cada ação.
5. Depósitos possuem nomes. Pedra, madeira, fibra, frutas, argila, areia, terra,
   flores e ervas podem ser recolhidos com E. Para minérios, equipe uma picareta e
   use clique/E. O progresso e os estoques pertencem ao servidor.
6. Na mochila, selecione um item e Equipar. Equipar ferramenta cancela o modo de
   construção anterior. As abas separam Mochila, Fabricação e Construir.

## Fabricação e medicina

A busca aceita nome de item/material. Cada receita mostra posse/custo, estação,
quantidade produzida e duração. Receitas bloqueadas explicam o motivo; elas não
somem. A fila reserva materiais, produz um trabalho por vez e permite cancelar e
restituir os custos quando existe espaço. Ficar longe da estação pausa sua receita.

Construa uma bancada e abra Pesquisa e tecnologias. A primeira pesquisa requer
pedra e fibra; outras liberam metalurgia e equipamentos. Não é preciso encontrar
um item de administração para progredir: o teste de catálogo verifica um caminho
de obtenção para cada identificador existente no jogo.

Flores e ervas são coletáveis e entram em curativos/chá/kit medicinal. Selecione
um remédio na mochila e use Comer/usar para curar vida; o item é consumido pela
autoridade. Chá também hidrata. Na fonte, E bebe; estando hidratado, E guarda água.
Faça backup de saves e preserve identity.cfg antes de atualizar.

## Máquinas e embarcações

Em Construir: serraria transforma madeira em tábuas; tear transforma fibra em
tecido; britador transforma pedra em areia. E abre uma máquina próxima. Abastecer
transfere materiais para cinco ciclos; Retirar produção recolhe as saídas reais.
A produção avança com o servidor ativo e persiste seus insumos, resultados e tempo.
O painel mostra entradas, saídas e duração. Clique Atualizar para consultar novamente.

Uma jangada usa tábuas e cordas e deve ser colocada em água suficientemente funda.
A prévia verde indica posição válida. E embarca/desembarca; W/S rema e A/D vira.
O servidor impede navegação sobre terra e através de obstáculos. A jangada e sua
posição são salvas; o personagem desocupa a embarcação ao renascer.

A pá permite escavar o solo com clique. A superfície e a colisão mudam juntas;
o jogador ganha terra e a ferramenta gasta resistência/durabilidade. As alterações
são salvas. A escavação é superficial, limitada a 4 m; não é terreno volumétrico.

## Mundo vivo, noite e tribos

Novos mundos usam 1536 × 1536 m (23,04 vezes a área da 0.4). O gerador mantém oito
monumentos regionais, caverna e ruínas, floresta, flores, encostas e rio navegável.
Há 96 animais distribuídos, seis espécies e árvores/recursos com regeneração.
A extensão planeja espaço para oito tribos; isso não comprova carga de oito
tribos grandes conectadas. Saves antigos mantêm seus geradores e dimensões.

O dia dura 30 min e a noite 15 min por padrão; o relógio é do servidor. Sol, lua,
clima, fogueiras, tochas e lamparinas mudam a apresentação. Fogueiras precisam de
combustível e podem apagar sob chuva sem teto. Telhados e cavernas são cobertura
física. A regra de exposição 40/55/15 s e as regras de vida existentes foram mantidas.

Esc → Tribos e diplomacia: criar/entrar/gerenciar membros, propor/aceitar alianças,
declarar guerra, propor/aceitar paz ou romper aliança. Só líderes administram a
diplomacia. Dano aliado é bloqueado; romper aliança inicia uma hora de proteção.
A proteção de cinco minutos ao sair/ser expulso também foi preservada.
O administrador pode usar PvP on/off/war; war só permite combate entre tribos em
guerra declarada. O modo on permite PvP geral, respeitando aliados/proteções.

## Limites desta entrega

Os sistemas novos são versões funcionais iniciais: três máquinas de receitas
fixas, jangada simples, escavação superficial e diplomacia básica. Este não é o
catálogo completo proposto de centenas de itens, uma fábrica com esteiras/energia,
um simulador de guerra com cercos ou arte/animação final. Não foram certificados
100 jogadores, 60 FPS no 4600G, microfones físicos ou todos os drivers Windows.
Consulte o relatório de validação e PROGRESS.md para os resultados realmente executados.

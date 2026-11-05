# Pendências atuais — 0.8.0-dev

Consulte [REQUEST_TRACEABILITY.md](REQUEST_TRACEABILITY.md) para cada grupo de pedidos
e [SETTLEMENT_REPORT.md](SETTLEMENT_REPORT.md) para testes desta revisão.

Energia de rio, fios/luzes/motores, esteiras ponto a ponto, troca direta e pings de
tribo/aliados agora possuem implementação integrada. Arte procedural foi refinada;
a perda de faces no batching foi corrigida. Isso substitui as descrições antigas
que tratavam toda energia/automação/troca/ping como ausentes.

Continuam pendentes: todos os assets/animações finais, durabilidade por cópia,
navios e túneis volumétricos, 12 km, suporte validado a oito grandes tribos e
100 jogadores, cercos/guerra territorial/catapulta completos, mercados/NPCs,
splitters/automação avançada, remoção/reposicionamento completo de aparelhos,
WAL/fsync e testes de queda de energia, Steamworks/publicação Steam/assinatura,
revisão linguística dos seis idiomas, microfones/voz humana e rede externa,
Windows gráfico físico, GPU/hardware alvo e playtest humano dos 60 minutos.

A cadeia industrial atual permite produção real; não equivale a uma cidade
completa. Os relatos 0.5 abaixo são históricos, não a matriz atual de ausências.

# Pendências — 0.5.0-dev

Criado por **felipealx**. O estado anterior está preservado em
[verification/0.4.0-dev/PENDENCIAS.md](verification/0.4.0-dev/PENDENCIAS.md).
Resultados atuais: [PLAYABILITY_REPORT.md](PLAYABILITY_REPORT.md).

## Entregue nesta revisão

Faces externas dos modelos corrigidas; fabricação em abas com busca, custos e
motivos de bloqueio; fontes para todos os IDs do catálogo atual; medicina e
materiais/equipamentos adicionais. Novo mapa de 1536 × 1536 m, oito monumentos
regionais, 96 animais, flores, floresta distante e rio navegável. Jangada, pá,
serraria/tear/britador e diplomacia têm interação autoritativa e persistência.
São versões iniciais; dia/noite e geradores de saves antigos foram preservados.

## Validação a ampliar

- Sessão contínua de 30 min, carga de 8–100 jogadores, rede externa/latência e
  matriz abrangente de administração, protocolo, senha e entradas hostis.
- Exploração das regiões/seeds, costuras e distribuição final de recursos/ecologia.
  O espaço planejado para oito tribos não comprova oito tribos grandes conectadas.
- Windows gráfico interativo, GPU física, memória e benchmarks de CPU/GPU.
  Não há certificação de 60 FPS no Ryzen 5 4600G.
- Microfones físicos, eco/Opus, gamepad, multimonitor/DPI e acessibilidade completa.
- Atualização nativa entre versões diferentes, preservando perfis antigos.
  O instalador 0.5 passou seus 24 checks nativos; isso não testa upgrade entre versões.
- Traduções novas nos seis idiomas, animações/modelos finais e balanceamento.

## Conteúdo parcial ou ausente

O catálogo atual tem caminhos de obtenção verificados; não equivale ao catálogo
proposto de centenas de itens. Faltam modelos/ícones individuais para todos,
peso/qualidade/validade, mais receitas/culturas e roupas térmicas. Medicina é
básica; não há ferimentos completos.

Máquinas têm três receitas fixas: faltam esteiras, energia, fiação e automação
complexa. Escavação altera a superfície em até 4 m; não permite túneis volumétricos.
A jangada é simples; navios e navegação oceânica completa permanecem pendentes.

Construções têm colisão/comando/save, mas materiais, resistência estrutural,
destruição/reparo e territórios precisam expansão. Diplomacia possui alianças,
guerra/paz/tréguas; cercos, catapultas e gestão territorial completa não estão
concluídos. Ecologia, pets, NPCs/trocas, eventos e diário são parciais.

Descoberta pública, autenticação comercial, criptografia, predição/relevância
avançadas, WAL/fsync contra queda de energia, assinatura Windows, Steamworks e
material final de divulgação continuam pendentes. resource_rate afeta madeira;
dificuldades normal/difícil ainda são parciais.

A matriz e o roteiro estão em FEATURE_MATRIX.md e ROADMAP.md. Módulo, botão ou
teste isolado não certificam conclusão integral do jogo nem produto 1.0.

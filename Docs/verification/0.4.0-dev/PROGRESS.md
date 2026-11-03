# Progresso — reconstrução 0.4.0-dev

Criador: **felipealx**. Trabalho sobre a base publicada **0.3.1-dev / 18bb0cc**;
a implementação existente foi preservada. Esta revisão ainda está em validação
local e não foi publicada como jogo pronto ou versão 1.0.

O diagnóstico obrigatório anterior ao código foi registrado no commit **5992efc**,
em [Docs/RECONSTRUCTION_DIAGNOSIS.md](Docs/RECONSTRUCTION_DIAGNOSIS.md). O primeiro
lote integrado está no commit **21c8356**. Alterações posteriores passam por nova
validação antes da entrega. Os pedidos completos estão nos quatro arquivos
`Docs/REQUEST_*.md`; o histórico de uma solicitação cita 0.3.0, mas a base efetiva
conferida foi 0.3.1.

## Correções e integração atual

- Autoload Settings e `settings.cfg` único: preset aplica/salva imediatamente e
  reabrir painel não descarta a escolha. Rollback de 15 s limita-se ao display.
  Teste real de seis presets por pelo menos 120 s cada, mundo/menu e reinício em
  seis processos passou. Áudio pendente no encerramento foi reproduzido e corrigido.
- Alcance/altura/oclusão na árvore e ações de recurso/água/cozimento. Machado sofre
  desgaste e materiais caem fisicamente após a ação; coleta não concede madeira
  através de paredes nem consome uma árvore para inventário cheio silenciosamente.
- Cobertura usa colisão física; calor tem alcance/oclusão, combustível e chuva
  descoberta pode apagar o fogo. Calor válido pode interromper perda por frio,
  conforme o pedido de reconstrução, sem reiniciar o contador de chuva.
- Fauna distingue passivos/neutros/predadores. Neutros precisam de provocação;
  domesticação básica persiste dono. A expansão da IA/ecologia continua parcial.
- Descritor de mundo e schema v4, gerador antigo preservado. Nova jornada aceita
  seed e usa 320 × 320 m; chunks e registros estáveis suportam descarregamento e
  rebrota. Biomas/litoral/água/caverna/ruína são representações iniciais.
- Malhas originais novas de personagem, árvores/vegetação e fauna; rig conectado
  às ações reais. Inspeção visual e qualidade final ainda não concluídas.
- Peças modulares físicas, portas, cama/respawn, baús de materiais e canteiros.
  Construções avançadas/integridade completa ainda faltam.
- Coleta com duração/animação e objetos no chão; crafting com fila/reserva/cancelar,
  reparo, XP/pesquisa, cultivo de bagas, pesca com lança/cozinhar/consumir peixe e
  domesticação básica. Valores novos vêm de `Data/Balance.json`.
- Mapa real com exploração/marcadores; HUD sem a lista fixa de teclas, ajuda,
  tecnologia e armazenamento. Traduções novas e acessibilidade integral pendentes.
- Snapshots por destinatário, estado privado do dono e deltas; senha opcional,
  verificação de protocolo/versão, configuração de servidor e moderação por
  identidade. Cenários locais foram repetidos; senha/moderação abrangentes e carga ainda
  precisam de execução.
- Filtro de fontes exclui credenciais, arquivos privados e saídas; manifesto/
  recibo de build protege contra fontes alteradas durante exportação. Versão de
  produto e instalador deriva de `project.godot`.

## Resultados observados desta reconstrução

| Verificação | Resultado observado |
|---|---|
| Baseline antes de alterar código | 300,049749 s gráficos, saída 0; sem erro ou aviso de vazamento |
| Suíte completa final de regras/integração/processos | **458 verificações, 0 falhas** |
| Nova suíte integrada da cena real (incluída nas 458) | **83 verificações, 0 falhas** |
| Presets reais | Seis perfis por ≥120 s cada; seis reinícios; todos passaram |
| Integridade Python/build/fontes (incluída nas 458) | 12 verificações, 0 falhas |
| ENet isolado | Servidor + 2 clientes, ações/intenção e 4 rejeições maliciosas; passou |
| Cena real multiplayer | Dedicado + 2 clientes movendo-se, árvore compartilhada, save; passou |
| Reconexão e reinício | Identidade e 12 madeiras preservadas; passou |
| Migração solo → dedicado | Dono original, 37 madeiras e tribo preservados; passou |
| Comunicação real | 3 clientes; seis canais de texto e áudio sintético autorizado; passou |
| Abre/continua/fecha | **50 processos headless sequenciais, 0 falhas**, 124,95 s totais |
| Exportações 0.4.0-dev | Windows, Linux e servidor Linux gerados com recibo/hash |
| Pacotes locais 0.4 | Instalador NSIS e quatro ZIPs gerados; CRC/cabeçalhos/SHA256 verificados, Windows nativo pendente |
| Executáveis Linux | **6 verificações, 0 falhas**: cliente, dedicado, reinício, saves/locks |
| Capturas gráficas | Dez telas reais; dia/noite/personagem/mapa inspecionados em llvmpipe |
| Cliente Linux exportado gráfico | Abriu por 5 s em display virtual, sem erro/leak; aviso de VSync |
| Windows nativo 0.4 / sessão 30 min / microfone / hardware alvo / carga 8–16 | Pendentes |

As falhas encontradas em fixtures antigos foram corrigidas preservando as
regressões: duração de ações/fila, schema 4 e nova API de altura. A repetição final
completa passou. Foram acrescentadas regressões de troca de seed e restauração
de estrutura com mesmo ID e dono/tipo/rotação diferentes.

Uma tentativa de comunicação ficou em timeout com fases vazias: o fixture enviava
aparência antes da confirmação do servidor. O fixture passou a aguardar o ack e
usar a altura atual do terreno; a execução final passou. Áudio foi sintético, sem
microfone capturado. Esse sucesso não certifica comunicação sob carga.

A repetição de aberturas detectou nós de áudio pendentes; shutdown agora aguarda
referências fracas e remove emissores antes de sair. Cinquenta ciclos finais
passaram. As primeiras capturas gráficas emitiram erros ALSA por ausência de
dispositivo no ambiente; a repetição com driver Dummy não teve erros de shader.
Arte ainda é geométrica e a captura japonesa do mapa mostra texto novo em inglês.

Detalhes e limites em [Docs/RECONSTRUCTION_TEST_REPORT.md](Docs/RECONSTRUCTION_TEST_REPORT.md).
O relatório anterior [Docs/TEST_REPORT.md](Docs/TEST_REPORT.md) refere-se à 0.3.1.

## Medição e interpretação

Baseline: Xorg virtual/OpenGL Mesa llvmpipe, Muito Baixo/safe, Godot 4.6.3,
áudio Dummy, movimento automatizado e perfil isolado. Média **17,0538 FPS**,
2.188 nós constantes; memória estática Godot 102.095.654–102.435.954 bytes.
RSS só foi amostrado na segunda metade: 495.716–526.348 KiB. Esses contadores não
comprovam ausência de vazamento prolongado. Não representam Ryzen 4600G/GPU real
e não certificam meta de 60 FPS. Captura/métricas anteriores às mudanças foram
preservadas em `Docs/reconstruction-audit/before/`.

320² / 128² = **6,25× a área da malha anterior**; comparado ao clamp explorável
antigo de 120², é 7,11×. A nova extensão não comprova conteúdo balanceado, toda a
costa navegável, streaming perfeito nem desempenho final.

## O que ainda impede a entrega completa

[Docs/PENDENCIAS.md](Docs/PENDENCIAS.md) lista critérios de validação e produto.
QA Windows e workflow foram adaptados estaticamente à nova versão/schema/mundo,
mas não executados em Windows. Regras administrativas ainda são parciais:
resource_rate afeta madeira e normal/difícil não têm diferenciação completa.

Faltam, entre outros: conteúdo completo proposto, roupas térmicas, itens por
instância/peso/validade, agricultura/ecologia avançadas, barcos/terreno editável,
arte/animação final, territórios/alianças/guerras e proteção diplomática de 1 h,
NPCs, segurança comercial, descoberta/relevância/predição, carga, WAL/fsync,
Opus/eco/voz física, revisão linguística, gamepad físico, benchmark alvo e Steam.

A fonte runtime congelada dos exports tem SHA256
`1b3f0bcee08ae59de45212935832f823b4e847fbfded863c6ea80a301f1c3715`;
recibo e logs em [Docs/verification/0.4.0-dev](Docs/verification/0.4.0-dev).

A seção 22.6 do pedido complementar permite MVPs funcionais com pendências
explícitas. Ela não dispensa testes nem permite botões sem ação como sistema
concluído. A tabela de conteúdo solicitada ainda precisa confrontar cada proposta
com evidência de código/receita/uso; o relatório enviado pelo usuário é um plano.

## Publicação e histórico preservado

Última publicação confirmada: **0.3.1-dev**, commit **18bb0cc**, downloads antigos
inalterados. A validação Windows [41394174603](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41394174603)
e os resultados em [Docs/verification/0.3.1-dev](Docs/verification/0.3.1-dev) são
históricos dessa versão, não certificam a 0.4.0-dev. README/arquitetura/progresso
anteriores foram preservados nessa pasta para comparação.

Na tentativa anterior, a publicação parou por bloqueio403 e autenticação não
validada. Após a alteração do ambiente, API respondeu200, `gh` autenticou e o
repositório confirmou acesso de escrita. O remoto continha apenas o commit inicial
`bf0faa7`, sem ancestral comum com o projeto: os históricos foram integrados sem
remover trabalho nem usar force push. Código e cinco pacotes0.4-dev seguem para
publicação de desenvolvimento; confirmação remota e QA serão registrados depois
que forem observados. Veja [Docs/PUBLICATION.md](Docs/PUBLICATION.md).

## Publicação confirmada — 0.4.0-dev

Código e pacotes estão em main, com históricos preservados, e a [prévia está
publicada](https://github.com/teyranto7-cloud/Tribes-Of-Fire/releases/tag/v0.4.0-dev). O [QA Windows nativo](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41493048214) passou nos testes
de instalação/atalhos/runtime headless/persistência/reinício/reinstalação/uninstall.
Esse resultado substitui a pendência de execução headless Windows acima;
não certifica Windows gráfico, microfone, hardware alvo, carga ou jogo completo.

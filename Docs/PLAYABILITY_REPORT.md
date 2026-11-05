# Validação atual — 0.8.0-dev

Resultados atuais, comandos reproduzíveis e capturas estão em
[SETTLEMENT_REPORT.md](SETTLEMENT_REPORT.md); requisitos da conversa em
[REQUEST_TRACEABILITY.md](REQUEST_TRACEABILITY.md). Suíte 4.372/0, GUI 37/0 e
17/0, Windows nativo 34/0 incluindo upgrade e captura gráfica do EXE em VM.
O soak de três clientes passou na repetição, com pico de resposta de 4,5 s ainda
sem causa isolada. Hardware físico, microfone e playtest humano continuam pendentes.
Os números 0.5 a seguir são históricos e não descrevem a revisão atual.

# Validação e Fase 0 — 0.5.0-dev

Criado por **felipealx**. Continuação da base 0.4 no mesmo projeto Godot.
O novo plano integral está em [REQUEST_EVOLUTION_PLAN.md](REQUEST_EVOLUTION_PLAN.md).
Esta revisão conclui auditoria/estabilização dos incrementos já autorizados;
nenhuma fase nova de energia/automação avançada foi iniciada.

Checkpoint recuperável antes da auditoria complementar: `087472f`, branch
`checkpoint/0.5-playability-before-phase0`. O histórico e os instaladores anteriores
foram preservados. `Scenes/Main.tscn`, `Settings` e Compatibility continuam ativos.

## Fontes e execução

Godot **4.6.3 oficial**. Suíte completa: **564 verificações, 0 falhas**.

| Grupo | Verificações |
|---|---:|
| Regras, mundo, jogador, entrada e gameplay | 122 |
| Sistemas v3 | 109 |
| Regressões de gameplay, tribos, UI, voz e confiabilidade | 119 |
| Fechamento durante inicialização | 2 |
| Jogabilidade 0.5 | 106 |
| Reconstrução integrada preservada | 83 |
| Persistência/inicialização em processos | 11 |
| Integridade de build/fontes/credenciais | 12 |
| **Total** | **564** |

Impressão SHA256 das fontes da aplicação congelada:
`ae784b75629979b2acf132051df58f11453d0863e7108e35836d986417d66b71`.
O recibo associa essa impressão aos três binários Windows/Linux/dedicado Linux.
O empacotador recusa uma fonte ou binário diferente do recibo.

Cliente Linux exportado, dedicado e reinício passaram **6 verificações** sem
editor: abertura, snapshots íntegros, relógio avançando, jogadores preservados e
lock liberado. Servidor ENet e dois clientes passaram movimento, 35/36 snapshots por
cliente, árvore compartilhada, inventários individuais e persistência.
As **50 aberturas/salvamentos/continuações** sequenciais passaram, em 178,36 s.
Isso não equivale a uma sessão contínua de 30 minutos.

O cliente Linux exportado também abriu graficamente por cinco segundos reais
após inicialização, sem erro/leak observado (Xorg/llvmpipe; aviso de VSync não
suportado). O ZIP de fontes foi extraído sem cache, importado e executado com
salvamento válido: **2 verificações, 0 falhas**. Os cinco pacotes passaram CRC/
SHA256/tamanho e cabeçalho PE do instalador. Manifesto e logs estão nas evidências.

## Cobertura e inspeção

`Tests/test_playability.gd` exercita a cena Main e regras: normais externas dos
modelos; geradores antigos/mapa novo; dez pontos de interesse; rio; caminho de
obtenção de cada ID atual; craft/medicina; receitas/busca/UI; pá/altura/colisão;
fábrica sem duplicação; jangada/renascimento; liderança/aliança/trégua/guerra;
sol/lua e snapshots novos. Não comprova todo o catálogo proposto ou balanceamento.

Capturas reais em Xorg virtual/Mesa llvmpipe, preset Médio: menu, personagem,
dia/noite, fabricação, rio/jangada e horizonte. Imagens foram inspecionadas; a
captura usa pose congelada e relógio de inspeção. Não é benchmark de GPU física.
A primeira repetição falhou porque o display X11 estava encerrado; o display foi
reiniciado e a captura posterior passou, sem erro de script/renderização observado.

Inventário estático de arquivos, cenas, autoloads, plugins e referências literais:
`Tools/audit_project.py`. Ele não substitui testes de caminhos dinâmicos.
O carregamento próprio está em `HUD.loading`; logs de desenvolvimento continuam
disponíveis. Controle de clima requer `OS.is_debug_build()` e `--developer` no
host; os exports release não liberam essa ação no gameplay público.

## Falhas reproduzidas e correções

- Faces invertidas: produto médio vértice·normal -0,661 na malha original versus
  +0,5 no BoxMesh. Ordem dos triângulos corrigida e regressão de normais adicionada.
- Prazo CLI incluía inicialização: passou a contar tempo real após GAME_READY;
  os seis checks dos exports passaram após a correção.
- Fixture de 12 animais ajustado aos 96 novos, preservando validação das espécies;
  saves antigos de 12 animais continuam aceitos.
- Teardown manual deixava WAV sob carga: testes passaram a exercer shutdown real,
  com liberação do mixer e sem remover asserções.
- Multiplayer concorrente falhou no prazo; reduzir cosméticos em headless e
  compartilhar áudio por espécie permitiu repetição isolada aprovada. Não é carga.

## Pacotes e limites

Instalador NSIS por usuário e ZIPs Windows/Linux/dedicado/fontes usam a mesma
coorte e hashes. O [workflow nativo Windows 0.5 passou](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41560599160),
incluindo checksums/documentação e 24 verificações de instalação, atalhos,
runtime headless, restauração, reinstalação e desinstalação. Nenhum passo
obrigatório foi ignorado. Relatório nativo e logs foram baixados e preservados;
a aprovação é desta coorte. A matriz gráfica/manual continua pendente.

[Prévia publicada](https://github.com/teyranto7-cloud/Tribes-Of-Fire/releases/tag/v0.5.0-dev),
com os cinco pacotes e hashes versionados em Downloads/0.5.0-dev, fixados no commit
`b8bedca4810fabcc8ebca5d9224f8848d0cf6fd4`. Os cinco links públicos responderam
HTTP 200 com tamanho correto. O conteúdo runtime continua igual ao recibo.
Relatórios internos dos pacotes registram o estado anterior à execução do CI;
esta página e windows-report.json registram o resultado posterior observado.

**Fase 0 concluída no escopo verificado; próxima fase tecnicamente liberada.**
Nenhuma fase adicional será executada automaticamente. A liberação dos testes
básicos não certifica os requisitos finais do produto.

Evidências: [verification/0.5.0-dev](verification/0.5.0-dev).
Guia: [PLAYABILITY.md](PLAYABILITY.md). Matriz: [FEATURE_MATRIX.md](FEATURE_MATRIX.md).
Gráficos Windows interativos, hardware físico, carga 8–100 jogadores, sessão de
30 min, animações/arte finais e catálogo integral continuam pendentes.
Não há alegação de jogo 100% concluído.

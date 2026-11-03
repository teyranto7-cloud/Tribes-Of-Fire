# Relatório verificável da reconstrução — 0.4.0-dev

Criador: **felipealx**. Atualização em 2 de novembro de 2026. Linux x64, Godot
**4.6.3.stable.official.7d41c59c4**, renderer Compatibility. Resultados desta revisão
não equivalem à conclusão 1.0 nem à publicação. Evidências antigas em TEST_REPORT.md
e verification/0.3.1-dev continuam identificadas como históricas.

## A — Base e diagnóstico

Base pública **18bb0cc** (0.3.1-dev). Diagnóstico antes de alterar runtime no commit
5992efc, integração inicial **21c8356**. Não houve reinício de projeto/engine. Inventário
inicial: 246 arquivos, 42 scripts runtime, uma cena, 28 assets e 151 referências
literais, sem referência runtime quebrada ou duplicação binária por hash encontrada.
Leia [RECONSTRUCTION_DIAGNOSIS.md](RECONSTRUCTION_DIAGNOSIS.md) para severidade,
reprodução e dependências do estado anterior.

## B — Baseline real antes das mudanças

Cena real, perfil isolado, Xorg virtual/Mesa llvmpipe, Muito Baixo/safe, áudio Dummy
e movimento automatizado. 300,049749 s monotônicos, saída 0, sem erro ou vazamento
observado; aviso de VSync indisponível no display virtual.

5.117 frames, média 17,0538 FPS, 2.188 nós constantes; memória estática Godot
102.095.654–102.435.954 bytes. RSS só foi amostrado na segunda metade:
495.716–526.348 KiB. Não é benchmark do 4600G nem prova de estabilidade prolongada.
[Captura anterior](reconstruction-audit/before/baseline-gameplay.png) e métricas em
reconstruction-audit/before/ representam a base anterior às novas malhas.

## C — Opções gráficas e encerramento

Tools/test_settings_lifecycle.py executou seis processos Main/UI, cada perfil por
pelo menos 120 s monotônicos, conferindo aplicação/arquivo, reabertura do painel,
mundo/menu e reinício em seis processos adicionais. Todos passaram. Confira
[o resumo](verification/0.4.0-dev/settings-lifecycle.log) e os
[logs por perfil](verification/0.4.0-dev/settings).

A primeira execução encontrou playback WAV pendente no shutdown; verbose confirmou
a causa, e streams passaram a ser liberados antes de sair. Repetição final passou.
Outro caso de nós pendentes foi corrigido aguardando referências fracas e removendo
emissores; os 50 ciclos finais terminaram limpos. [Evidência de áudio](verification/0.4.0-dev/audio-shutdown.log).
Isso não certifica três modos de janela, multimonitor/DPI ou monitores físicos.

## D — Suíte completa e integração

A [execução final de build](verification/0.4.0-dev/build.log) passou em
**458 verificações, 0 falhas**:

| Suíte | Verificações aprovadas |
|---|---:|
| Regras / mundo / player / input | 61 / 25 / 11 / 8 |
| Gameplay / V3 | 17 / 109 |
| Regressões gameplay / tribos / UI / voz | 25 / 32 / 33 / 8 |
| Confiabilidade / fechar no carregamento | 21 / 2 |
| Reconstrução integrada Main | **83** |
| Processos: persistência / inicialização / integridade | 4 / 7 / 12 |

Os 83 novos checks cobrem seed/reprodução/diferença/área, chunks parciais, alcance
horizontal/vertical/parede, rig conectado, materiais físicos, pickup, desgaste,
rebrota, escrow/cancelamento sem duplicação, teto, estruturas/porta/baú, exploração,
marcador inválido, schema 4/migração/IDs/seed, privacidade por destinatário, animal
neutro/provocado, domesticação, fogo/chuva, pesquisa/custo, bagas e pesca/população/
cozinhar/consumir/save. As últimas oito regressões incluem trocar seed e restaurar
estruturas com o mesmo ID e dono/tipo/rotação diferentes.

As primeiras integrações expuseram fixtures com expectativa de crafting imediato,
schema 3 ou FlatWorld sem a nova API de altura. Fixtures foram adaptados mantendo
regressões e a suíte inteira foi repetida. Esses erros anteriores não foram
omitidos nem contados como aprovação. Tempo de regra simulado não é sessão real.

## E — Rede, reconexão e comunicação

O transporte ENet isolado passou com um servidor, dois clientes e quatro entradas
maliciosas recusadas. Novas execuções com a cena real também passaram:

- [Multiplayer](verification/0.4.0-dev/multiplayer.log): dedicado, dois clientes
  visíveis em movimento, árvore compartilhada e save do mundo. Clientes encerram
  com a desconexão esperada quando o servidor de teste fecha.
- [Reconexão/reinício](verification/0.4.0-dev/reconnect.log): peer IDs diferentes,
  mesma identidade e inventário de 12 madeiras, inclusive após reinício do servidor.
- [Migração solo → dedicado](verification/0.4.0-dev/host-migration.log): dono
  original, perfil 1, 37 madeiras e tribo preservados.
- [Comunicação final](verification/0.4.0-dev/communication.log): três clientes,
  seis canais de texto e áudio sintético codificado/reproduzido, privacidade e
  bloqueio. B recebeu 6 pacotes de proximidade e 4 em cada canal privado/tribo/
  grupo; C recebeu 4 de diplomacia. Nenhum microfone foi capturado.

Uma [tentativa anterior de comunicação](verification/0.4.0-dev/communication-first-failure.log)
ficou em timeout com fases vazias. O fixture enviava aparência antes do ack da
aparência padrão; passou a esperar a confirmação do servidor e consultar a altura
atual do terreno. A repetição final passou. Esse resultado não comprova estabilidade
de voz sob carga nem captura física.

Ainda faltam cenários abrangentes de senha correta/incorreta, protocolo/versão,
administração/ban/mute, deltas e carga 8–16/100 clientes. Não houve teste de Internet.

## F — Capturas reais e qualidade visual

Tools/capture_reconstruction.gd gerou dez telas OpenGL. Foram inspecionados
[personagem](verification/0.4.0-dev/screenshots/04-custom-character.png),
[dia](verification/0.4.0-dev/screenshots/05-world-day.png),
[noite](verification/0.4.0-dev/screenshots/06-world-night.png) e
[mapa](verification/0.4.0-dev/screenshots/08-world-map.png).
A arte continua geométrica/low-poly em desenvolvimento; o mapa japonês ainda
mostra texto novo em inglês. Não há certificação cinematográfica ou tradução final.

A primeira tentativa emitiu erros ALSA porque o ambiente não possui dispositivo.
A repetição com `--audio-driver Dummy` terminou sem erro de shader; permanece o
aviso de VSync indisponível. [Log gráfico](verification/0.4.0-dev/graphics-capture.log).
Renderer Mesa llvmpipe não representa GPU física. Costuras/navegação/colisão em
toda a área, tempestade e modos de janela ainda exigem verificação mais ampla.

## G — Conteúdo e progressão

Peças, pesquisa, crafting, bagas, pets e pesca são MVPs ligados à autoridade e
persistência, com fluxos específicos testados. O relatório de conteúdo do usuário
é proposta, não inventário implementado. A matriz item a item ainda está pendente.
Peso/validade/instâncias, roupas térmicas, medicina e progressão completa não foram
declarados implementados. Regras administrativas também são parciais: resource_rate
afeta madeira; normal/difícil não têm diferenciação completa. Baús guardam
materiais; equipamentos são recusados para
preservar durabilidade, que ainda é por tipo.

## H — Persistência

Schema 4 inclui descritor e novos módulos, migrando saves anteriores com terreno
legado. A suíte testa IDs/seed inválidos, migrações, progresso, pets, peixe e
restauração de estrutura. Processos separados passaram em encerramento forçado,
recusa de lock, recuperação explícita e liberação. Exports/reconexão/migração também
verificaram snapshots após reinício. Isso não é WAL/fsync nem garantia contra
queda de energia. Ações desde o último snapshot ainda podem ser perdidas.

## I — Preferências e 50 aberturas

[50 ciclos headless sequenciais](verification/0.4.0-dev/startup-50.log) passaram em
**124,9521 s totais**, com a mesma pasta de save, sequência final 50 e 0 falhas.
[Resumo](verification/0.4.0-dev/startup-summary.json). Isso é teste de abrir/
continuar/fechar processos, não sessão contínua de 30 min, Windows gráfico ou
validação de dispositivo físico.

Validação inicial de configurações trata tipos/limites e recuperação .bak de
arquivo inválido/versão incompatível; ainda falta cobrir todos os casos de tipos,
limites, permissões, multimonitor/DPI e gamepad físico. Sessão de 30 min permanece
pendente.

## J — Exportações, recibo e Windows

Após as 458 verificações, foram gerados Windows x64, Linux x64 e Linux dedicado.
O [recibo](verification/0.4.0-dev/build-receipt.json) identifica binários e fonte
runtime congelada SHA256:

```text
1b3f0bcee08ae59de45212935832f823b4e847fbfded863c6ea80a301f1c3715
```

[Execução dos exports Linux](verification/0.4.0-dev/exports.log): **6 verificações,
0 falhas**, incluindo cliente, servidor, reinício, snapshots e locks liberados.
O [cliente Linux exportado gráfico](verification/0.4.0-dev/export-graphics.log)
também abriu por 5 s no display virtual, `--safe` e áudio Dummy, sem SCRIPT ERROR,
ERROR ou vazamento observado; apenas VSync indisponível no llvmpipe. Não é benchmark.

Windows novo foi exportado, mas não executado em Windows nativo. O instalador
NSIS e quatro ZIPs foram gerados localmente; o empacotador verificou cabeçalhos,
CRC dos ZIPs e gravou SHA256/manifesto. Ainda precisam de instalação numa conta
Windows limpa; geração e integridade do arquivo não substituem esse resultado. A aprovação 0.3.1 não se
transfere à 0.4.0. QA PowerShell e workflow foram adaptados estaticamente para
schema4, seed/tamanho320 e versão dinâmica. Essa revisão de código não executou
instalação/upgrade/uninstall nativos; esses critérios continuam pendentes.

O [ZIP de fontes extraído em pasta nova](verification/0.4.0-dev/source-package.log)
passou em mais **2 verificações**: importação sem cache do checkout e execução
real com mundo de seed71991, save v4, 12 peixes, dois baús e lock liberado.
Artefatos/hashes locais: [manifesto](verification/0.4.0-dev/package-manifest.json).
Os pacotes preparados em `Downloads/0.4.0-dev` ainda não foram enviados.

## K — Publicação

Atualização: na nova tentativa, API respondeu200 e a autenticação confirmou acesso
de escrita. Histórico remoto inicial e trabalho local foram integrados sem force
push. A confirmação do envio e QA seguirá em [PUBLICATION.md](PUBLICATION.md).
O relato de403 abaixo é histórico da tentativa anterior.


Destino: https://github.com/teyranto7-cloud/Tribes-Of-Fire. A API recebeu bloqueio 403
do proxy na conexão HTTPS; gh auth status não validou a autenticação disponível.
Publicação suspensa conforme pedido, sem contorno. Nenhum push/release novo foi
confirmado. Liberar api.github.com e fornecer autenticação válida por segredo do
ambiente são necessários antes de repetir. Não colocar tokens no chat ou no Git.
Os resultados estão [resumidos em JSON](verification/0.4.0-dev/summary.json).

## L — Critério de conclusão

Não há conclusão 1.0. Permanecem sessão de 30 min, carga de 8–16, senha/moderação abrangentes,
Windows nativo, microfone físico, benchmark alvo, conteúdo/traduções e demais
pendências em [PENDENCIAS.md](PENDENCIAS.md). Somente execuções observadas podem
substituir pendências por resultados; código, botão ou script não são prova.

## Confirmação posterior de entrega

[Prévia0.4-dev publicada](https://github.com/teyranto7-cloud/Tribes-Of-Fire/releases/tag/v0.4.0-dev), código e pacotes em main.
[Workflow Windows41493048214](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41493048214) concluiu com sucesso e executou
todos os passos: verificação de pacotes/documentação, instalação/atalhos, runtime
headless/saves/reinício, reinstalação e desinstalação. Nenhum desses passos foi
pulado. Resultado posterior à geração dos ZIPs; Windows gráfico, áudio físico,
hardware e demais pendências permanecem.

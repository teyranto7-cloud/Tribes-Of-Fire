# Relatório verificável — 0.3.1-dev

Validação em Linux x64, Godot 4.6.3.stable.official.7d41c59c4. Revisão de
estabilidade da 0.3.0, preservando o jogo e os pacotes anteriores. Resultados
abaixo são execuções reais; exportar Windows não é prova de execução Windows.

## Suíte final e binários

`python3 Tools/build.py` importou e executou as doze suítes GDScript e três testes
Python, depois exportou Windows x64, Linux x64 e dedicado Linux. Saída observada:

```
RULES CHECKS=61 FAILED=0
WORLD CHECKS=25 FAILED=0
PLAYER_CHECKS=11 FAILED=0
INPUT CHECKS=8 FAILED=0
GAMEPLAY CHECKS=17 FAILED=0
V3 CHECKS=109 FAILED=0
GAMEPLAY_REGRESSIONS CHECKS=25 FAILED=0
TRIBES CHECKS=32 FAILED=0
UI_REGRESSIONS CHECKS=33 FAILED=0
VOICE_REGRESSION CHECKS=8 FAILED=0
RELIABILITY CHECKS=21 FAILED=0
STARTUP_CLOSE CHECKS=2 FAILED=0
PERSISTENCE_PROCESS CHECKS=4 FAILED=0
STARTUP_PROCESS CHECKS=7 FAILED=0
BUILD_INTEGRITY CHECKS=9 FAILED=0
```

Total: **372 verificações, zero falhas**. A execução final não registrou erros de
script nem avisos de recursos em uso/vazamento. Os nove testes do recibo usam
exports simulados para provocar alterações/falhas; os três exports de entrega
foram gerados separadamente pelo Godot real na mesma execução do build.

`python3 Tools/test_exports.py --keep-logs builds/verification/exports`:
**EXPORT CHECKS=6 FAILED=0**. Binários Linux executados fora do editor: solo,
dedicado e reinício; checksums, avanço do relógio, jogadores e locks conferidos.
Total com exports: 378 asserções, além dos cenários de rede abaixo.

O executável Linux também abriu com OpenGL 4.5 no Xorg virtual, iniciou jornada,
salvou e encerrou normalmente. Renderizador Mesa llvmpipe, aviso esperado de VSync
indisponível no display. Isso não certifica desempenho em GPU física.

## Regressões reproduzidas e corrigidas

- Corpo morto ainda aceitava movimento; intenção e movimento planar agora são
  bloqueados e o respawn limpa estados transitórios.
- Descartar e recuperar machado gasto restaurava sua durabilidade; metadado agora
  acompanha bolsa, save/reload e pickup real. Reservas sobrevivem à quebra.
- Mineração e saque aceitavam alvos através de paredes; raios verificam oclusão.
- Cozinhar o último item com inventário cheio falhava mesmo liberando um espaço;
  a transação considera o estado final.
- Configuração `ui.language` como Dictionary interrompia `_ready`; preferências
  inválidas recebem fallback, inclusive em startup real e modo seguro isolados.
- Setas eram consumidas pela navegação GUI antes do remapeamento; o painel recebe
  o evento na etapa correta. LOD personalizado deixava faixa invisível corrigida.
- Fechamento durante carregamento deixava corrotina/recurso pendente; geração é
  cancelada e finalizada antes de desligar. Teste verbose final sem vazamento.
- Novo mundo/sessão mantinha apresentação antiga de grupos/chat; reset limpa
  autoridade e UI. Desconexão limpa atores/comandos/canais e retorna ao menu.
- Saídas solo repetidas produziam mais de 2.048 proteções e invalidavam o save;
  teste de 3.000 ciclos e limites ativos passou com persistência.
- Dois slots corrompidos podiam virar mundo vazio sobrescrito; abertura agora
  obtém lock antes da leitura, recusa e preserva ambos os arquivos.
- Save legal com 1.024 inventários cheios ultrapassava o limite anterior; envelope
  de 16 MiB/payload de 8 MiB, admissão e mutações limitadas por orçamento. Gravação
  e restauração reais de todos os perfis foram conferidas.
- Identidade do antigo anfitrião não recuperava perfil `1` no dedicado; vínculo
  opcional ao hash do proprietário e validação do token corrigem a migração.
- A cinco FPS, o delta limitado pelo Godot atrasava relógio/exposição. O tempo
  monotônico acompanha três segundos reais mesmo com limite de oito passos.
- Reprodução de voz drenava um pacote por frame; agora usa capacidade disponível,
  mantém fila limitada e limpa streams ao mutar/desativar. Fechar o teste local
  encerra a ativação temporária. Testes usaram sinais sintéticos, sem microfone.
- Recibo antigo podia autorizar mistura de fontes/binários; testes provocam drift
  antes/depois das etapas e falhas, verificando recusa/remoção do recibo. Pacotes
  incluem os documentos vinculados e hash externo sem referência circular.

## Rede em processos separados

- `Tools/test_network.py`: servidor e dois clientes ENet; intenções válidas,
  payloads inválidos e administração indevida recusados: **NETWORK_PASS**.
- `Tools/test_multiplayer.py`: cena Main real, dedicado e dois clientes; movimento,
  visibilidade de atores e corte/coleta compartilhados, saves e saída limpa:
  **MULTIPLAYER_PASS** (8 madeiras observadas no estado compartilhado).
- `Tools/test_reconnect.py`: nova identificação temporária ENet, mesma identidade
  persistente, inventário de 12 madeiras após reconexão e reinício real:
  **RECONNECT_PASS**.
- `Tools/test_host_migration.py`: mundo solo real, save com vínculo do dono,
  reinício como dedicado e cliente original via ENet; perfil `1`, 37 madeiras e
  tribo preservados: **HOST_MIGRATION_PASS**.
- `Tools/test_communication.py`: dedicado e três clientes, seis canais de texto,
  bloqueio/privacidade, roteamento de áudio codificado, reprodução e recusa de
  dano aliado/pós-saída: **COMMUNICATION_PASS** nas duas repetições finais.
  B recebeu proximidade, privado, grupo e tribo; C somente diplomacia autorizada.
  Nenhum teste iniciou microfone físico.

Uma primeira execução de comunicação, concorrente ao build e outros cenários,
**falhou** porque B não recebeu pacotes de proximidade/tribo. Texto e áudio
privado/grupo funcionaram; o encerramento abrupto do fixture falho também mostrou
recursos pendentes. Não foi comprovada a causa. Repetições posteriores passaram,
mas não estabelecem estabilidade de voz sob carga, latência/perda extensa ou
Internet hostil. O transporte de voz é não confiável e não garante cada pacote.
Esses testes também não comprovam 100 jogadores ou segurança comercial.

## Distribuição e Windows

ZIPs Windows/Linux/dedicado/fontes e instalador NSIS Unicode com seis idiomas são
conferidos por CRC/SHA256, com manifesto em `Downloads/0.3.1-dev/`.
A assinatura runtime do build validado é:

`2d870fb77fae6583689ef5f658f43ae2694c358ccfdd47e2a65e7eba1307c5d3`

O empacotador compara a assinatura e os três hashes dos executáveis com o recibo
antes de gerar os arquivos. A fonte é congelada após importação e conferida em
cada etapa de teste/exportação. Nenhum pacote reutiliza o executável 0.3.0.

Após o push, o workflow [Windows installer and runtime](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/workflows/windows-qa.yml)
verifica os cinco hashes, documentação dos ZIPs, instalação/atalhos/documentos,
execução headless, snapshots, reinício, reinstalação e desinstalação preservando
saves em `windows-latest`. O resultado referente ao commit desta revisão deve ser
consultado em Actions; este texto acompanha a geração anterior a essa execução.
A [execução 41380465249](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41380465249)
aprovada anteriormente pertence à **0.3.0-dev**.

Windows 10/11 gráficos/interativos, troca entre versões instaladas, microfones
físicos, hardware de referência, Internet e 100 jogadores permanecem pendentes.
Instalador sem assinatura digital pode apresentar aviso do Windows.

## Medição gráfica anterior, sem novo benchmark de hardware

Na 0.3.0, nove amostras curtas a 1280 × 720 em llvmpipe/EPYC, câmera fixa, mostraram
redução diurna de draw calls após consolidação: Muito Baixo 548 → 416, Médio
1.934 → 1.302, Ultra 4.339 → 2.238. FPS posterior aproximado: 14,5–18,7 em Muito
Baixo e 1,8–2,8 em Médio/Ultra; renderização por software insuficiente. As amostras
não foram um comparativo controlado e não equivalem à GPU integrada 4600G.
Não há novo resultado de FPS, tempo de GPU ou teste de 60 FPS nesta revisão.

## Reprodução e limites

Logs locais em `builds/logs/` e `builds/verification/`; scripts/fixtures no checkout
permitem repetir os casos. Build/export/NSIS exigem ferramentas descritas no
README. Instalação/QA Windows exige conta de teste limpa. A matriz interativa está
em `Tests/MANUAL.md`; requisitos ainda ausentes estão em `Docs/AUDIT.md`.
Esta entrega é **0.3.1-dev**, sem certificação 1.0 ou publicação Steam.

## Validação Windows posterior à geração dos pacotes

A [execução 41394174603](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41394174603) do commit `908b647` foi observada com
status **Success**. Conferiu os cinco hashes/documentação dos ZIPs e executou
instalação, documentação/atalhos, jogo headless, saves/checksums, reinício dedicado,
reinstalação e desinstalação preservando dados. Relatórios JSON/CSV e logs estão
no artefato `windows-native-results` dessa execução.

As duas tentativas anteriores (41393773739 e 41394030410) falharam na conferência
dos ZIPs antes da instalação: o teste contava dois README no ZIP de fontes,
incluindo o documento legítimo de Assets/Audio. O workflow foi corrigido para
consultar o caminho exato do README principal. Os cinco artefatos permaneceram
inalterados; nenhum sucesso foi inferido do badge de uma execução anterior.

Uma cópia nova clonada do GitHub em caminho com espaços/acentos confirmou os cinco
hashes. O ZIP Linux desse clone executou fora do editor, salvou snapshot e
liberou o lock ao sair. A aprovação Windows é headless; as pendências gráficas,
de voz física, carga e desempenho listadas acima continuam válidas.

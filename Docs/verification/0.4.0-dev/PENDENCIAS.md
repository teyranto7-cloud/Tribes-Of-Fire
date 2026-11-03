# Pendências e critérios verificáveis — 0.4.0-dev

Criador: **felipealx**. A base pública 0.3.1-dev permanece preservada. Diagnóstico
anterior às alterações: [RECONSTRUCTION_DIAGNOSIS.md](RECONSTRUCTION_DIAGNOSIS.md),
commit 5992efc. Leia também os pedidos integrais REQUEST_RECONSTRUCTION.md,
REQUEST_RECONSTRUCTION_PART2.md, REQUEST_CONTENT.md e REQUEST_CONTINUITY_MASTER.md.

## Já observado

- Baseline real de 300,05 s antes de alterar a aplicação, saída 0, sem erro/leak.
- Falhas de presets, oclusão, desgaste, cobertura e neutralidade diagnosticadas
  antes das correções. Settings agora é autoload com arquivo único e aplicação
  imediata; seis presets esperaram ≥120 s reais cada e passaram por reinício.
- Nova suíte real Main: **83 verificações, 0 falhas**; cobre mundo/seed, coleta e
  objetos físicos, fila/cancelamento, estruturas/porta/baú, mapa, privacidade,
  migração, neutralidade/domesticação, pesquisa, bagas e pesca/cozinhar/consumir.
- Suíte final completa: **458 verificações, 0 falhas**, incluindo as 83 novas;
  versões anteriores dos fixtures foram adaptadas e as regressões preservadas.
- Integridade de build/fontes/credenciais: 12 testes Python passaram.
- ENet servidor + 2 clientes passou com 4 entradas maliciosas recusadas.
- Áudio pendente no encerramento foi reproduzido com verbose e corrigido;
  a repetição real de presets terminou sem o vazamento observado anteriormente.
- Cinquenta aberturas/continuações/fechamentos headless sequenciais passaram,
  em 124,95 s totais. Não é uma sessão contínua de 30 min.
- Três exports gerados; cliente/dedicado/reinício Linux passaram em 6 verificações.
  Cliente Linux exportado também abriu graficamente por 5 s no llvmpipe, sem
  erro/leak observado; só aviso de VSync. Não é validação Windows ou benchmark.
- Cena real multiplayer com 2 clientes, reconexão/reinício, migração solo para
  dedicado e comunicação com 3 clientes passaram. Áudio sintético, sem microfone.
- Dez telas OpenGL capturadas, com dia/noite/personagem/mapa inspecionados.
  Arte continua geométrica e há texto novo em inglês no mapa japonês.

Logs e recibo: [verification/0.4.0-dev](verification/0.4.0-dev).

## Bloqueios de validação antes de nova distribuição

1. Adicionar cenários abrangentes de senha correta/incorreta, protocolo/versão,
   administração, privacidade/deltas e carga 8–16 clientes. Os cenários locais
   observados passaram; isso não certifica exposição pública ou carga.
2. Completar todos os casos de preferências vazias/truncadas/tipos/limites/versão
   futura/permissão e backup .bak. Cinquenta aberturas já passaram; validação
   gráfica em Windows e dispositivos físicos continua separada.
3. Ampliar inspeção para tempestade e três modos de janela; testar costuras,
   navegação/streaming e colisão fora do início. Capturas observadas não provam
   toda a área nem qualidade cinematográfica final.
4. Executar 30 min contínuos e registrar memória/frames/saves. Não equiparar
   llvmpipe a GPU real; não anunciar 60 FPS sem benchmark do hardware alvo.
5. ZIPs/NSIS foram gerados localmente e passaram pela verificação de integridade.
   Executar o QA Windows
   já adaptado estaticamente para schema4, coordenadas e versão derivada; testar
   instalação/upgrade/desinstalação em Windows limpo. Exports Linux já passaram; Windows novo só
   foi exportado. Não transferir a aprovação antiga para o binário novo.
6. Completar traduções novas e a matriz individual do relatório de conteúdo,
   distinguindo código implementado, MVP parcial e proposta ausente.
7. Conferir os resultados nativos do workflow Windows antes de declarar a nova
   instalação validada. O acesso à API foi restabelecido e a autenticação existente
   funcionou; a publicação de desenvolvimento será conferida no remoto, sem force
   push. O estado atual está em PUBLICATION.md. As demais pendências impedem 1.0.

## Sistemas mínimos que ainda precisam expansão

- Mundo 320 × 320/seed/chunks, água/biomas/caverna/ruína têm código e testes iniciais;
  faltam exploração/geração amplas, distribuição final de recursos/ecologia,
  costuras e medição. Não é o continente final.
- Peças de casa/porta/cama/baú/canteiro têm colisão/comando/save. Integridade,
  materiais, destruição/reparo e permissões/território completos são parciais.
  Baús guardam materiais; equipamento é recusado para não perder durabilidade.
- Fila/pesquisa/XP, pesca, bagas e domesticação têm ações e persistência. Faltam
  estações/receitas/espécies/culturas/necessidades de pets da proposta completa.
- Novas malhas/rig/grama são originais, mas não certificam arte cinematográfica.
- Configuração de servidor, senha, deltas e moderação existem; falta validação
  abrangente de rede e segurança para exposição pública. `resource_rate` afeta
  madeira; dificuldade normal/difícil ainda não tem diferenciação completa.
- Mapa/exploração/marcadores existem; diário narrativo/conquistas/UI finais são
  parciais. Acessibilidade e tradução integral ainda incompletas.

## Produto ainda ausente ou parcial

Catálogo completo proposto; ícones/modelos individuais; peso/mochilas/pilhas e
qualidade/desgaste por instância; validade/conservação; roupas térmicas; cerâmica,
curtimento e medicina; NPCs/trocas; projéteis recuperáveis/ferimentos; estações/
eventos; diplomacia/alianças/guerras/1 h de proteção; transporte/barcos; fauna/
ecologia/pets avançados; trilhas e navegação completa; terreno editável; servidor
público/descoberta/autenticação comercial/criptografia/relevância/predição;
WAL/fsync/durabilidade contra energia; Opus/eco/microfones físicos; gamepad físico,
acessibilidade integral/multimonitor/DPI; benchmark alvo; assinatura Windows,
Steamworks e material final de divulgação.

Os novos parâmetros ficam em Data/Balance.json; a centralização de todos os
valores legados ainda precisa revisão. A seção 22.6 autoriza MVP com pendências
explícitas, não conclusão fictícia. Nenhum requisito pendente deve aparecer como
pronto só porque existe um módulo, botão, script de teste ou documentação.

## Atualização de publicação

Prévia0.4-dev publicada. QA Windows nativo aprovado: https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41493048214 .
Instalação/atalhos/runtime headless/persistência/reinstalação/uninstall foram
validados; essas partes dos itens5/7 acima estão concluídas. Gráficos/dispositivos
físicos, atualização entre versões distintas e os demais requisitos continuam pendentes.

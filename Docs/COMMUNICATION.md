# Comunicação de desenvolvimento

Texto: global; local por distância de 40 m; privado para identidade selecionada;
grupo por convite; tribo por filiação real; diplomacia para líder e participantes
convidados permitidos. A autoridade calcula os destinatários a cada mensagem.
Bloqueio funciona nos dois sentidos. Texto até 240 caracteres, cinco mensagens
por dez segundos, nomes/mensagens exibidos sem interpretar BBCode/HTML.

Grupos e bloqueios são persistidos com identidades estáveis. Convites de grupo
expiram em dez minutos. Grupos têm até cem membros, 64 grupos por mundo.
Salas diplomáticas deixam de autorizar o líder antigo após transferência de poder.
Ainda não há oficiais, alianças ou canais territoriais.

Voz permanece desativada em cada nova abertura. Ativação pela interface é
necessária mesmo após salvar volumes/mudos. V é PTT; ativação por nível de voz é
opcional. O botão de teste inicia um retorno local explicitamente solicitado.
Desativar voz para captura e reprodução. Uma chamada não ativa microfone.

Pacote: 640 amostras mono/16 kHz, 40 ms, 325 bytes com IMA ADPCM independente.
Carga de codec: 8.125 bytes/s (~65 kbit/s), mais envelopes de RPC/ENet/IP. O limite
da autoridade é 30 pacotes/s; o fluxo normal é 25. Não é Opus nem compressão
fingida. Captura usa o mixer Godot e resampling simples; melhoria de filtro e
codec é trabalho posterior.

Canal ENet 3 não confiável, separado de comandos/snapshots. A autoridade valida
tamanho, codec, remetente, vida, criação de personagem e autorização de sala.
Roteamento de proximidade usa posições do servidor, com alcance de 30 m.
Chamadas privadas só enviam áudio após aceite; terceiros não recebem os pacotes.
Grupos, tribos e diplomacia são remotos e não perdem volume pela distância.
Proximidade tem ganho contínuo: integral até 5 m, decai até zero em 30 m, e posição
3D do emissor. Volume/mudo individual usam identidade estável.

Recepção tem limite de 32 emissores, início com dois pacotes ou espera de 80 ms,
fila máxima de cinco pacotes e descarte dos antigos/duplicados. Até duas perdas
consecutivas são substituídas por silêncio. Isso não equivale a PLC avançado.
Após cinco segundos sem áudio, receptor inativo é removido.

Não há gravação de voz/chat em disco. O sistema não oferece criptografia de ponta
a ponta, autenticação comercial, cancelamento de eco ou supressão de ruído.
Nenhuma voz de pessoa foi capturada nos testes automatizados. A suíte injeta um
sinal sintético no mixer, captura, codifica, transmite entre processos, decodifica
e alimenta AudioStreamGenerator; não prova qualidade de microfone/alto-falante.

Teste humano pendente: dois computadores, fones, devices separados, V/ativação,
chamadas recusadas/aceitas, deslocamento 5/15/30/31 m, grupo/tribo remotos,
transferência de liderança, mudo/bloqueio, reconexão, perda/latência e ausência de eco.


## Auditoria 0.7.1

Três clientes voltaram a passar os seis canais, bloqueio e privacidade com sinal
sintético. Em ~4 m o ganho observado foi 0,80; em ~15 m, 0,287; fora de 30 m não
houve recepção de pacotes de proximidade. Não houve captura de microfone. Voz com
dispositivos físicos/latência/audibilidade segue PENDENTE, inclusive os passos
humanos listados acima. Canais automáticos de aliados e pings temporários não
foram adicionados durante a auditoria. Relatório: AUDIT_PHASES_1_3.md.

# Entrega verificada — 0.7.0-dev

Tribes of Fire · criado por **felipealx** · 04/11/2026.

A entrega continua a base remota 634f07e, incluindo o catálogo da Fase 3. O checkpoint
local c18c55f foi preservado em `checkpoint/phase2-before-remote-integration`; suas
medições e implementação não são apresentadas como evidência da build atual.
O gerador publicado, os saves e os 100 itens/89 receitas/17 bancadas foram mantidos.

## Correções

- Eventos e snapshots tardios deixam de acessar o jogo/áudio durante encerramento.
- Um pickup próximo pode ser coletado junto de um baú; depois o baú continua abrindo.
- A atualização dos canais de comunicação conserva a identificação do baú aberto.
- A interface acompanha a janela real, sem reduzir apenas uma tela virtual fixa.
- O texto em inglês usa a origem inglesa, evitando fallback para português.

## Resultados observados nesta revisão

| Verificação | Resultado |
|---|---|
| Build completo: regras, integração e processos | **4209 checks, 0 falhas, 21 runners** |
| Regressões novas de coleta, baú e encerramento | 9/0, incluídas acima |
| Catálogo e ciclos da Fase 3 | 804/0, incluídos acima |
| Binários Linux: solo, dedicado e reinício | 6/0; execução sem editor |
| ENet: dois clientes e servidor | Ciclos, coleta, replay, reconexão e reinício limpo passaram |
| GUI e produção com mouse/teclas | **34/0**, sete capturas, 1280×720 / 1920×1080 / 800×600 |
| Exportações | Windows x64, Linux x64 e servidor Linux; recibo fonte/binários |
| Pacotes | Instalador NSIS + 4 ZIPs; 5 hashes e tamanhos conferidos |
| ZIP de fontes extraído em diretório limpo | 2/0: importação e jogo/save reais |
| QA Windows nativo | Resultado do workflow desta revisão é registrado após o envio |

Logs, capturas e recibo: [verification/0.7.0-dev/delivery](verification/0.7.0-dev/delivery).
Os registros anteriores dessa pasta pertencem à base da Fase 3, antes destas correções.

A GUI foi executada em Xorg/Mesa llvmpipe. Teclas e cliques passam pelo sistema de
input do Godot. Há itens de fixture para a inspeção da UI; o teste ENet verifica
coleta e progressão sem conceder matérias-primas. A sequência de UI desliga somente
o desenho 3D; a captura de mundo reativa o 3D. Isso não mede FPS de GPU física.

## Repetir

```sh
python3 Tools/build.py
python3 Tools/test_phase3_network.py
python3 Tools/test_exports.py
python3 Tools/render_check.py --script res://Tools/capture_delivery.gd --log builds/delivery-gui.log --virtual-display
python3 Tools/package.py
python3 Tools/test_source_package.py
```

O display virtual exige Xorg com driver dummy; omita `--virtual-display` ao usar um
display existente. Perfis de testes são isolados. NSIS gera o instalador per-user,
com idiomas, atalhos e desinstalador; manifesto e SHA256 identificam os cinco arquivos.

Continuam pendentes sessões prolongadas em hardware físico, Windows gráfico,
voz/microfone reais, multiplayer com perda/latência externa e carga de 100 jogadores.
Arte final, conteúdo integral, energia/esteiras e integração Steam não são declarados
concluídos. O instalador e o ZIP não transformam a versão de desenvolvimento em 1.0.

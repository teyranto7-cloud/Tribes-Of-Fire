# Progresso — 0.3.1-dev

Criado por **felipealx**. Validação em 2 de novembro de 2026 (UTC), Linux x64,
Godot **4.6.3.stable.official.7d41c59c4**. Correções reais sobre 0.3.0-dev;
os critérios obrigatórios de 1.0 continuam incompletos.

## Implementado e integrado

- Funcionalidades anteriores preservadas: mundo/colisões, câmera, árvores/coleta,
  inventário, crafting, fogueiras, telhados, dia/noite, clima, host/dedicado e saves.
- Criação de personagem com preview real, nome, 18 parâmetros, variação de cabelos,
  barbas/olhos/roupa, altura cosmética 1,35–1,65 m e Skeleton3D de nove ossos.
  Aparência validada pela autoridade e restaurada do save. Arte ainda inicial.
- Agachamento com mudança real de cápsula e teste de espaço para levantar,
  esquiva com stamina/cooldown, defesa, câmera suave/zoom e controles remapeáveis.
- Catálogo de recursos, ferramentas, armas e armaduras; 36 espaços, arrastar/dividir,
  equipar, consumir, descartar e recuperar bolsas, transações de custo/recompensa.
- Fome, sede, alimentos, fonte potável, cozinhar carne junto ao fogo, morte e
  renascimento inicial; sem camas ou seleção de ponto de respawn.
- Mineração/coleta em 22 depósitos, picaretas, bancada/fornalha com colisão/custo,
  fundição cobre/bronze/ferro/aço e receitas que verificam estação próxima.
- Seis espécies/12 animais com navegação em grade e física, fuga/perseguição,
  retorno, ataque com aviso, limite 20 HP, cadáver e saque concedido uma vez.
- Combate autoritativo com armas/munição, alcance e oclusão, stamina/cooldown,
  durabilidade, armadura, bloqueio/esquiva. Arco usa acerto por raio nesta fase.
- Tribos, líder, convites, entrada/saída/expulsão/transferência; dano aliado recusado.
  Proteção bilateral de 300 s após saída/expulsão, persistida por identidade/UTC.
- Chat global/local/privado/grupo/tribo/diplomacia, histórico limitado, comandos,
  grupos por convite, bloqueio, salas privadas por aceite e roteamento server-side.
- Voz real opt-in: captura/mixer, resampling, IMA ADPCM, canal ENet separado,
  validação, decodificação, fila limitada, reprodução espacial ou remota autorizada.
  Volumes/mudos individuais persistidos; microfone desativado a cada abertura.
- Seis idiomas e fonte japonesa, 233 entradas em cada catálogo; primeira escolha,
  troca em execução e persistência. Algumas mensagens técnicas antigas precisam
  de migração; revisão linguística nativa integral ainda pendente.
- Seis perfis gráficos, Médio padrão, escalabilidade real e configuração pendente;
  confirmação de resolução em 15 s sem persistir preview, fallback `--safe`.
- Áudio original em 20 WAV, música por estado com crossfade, sons posicionais,
  passos, pooling e buses/volumes independentes persistidos.
- Persistência v3 de aparência/espaços/equipamentos/necessidades/tribos/grupos/
  bloqueios/fauna/recursos/estações/bolsas, migrações anteriores, schema/checksum/lock.
  Chamadas e convites de comunicação exigem novo aceite após reinício do processo.
- Logs técnicos de inicialização/salvamento sem conversas, voz ou tokens.
- Consolidação das malhas estáticas de árvores/depósitos por material, preservando
  triângulos, colisões, animação de queda e LOD; IA/animação reduzidas à distância.
- Exportação real Windows/Linux/dedicado; recibo de hashes impede empacotar fontes
  ou binários diferentes dos exportados. Setup mantém TLS/SHA512/APT verificados.
- NSIS Unicode com seis idiomas, opção de atalho marcada por padrão, menu Iniciar,
  lançamento final, ícone, instalação por usuário e desinstalação preservando dados.
  Script PowerShell de QA para conta Windows limpa e modo seguro no pacote Windows.

## Auditoria e estabilização da 0.3.1-dev

- Corrigidos movimento/intenção após morte e estado transitório no respawn.
- Durabilidade acompanha bolsas descartadas, persistência e recuperação; uma
  ferramenta quebrada não destrói a reserva nem a restaura através do descarte.
- Mineração, saque de cadáver e bolsas respeitam oclusão física; cozimento usa
  transação que permite liberar o último espaço ocupado pela carne crua.
- Preferências malformadas recebem valores válidos; modo seguro foi testado em
  processo real e a janela pode fechar durante a geração sem vazar recursos.
- Setas remapeadas chegam ao painel antes da navegação GUI; LOD não deixa uma
  faixa vazia com distância personalizada; chat/grupos/voz limpam estado ao trocar
  de sessão e desconexão retorna ao menu com estado local coerente.
- Relógio/clima/exposição passam a usar tempo monotônico; teste a cinco FPS com
  limite de oito passos comprova acompanhamento do tempo real.
- Lock adquirido antes de carregar; ambos os slots corrompidos são preservados e
  recusados. Save grande com 1.024 perfis cheios realmente gravado e restaurado.
  Admissão respeita limite de perfis e orçamento de payload antes de inserir dados.
- Proteções tribais expiradas são podadas, saídas solo não criam histórico inútil,
  duplicatas equivalentes são consolidadas; limite cheio recusa mutação atomicamente.
- Migração solo → dedicado vincula o anfitrião à identidade original, preservando
  inventário e tribo. O teste real restaurou 37 madeiras e perfil `1` por ENet.
- Voz escoa vários pacotes por frame, limita backlog de captura e limpa reprodução
  ao desativar/mutar. Teste de microfone termina ao fechar o painel, sem manter
  ativação temporária. Nenhum teste iniciou microfone físico.
- Recibo de build congela as fontes após importação e detecta alterações em cada
  etapa; falha invalida recibo antigo. ZIPs e NSIS incluem documentação vinculada.

## Evidências reproduzíveis desta revisão

| Verificação | Resultado |
|---|---|
| Importação e parser | Sem erros |
| Seis suítes anteriores (regras/mundo/player/input/gameplay/v3) | 231 verificações, 0 falhas |
| Regressões gameplay / tribos / UI / voz / confiabilidade / fechar carregamento | 25 + 32 + 33 + 8 + 21 + 2 = 121 verificações, 0 falhas |
| Processos: persistência / inicialização / integridade do build | 4 + 7 + 9 = 20 verificações, 0 falhas |
| Total no build final | **372 verificações, 0 falhas** |
| Exportação Windows/Linux/dedicado | Três executáveis gerados sem erros |
| Linux exportado: solo/dedicado/reinício | 6 verificações, 0 falhas |
| Executável Linux OpenGL em display virtual | Abriu, salvou e saiu; llvmpipe, aviso de VSync indisponível |
| ENet isolado / jogo real com dois clientes | Passou; coleta e estado compartilhados |
| Reconexão / reinício / migração solo → dedicado | Passou; inventário, identidade e tribo preservados |
| Comunicação com três clientes | Passou nas duas repetições finais; ver ocorrência anterior abaixo |
| Windows nativo desta revisão | [Aprovado](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41394174603); instalação, documentação, atalhos, headless, saves, reinício, reinstalação e uninstall |
| Windows 10/11 gráficos, microfone físico, 4600G e 100 jogadores | **Não validados** |

Registros detalhados em [Docs/TEST_REPORT.md](Docs/TEST_REPORT.md). As seis
verificações dos exports acrescentam-se às 372 (378), sem contar marcadores de
cenários multiprocesso como se fossem asserções individuais.

Uma execução de comunicação simultânea a build e outros cenários falhou: B não
recebeu voz de proximidade/tribo; canais privado/grupo e mensagens funcionaram.
Houve também aviso de recursos no encerramento abrupto do fixture que falhou.
Duas repetições posteriores passaram com saída limpa. Não foi provada a causa
nem estabilidade de voz sob carga; essa limitação permanece explícita.

O aviso reproduzido ao fechar durante carregamento foi corrigido cancelando a
geração e finalizando a corrotina antes do shutdown. A suíte final completa não
registrou erros nem avisos de vazamento. O display virtual emite aviso de VSync,
que não representa validação de driver/hardware do usuário.

## Medição e limites

Nove amostras curtas de renderização, câmera fixa, 1280 × 720, OpenGL/Mesa llvmpipe,
CPU reportada EPYC 9V74, cinco processadores visíveis. Aquecimento de 1 s e amostra
de 4 s para dia/noite/tempestade em Muito Baixo/Médio/Ultra. JSON antes/depois em
builds/reports/. A execução posterior coincidiu parcialmente com trabalho de build,
portanto tempos/FPS não constituem comparação controlada de ganho.

Chamadas de desenho diurnas: Muito Baixo ~548 → ~416, Médio 1.934 → 1.302,
Ultra ~4.339 → 2.238. Memória estática reportada pelo Godot caiu aproximadamente de
114–118 MiB para 101–102 MiB nessas amostras. Esse contador não é RSS total.
FPS posterior: ~14,5–18,7 em Muito Baixo e ~1,8–2,8 em Médio/Ultra. O renderizador
é software; desempenho permanece insuficiente nesse ambiente e não é o resultado
da GPU de referência. Tempo de GPU não disponível; não foi inventado.

Sete telas reais inspecionadas em builds/screenshots/v3/ mostram idiomas, menu,
criador, aparência, japonês, gráficos e inventário. A inspeção ampliou o personagem
no preview e confirmou glyphs japoneses; não certifica arte final ou revisão nativa.

## Pendências que impedem 1.0

Construção modular completa/baús/camas, agricultura/ecologia e regeneração dos
recursos, mundo amplo/seed selecionável/streaming/biomas/cavernas/barcos/terreno
editável, arte/animações cinematográficas finais, territórios/alianças/guerras,
proteção diplomática de 1 h, autenticação/senha/segurança comercial, relevância de
rede/predição/testes de carga, journal/WAL/energia, Opus/eco/voz física, revisão
linguística integral, Windows reais, benchmark no hardware alvo e Steamworks.

Depósitos e fauna são finitos nesta versão; alguns minérios não têm progressão
completa. Durabilidade é por tipo de item. Snapshots ainda compartilham inventários
de outros jogadores. A matriz detalhada e critérios de liberação estão em
Docs/AUDIT.md. Não publicar esta entrega como 1.0 nem prometer desempenho validado.

## Entrega pelo repositório

Código e pacotes são preparados para a branch main do repositório
teyranto7-cloud/Tribes-Of-Fire. O README contém links para instalador e ZIPs em
Downloads/0.3.1-dev, acompanhados de manifesto e SHA256. Essa pasta é excluída dos
exports, da impressão digital runtime e do ZIP de fontes para impedir cópias
recursivas. A suíte de 372 verificações e as três exportações foram repetidas
após ajustar essas exclusões. O teste Windows aceita modo headless para CI;
qualquer resultado Windows depende de execução real posterior, não desta preparação.

## Evidência Windows da versão anterior (0.3.0-dev)

A [execução do workflow Windows](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41380465249)
foi observada com status público **passing**. O job usa windows-latest e testa
o instalador, atalhos, inicialização headless, snapshots/checksums, reinício
dedicado, preservação de jogadores/relógio/lock, reinstalação da mesma versão e
desinstalação preservando dados. Os relatórios JSON/CSV e logs estão no artefato
da execução. Essa evidência atualiza as notas anteriores dos pacotes, gerados
antes do CI; os executáveis permanecem identificados por SHA256.

Não houve teste gráfico em Windows 10/11, microfone físico ou benchmark no
hardware alvo. Essas pendências e a matriz 1.0 continuam válidas.

## Entrega e confirmação final da 0.3.1-dev

Os cinco pacotes foram publicados em Downloads/0.3.1-dev e conferidos por um clone
novo do GitHub. O jogo Linux extraído desse clone executou e salvou corretamente.
A [execução Windows 41394174603](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41394174603) foi aprovada para os mesmos
artefatos. As tentativas anteriores identificaram uma falha no teste de caminhos
dos documentos do ZIP de fontes; corrigida no workflow sem alterar os binários.
Evidências e limitações em Docs/TEST_REPORT.md e Docs/verification/0.3.1-dev/.

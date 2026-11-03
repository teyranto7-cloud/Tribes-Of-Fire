# Arquitetura — 0.3.1-dev

A implementação 0.1 foi materializada e preservada. `Main.gd` coordena entrada,
ciclo de vida, autoridade, saves e replicação; `Game/Runtime.gd` integra os novos
comandos e módulos sem substituir as funcionalidades anteriores.

| Módulo | Responsabilidade atual |
|---|---|
| World | Terreno 128 × 128 m, seed 1337, colisão, 160 árvores, LOD, grama MultiMesh, água, sol/lua, relógio |
| Player / Character | CharacterBody3D autoritativo, câmera, movimento, agachamento/esquiva, modelo e Skeleton3D de nove ossos, aparência cosmética validada |
| Core / Items | 36 espaços, pilhas, transações, equipamentos/durabilidade, catálogo e receitas, vida e regeneração segura |
| Survival | Fome/sede, consumo real de alimentos/água, cozimento, dano por privação |
| Weather | Transições, vento, chuva, temperatura, relâmpagos/trovões, exposição e eventos cronológicos de dano |
| Building | Fogueira com calor/áudio, abrigo com telhado físico, bancada e fornalha |
| Mining | 22 depósitos/coletáveis, alcance e ferramenta, consumo autoritativo persistido |
| Animals | Seis espécies/12 animais, AStarGrid2D sobre terreno, perseguição/fuga, ataque com aviso, morte e saque único |
| Combat | Alcance, direção, oclusão por raio, resistência/cooldown, bloqueio, esquiva, armadura, arma/amunição, PvP e limites de dano |
| Tribes | Líder, convites, entrada/saída/expulsão, proteção bilateral com expiração UTC persistida |
| Networking | ENet, quatro canais, intenção e comandos com whitelist, limite de frequência, snapshots confiáveis a 10 Hz |
| Communication | Roteamento server-side, grupos/salas/chamadas, texto, captura opt-in, codec IMA ADPCM, jitter limitado e reprodução espacial/remota |
| Graphics / UI / Localization | Configuração aplicada/pendente, preview de resolução, seis perfis, seis catálogos, fonte CJK, painéis funcionais |
| Audio | Pool de 16 efeitos posicionais, passos, ambiente e música com transições, buses independentes |
| Persistence | Schema v3, migrações, SHA256, dois slots, temporário validado e lock exclusivo |
| Tools / Tests | Setup fixado, testes de regras/integrados/processos, exportação, recibo de build, ZIPs, NSIS, QA Windows e amostragem gráfica |

## Autoridade

Solo, anfitrião e dedicado usam as mesmas regras. Peer IDs vêm do transporte;
clientes enviam intenções e identificadores permitidos, sem conceder itens, HP,
dano ou posição final. O servidor valida física, alcance, recursos, cooldown,
ferramentas, receitas e espaço. Aparência tem schema e limites cosméticos.
Clientes interpolam jogadores; não há predição avançada ou compensação de latência.
Estados grandes usam fragmentação confiável; falta protocolo incremental por
relevância. Inventários ainda constam nos snapshots compartilhados, uma limitação
de privacidade que precisa ser removida antes de servidores públicos.

O handshake vincula peer temporário a hash de token aleatório local persistido;
reconexões recuperam o jogador, e identidade duplicada é recusada. O metadado
opcional `host_identity` vincula o hash do dono ao perfil histórico `1` ao migrar
solo/hospedagem para dedicado. Enviar o hash público como token não autentica seu
dono. Saves antigos sem vínculo precisam ser abertos e salvos pelo anfitrião
original antes da transferência. Transporte e
token não têm a segurança de autenticação comercial. Testar apenas em redes de
confiança nesta fase. Senhas, Steam e criptografia são trabalho pendente.

Grupos, bloqueios e chamadas não são enviados nos snapshots gerais. Cada jogador
recebe apenas seus grupos, chamadas e convite por evento dirigido. A autoridade
seleciona destinatários por posições e filiação reais; mudança de liderança retira
a autorização diplomática. Chamadas exigem aceite e terminam na desconexão.
Proteção de saída de tribo captura membros/tribo anteriores com expiração UTC;
mudar de tribo ou desconectar não a elimina. Relógio UTC do servidor deve ser
administrado corretamente; não existe proteção contra alterações do relógio do SO.

## Tempo, chuva e sobrevivência

Apenas a autoridade avança exposição e HP. Relógio, clima, fome/sede e exposição
usam o tempo monotônico real (`Time.get_ticks_usec`) para evitar que o limite de
passos/delta do Godot atrase as regras em baixo FPS. Movimento/combate mantêm a
física em passo fixo. Cobertura é consultada na posição atual; uma pausa longa
não reconstrói movimentos ou mudanças de teto que o servidor não simulou. `Exposure.advance` divide o tempo nos
limites de 40/55/70 s e integra eventos em ordem cronológica, inclusive ticks longos.
A partir de 40 s de chuva sem teto, regeneração é suspensa. Primeiro dano em 55 s,
1 HP a cada 15 s. Teto ou fim de chuva reinicia exposição; calor não reinicia.
Após dano, espera configurável padrão de 6 s; em segurança, regeneração de 1/3 s.
Fome/sede zeradas e combate também suspendem regeneração. Morte não regenera.
As regras novas prevalecem conforme o prompt de auditoria final armazenado em Docs.

## Apresentação e orçamento

Compatibility, sem SSR/GI/volumetria afirmados. Nuvens e água usam shaders; luzes
locais, sombras, partículas, distância e MultiMesh têm orçamento por perfil.
Som e efeitos não modificam regras climáticas. IA reduz decisões/animação longe
dos jogadores. Não há streaming nem mundo volumétrico/terreno editável.

Voz: AudioStreamMicrophone → AudioEffectCapture → mono 16 kHz → pacotes IMA ADPCM
independentes de 40 ms/325 bytes → ENet não confiável, canal 3 → validação de
remetente/canal/destinatários → decode → fila de até cinco pacotes →
AudioStreamGenerator. Proximidade 30 m, salas autorizadas com áudio remoto.
Sequências duplicadas são descartadas e lacunas curtas recebem silêncio.
Opus, cancelamento de eco, supressão de ruído, segurança do transporte e testes de
microfones físicos continuam pendentes. Não é uma implementação Opus simulada.

## Persistência e entrega

Snapshots alternados não são banco transacional/WAL. Um slot válido anterior
permanece durante substituição do outro; checksum/schema recusam corrupção.
Lock de diretório impede dois processos escritores. A abertura autoritativa
obtém o lock antes de selecionar o snapshot; slots existentes inválidos causam
recusa, sem gerar um mundo vazio. Envelope de até 16 MiB, payload de até 8 MiB,
até 1.024 perfis históricos; admissão e mutações sociais reservam/verificam espaço
antes de comprometer o estado. Registros expirados de proteção são eliminados e
novas proteções nunca removem proteções ativas para abrir espaço. Crash deixa lock para
recuperação explícita, sem apagar estado possivelmente ativo. Saves anteriores
migram para v3. Não há garantia de fsync/durabilidade por queda de energia.

`Tools/build.py` importa, testa, exporta três plataformas e grava hashes de fontes
runtime/binários. A assinatura é congelada após importação, conferida antes e
depois de cada etapa; uma falha invalida o recibo e não autoriza empacotamento. `package.py` exige esse recibo, valida executáveis e ZIPs, inclui
licenças e cria manifesto SHA256. NSIS é per-user Unicode, com seis idiomas.
Fonte Noto CJK é redistribuída sob SIL OFL, com licença incluída. Binário Windows
compilado no Linux é conferido pelo workflow nativo Windows após o push. Isso
verifica instalação e runtime headless; renderização e áudio físicos precisam de
validação em desktop real. Documentação vinculada acompanha ZIPs e instalação.

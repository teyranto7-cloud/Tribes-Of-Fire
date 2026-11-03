# Tribes of Fire

Criado por **felipealx** · **0.3.1-dev** · Godot 4.6.3 · Windows/Linux x64

Jogo de sobrevivência 3D em desenvolvimento, continuado a partir da base 0.1.
Inclui solo, hospedagem por jogador e servidor dedicado autoritativo. Esta entrega
corrige a versão 0.3.0 após auditoria e testes de regressão; ainda faltam requisitos
obrigatórios para a versão 1.0.
Consulte [PROGRESS.md](PROGRESS.md) para resultados e limitações verificáveis.

## Download e código-fonte

Pacotes **0.3.1-dev**, disponíveis neste repositório e sem necessidade do editor
para jogar:

- [Instalador Windows x64](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.3.1-dev/TribesOfFire-0.3.1-dev-Windows-Setup.exe)
- [Windows ZIP](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.3.1-dev/TribesOfFire-0.3.1-dev-Windows.zip)
- [Linux ZIP](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.3.1-dev/TribesOfFire-0.3.1-dev-Linux.zip)
- [Servidor dedicado Linux ZIP](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.3.1-dev/TribesOfFire-0.3.1-dev-Server-Linux.zip)
- [Fontes ZIP](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.3.1-dev/TribesOfFire-0.3.1-dev-Source.zip)
- [Hashes SHA256](Downloads/0.3.1-dev/SHA256SUMS.txt)

Para clonar o projeto completo:

```sh
git clone https://github.com/teyranto7-cloud/Tribes-Of-Fire.git
cd Tribes-Of-Fire
```

Para executar o código-fonte, instale o Godot 4.6.3 padrão, importe
`project.godot` e pressione F5. Código, recursos, licenças, testes, presets e
scripts de build acompanham o checkout. Os pacotes ficam em `Downloads/0.3.1-dev`;
essa pasta é excluída dos exports e do ZIP de fontes para evitar incluir cópias
dos pacotes dentro do próprio jogo.

## Jogar

No Windows, execute `TribesOfFire-0.3.1-dev-Windows-Setup.exe`, ou extraia o ZIP
Windows e abra `TribesOfFire.exe`. O instalador oferece seis idiomas, atalho na
área de trabalho marcado por padrão, menu Iniciar, execução ao terminar e
instalação por usuário, sem privilégios de administrador. A desinstalação preserva
os saves. Esta versão passou pela [validação nativa Windows](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41394174603):
instalação, documentação/atalhos, execução headless, saves/reinício, reinstalação
e desinstalação em um runner limpo do GitHub.
**Renderização e uso interativo em Windows 10/11 continuam pendentes.** Existe um roteiro automatizado em
[Tools/Test-Windows.ps1](Tools/Test-Windows.ps1) para uma conta Windows de teste.

No Linux, extraia o ZIP Linux, dê permissão de execução se necessário
(`chmod +x TribesOfFire.x86_64`) e execute `./TribesOfFire.x86_64`.
Os executáveis contêm os recursos e não precisam do editor Godot instalado.

Selecione o idioma do jogo na primeira abertura, escolha **Nova jornada local**,
crie seu personagem e confirme. A altura de 1,35–1,65 m e os ajustes de aparência
são cosméticos: não alteram colisões, alcance ou dano. O idioma do instalador é
independente do idioma do jogo. Nomes e mensagens de jogadores não são traduzidos.

| Controle padrão | Ação |
|---|---|
| WASD / mouse / roda | Movimento / câmera / zoom |
| Shift / Espaço / C / Q | Correr / pular / agachar / esquivar |
| Clique esquerdo / direito / F | Usar ou atacar / defender / ataque forte |
| E | Coletar recurso próximo, saquear animal/bolsa ou beber na fonte |
| 1 / 2 / 3 | Ferramenta equipada / posicionar fogueira / posicionar abrigo |
| Tab / Esc | Inventário e fabricação / menu |
| Enter / V | Chat / pressionar para falar, após ativar voz |
| F5 / F9 | Salvar / carregar no solo |

Dê três golpes próximos em uma árvore para receber quatro madeiras. Duas árvores
fornecem madeira para uma fogueira; três para um abrigo. Em Tab, fabrique e equipe
a construção. Uma prévia verde indica local permitido. O abrigo possui teto e
colisões reais; entre por uma lateral aberta. Fogueiras aquecem sem conceder
imunidade à chuva. Perto delas é possível cozinhar carne obtida na caça.

Recolha pedra perto do início com E, fabrique uma picareta e equipe-a pelo
inventário para minerar. Bancada e fornalha podem ser construídas pelo painel;
as receitas avançadas exigem proximidade da estação correspondente. Arraste itens
entre os 36 espaços; Shift ao arrastar divide a pilha. Equipar, comer e descartar
alteram o inventário real. Bolsas descartadas são recuperáveis com E.
A fonte potável azul está próxima ao início. Fome e sede diminuem com o tempo.
Há morte e renascimento no ponto inicial; camas e respawn selecionável faltam.

## Multiplayer e comunicação

No menu escolha **Hospedar / Conectar por IP**. Porta padrão: **24567/UDP**.
Um servidor e três clientes reais foram testados localmente. A opção administrativa
aceita até 100 jogadores; essa capacidade **não foi comprovada por teste de carga**.

    ./TribesOfFireServer.x86_64 --headless -- --server --port=24567 --save-dir=/caminho/mundo --max-players=16 --regen-delay=6

O ZIP do servidor também inclui `start-server.sh`. O relógio continua enquanto o
processo estiver ativo, mesmo sem jogadores. Dia de 30 minutos e noite de 15.
Não há descoberta pública, senha, Steamworks ou abertura automática de NAT.
O anfitrião precisa encaminhar a porta UDP no roteador para acesso pela Internet.
Use esta conexão experimental em redes de confiança: ENet não criptografa o
transporte e o token local ainda não substitui autenticação comercial.

Menu **Comunicação**: jogadores, tribos, convites, saída, expulsão, transferência
de liderança, grupos, salas diplomáticas, bloqueio e chamadas privadas aceitas.
Dano entre membros da mesma tribo é recusado. Saída ou expulsão ativa proteção
bidirecional de 300 segundos contra a antiga tribo, inclusive após reconexão.
Não há ainda territórios, alianças, guerras, cercos ou oficiais com permissões.

Enter abre chat global, local (40 m), privado, grupo, tribo ou diplomacia.
Comandos: `/global`, `/local`, `/tribo`, `/grupo`, `/msg ID mensagem`, `/ajuda`.
Histórico limitado a 200 mensagens em memória; não há gravação do chat em disco.

Voz vem **desativada em cada abertura**. Em Comunicação, escolha dispositivo,
volume e sensibilidade, ative o microfone e use V. Há ativação por voz e teste
local do microfone. Proximidade alcança 30 m; chamadas aceitas, tribos, grupos e
salas diplomáticas autorizadas permitem áudio remoto. Bloqueio e mudo individuais
são funcionais. O pipeline usa captura real Godot, IMA ADPCM a 16 kHz mono,
ENet em canal separado, decodificação e reprodução com fila limitada. Não é Opus;
eco, supressão de ruído e calibração com dispositivos físicos continuam pendentes.
Veja [Docs/COMMUNICATION.md](Docs/COMMUNICATION.md).

## Chuva e vida

Vida máxima de 100 HP. Exposição contínua: 0 dano até 40 s, primeiro dano de
1 HP aos **55 s**, depois a cada 15 s (70/85/100; 17 HP brutos aos 300 s).
Abrigo físico ou fim da chuva reinicia o contador. Intensidade não muda a taxa.
Fogueiras melhoram conforto, mas não substituem o teto.

Conforme o prompt de auditoria mais recente, a regeneração só ocorre em condição
segura: sem combate, fome/sede zeradas ou exposição nociva à chuva a partir de
40 s. Cada dano impõe espera padrão de **6 s**, seguida de **1 HP a cada 3 s**
seguros (primeiro HP aos 9 s após um golpe). `--regen-delay=0` elimina a espera
adicional; intervalo configurável de 0 a 60 s. O servidor aplica todas essas regras.

## Gráficos, som e idiomas

Médio é o padrão; Muito Baixo, Baixo, Médio, Alto, Ultra e Personalizado alteram
vegetação, distância, sombras, iluminação, água e partículas. Há escala de
renderização, antialiasing, resolução, modo de janela, VSync, FPS e painel de
medição. Mudanças de resolução exigem confirmação em 15 s antes de serem salvas.
`TribesOfFire.exe -- --safe` (ou `SafeMode.cmd`) abre com configurações
conservadoras, sem apagar os dados pessoais. No Linux use `./TribesOfFire.x86_64 -- --safe`.

Compatibility é o renderer utilizado. Reflexos são aproximações do ambiente;
SSR, GI e iluminação volumétrica não são alegados. Opções incompatíveis são
indicadas na interface. Arte, animação e música são originais em estágio inicial;
não equivalem à qualidade cinematográfica final solicitada.

Interface principal em português brasileiro, inglês, espanhol, francês, alemão
e japonês, com fonte CJK incluída. Há 233 entradas por catálogo. Revisão linguística
integral e tradução de alguns erros técnicos antigos ainda são necessárias.
Som tem controles separados para música, ambiente, efeitos, interface, vocalizações
e voz; música muda entre menu, criação, exploração, noite e combate.

## Desenvolver, testar e compilar

Abra `project.godot` no Godot **4.6.3 padrão**, sem .NET. Não há dependências pagas.
A versão desta entrega foi validada com 4.6.3; versões anteriores precisam de teste.

    bash Tools/setup.sh
    python3 Tools/build.py --test-only
    python3 Tools/test_network.py
    python3 Tools/test_multiplayer.py --keep-logs builds/logs
    python3 Tools/test_reconnect.py
    python3 Tools/test_host_migration.py
    python3 Tools/test_communication.py --keep-logs builds/logs
    python3 Tools/build.py
    python3 Tools/test_exports.py --keep-logs builds/logs
    python3 Tools/package.py

Setup verifica SHA512 do editor/templates oficiais e usa APT verificado para
NSIS local. O editor e testes ENet podem exigir sockets locais em sandboxes.
Builds ficam em `builds/`, pacotes em `dist/`. O empacotador recusa fontes ou
binários alterados após a exportação, verifica ZIPs e gera SHA256 e manifesto.
Há ZIPs Windows, Linux, servidor Linux e código-fonte, além do instalador Windows.

`Tools/setup.sh` prepara o ambiente cloud Debian usado neste projeto. Para
compilar localmente em outros sistemas, instale Godot 4.6.3, os export templates
da mesma versão, Python 3.11 ou posterior para os scripts e NSIS 3.x para o
instalador. Para jogar pelos pacotes, essas ferramentas não são necessárias.

## Dados e recuperação

Dados pessoais em `user://`: normalmente
`%APPDATA%/Godot/app_userdata/Tribes of Fire/` no Windows e
`~/.local/share/godot/app_userdata/Tribes of Fire/` no Linux.
Mundo padrão na subpasta `world`; `--save-dir=...` escolhe outra pasta.
Idioma, gráficos, controles, volumes e identidade ficam fora da instalação.
Preserve `identity.cfg` e não o compartilhe; ele permite recuperar o jogador.
Ao transferir um mundo solo/hospedado para um dedicado, salve primeiro com esta
versão usando a identidade original. O save passa a vincular o perfil do anfitrião
a esse cliente. Mundos antigos sem esse vínculo não entregam o perfil ao primeiro
cliente que se conectar.
Para dois clientes na mesma máquina Linux, use diretórios XDG_DATA_HOME distintos.

Snapshots v3 alternados com SHA256, validação e migração v1/v2. Posições,
inventários, aparência, fome/sede, chuva, animais, recursos, estruturas, tribos,
grupos e bloqueios são persistidos. Chamadas exigem novo aceite após reinício.
Salvamento manual, automático a cada 45 s e ao sair normalmente. Lock exclusivo
impede escritores concorrentes. Após crash, pare todos os processos desse mundo,
faça backup e só então remova `.writer-lock` para recuperação. Não remova um lock
ativo. Se ambos os slots estiverem corrompidos, hospedar ou carregar recusa a
operação sem substituí-los. Novas identidades são recusadas quando não há espaço
para persistência, preservando os perfis existentes. Ainda não há journal/WAL nem garantia contra perda por queda de energia.

Logs técnicos de inicialização e salvamento em `user://logs/`; não gravam conversas,
áudio ou tokens. Arquitetura em [ARCHITECTURE.md](ARCHITECTURE.md), critérios e
pendências em [Docs/AUDIT.md](Docs/AUDIT.md), roteiro manual em
[Tests/MANUAL.md](Tests/MANUAL.md).

## Verificação automática em Windows

O workflow [Windows installer and runtime](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/workflows/windows-qa.yml)
usa um runner Windows limpo para conferir o SHA256, instalar o pacote, verificar
atalhos, iniciar o jogo sem interface gráfica, validar snapshots e reiniciar o
servidor, reinstalar a mesma versão e desinstalar preservando dados. Os relatórios
JSON/CSV e logs são publicados como artefato da execução. Consulte o resultado
real em Actions; a existência do workflow não significa que ele passou.

O modo headless não valida renderização, áudio físico, instalação interativa,
Windows 10/11 em máquinas de jogadores ou desempenho. Esses testes continuam no
roteiro manual. Para validar graficamente em uma conta Windows de teste, execute
Tools/Test-Windows.ps1 sem a opção -Headless.

Evidência anterior, referente à **0.3.0-dev**: [primeira execução Windows aprovada](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41380465249).
Esse resultado corresponde ao teste headless descrito acima, com os pacotes
publicados; não certifica renderização nem o conjunto completo da versão 1.0.

## Correções da 0.3.1-dev

A revisão corrigiu movimento após morte, perda/reparo indevido de durabilidade ao
descartar e recuperar equipamento, coleta através de paredes, cozimento com
inventário cheio, preferências inválidas que impediam abrir o jogo, teclas
consumidas pela interface, lacuna no LOD e encerramento durante carregamento.
Também protege saves corrompidos, limita históricos de tribos/perfis, mantém o
relógio e a exposição à chuva em tempo real mesmo sob poucos FPS e melhora o
escoamento da fila de voz.

Foram executadas **372 verificações** de regras, integração, regressão e processos,
além de seis verificações dos binários Linux e cenários reais de rede, reconexão e
migração solo → dedicado. A comunicação passou nas duas repetições finais; uma
execução concorrente anterior falhou por entregas de áudio ausentes. Isso permanece
registrado como limite da validação sob carga, sem prometer transporte de voz livre
de perdas. Detalhes e limites em [Docs/TEST_REPORT.md](Docs/TEST_REPORT.md).

A [validação Windows da 0.3.1-dev](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41394174603) foi aprovada.
[Logs e resultados da auditoria](https://github.com/teyranto7-cloud/Tribes-Of-Fire/tree/main/Docs/verification/0.3.1-dev)
estão no repositório, incluindo a ocorrência anterior de comunicação que falhou.

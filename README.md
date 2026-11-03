# Tribes of Fire

Criado por **felipealx** · código em desenvolvimento **0.5.0-dev** · Godot 4.6.3 · Windows/Linux x64

Jogo de sobrevivência 3D em terceira pessoa, com modo solo, hospedagem por jogador
e servidor dedicado autoritativo. A reconstrução continua a base existente; não é
uma versão 1.0 concluída. Funcionalidades, resultados observados e critérios ainda
pendentes estão em [PROGRESS.md](PROGRESS.md) e [Docs/PENDENCIAS.md](Docs/PENDENCIAS.md).

## Versões e downloads

**0.5.0-dev — sobrevivência em desenvolvimento.** Instalador Windows, ZIPs de jogo
Windows/Linux, servidor Linux e fontes são gerados a partir dos testes e recibo
congelado. O editor não é necessário para executar o jogo exportado.

[Prévia publicada 0.5.0-dev](https://github.com/teyranto7-cloud/Tribes-Of-Fire/releases/tag/v0.5.0-dev)
com downloads fixados no commit da entrega.

- [Instalador Windows](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.5.0-dev/TribesOfFire-0.5.0-dev-Windows-Setup.exe)
- [ZIP Windows](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.5.0-dev/TribesOfFire-0.5.0-dev-Windows.zip)
- [ZIP Linux](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.5.0-dev/TribesOfFire-0.5.0-dev-Linux.zip)
- [Servidor Linux](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.5.0-dev/TribesOfFire-0.5.0-dev-Server-Linux.zip)
- [Código-fonte ZIP](https://github.com/teyranto7-cloud/Tribes-Of-Fire/raw/refs/heads/main/Downloads/0.5.0-dev/TribesOfFire-0.5.0-dev-Source.zip)
- [SHA256 dos pacotes](Downloads/0.5.0-dev/SHA256SUMS.txt)

Guia de coleta, fabricação, medicina, máquinas, jangada, escavação e tribos:
[Como jogar](Docs/PLAYABILITY.md). Resultados atuais em [PROGRESS.md](PROGRESS.md).
Os downloads 0.4 anteriores permanecem preservados; não representam a nova revisão.

## Executar o código-fonte

Instale **Godot 4.6.3 padrão**, sem .NET. Não há dependências pagas obrigatórias.
Clone o repositório e importe `project.godot`; pressione F5:

```sh
git clone https://github.com/teyranto7-cloud/Tribes-Of-Fire.git
cd Tribes-Of-Fire
godot --path .
```

O checkout contém código, assets, testes e instruções de build. A pasta
`Downloads/0.5.0-dev` contém os pacotes preparados desta revisão.

Escolha o idioma, uma nova jornada, a seed e o personagem. Mundos novos usam um
terreno de **1536 × 1536 m** com geração determinística; saves anteriores preservam
seu gerador de 128 × 128 m ou 320 × 320 m. Não é o continente final de 12 km solicitado.

Controles podem ser remapeados em Configurações; Ajuda mostra os comandos.

| Padrão | Ação |
|---|---|
| WASD / mouse / roda | Mover / câmera / zoom |
| Shift / Espaço / C / Q | Correr / pular / agachar / esquivar |
| Clique esquerdo / direito / F | Usar ou atacar / defender / ataque forte |
| E | Interagir com recurso, material no chão, animal, água ou estrutura |
| 1 / 2 / 3 | Ferramenta / fogueira / abrigo |
| Tab / Esc / M | Inventário / menu / mapa |
| R / F4 | Girar construção / alternar visão |
| Enter / V | Chat / pressionar para falar, depois de ativar a voz |
| F5 / F9 | Salvar / carregar no modo solo |

A coleta agora leva tempo: dê três golpes próximos em uma árvore e recolha os
materiais que caírem. Fabricar reserva os recursos numa fila; cancelar devolve o
custo quando há espaço. Use o inventário para equipar ferramentas e construir.
Tecnologia e fabricação contém pesquisa, reabastecimento de fogueira, pesca com
lança e cultivo de bagas próximo a um canteiro. Esses sistemas são versões mínimas
funcionais, não a progressão completa proposta no relatório de conteúdo.

## Novidades 0.5

Faces invertidas corrigidas, abas/busca/fila de craft, fontes de recursos e
medicamentos, mapa de 1536 m com rio e 96 animais, jangada conduzível, pá/escavação,
serraria/tear/britador e diplomacia/guerra. Dia/noite permanecem ativos.
São versões funcionais iniciais; consulte o guia e as limitações antes de jogar.

## Sistemas atuais

- Terreno por seed, carregamento de chunks, árvores com IDs estáveis e rebrota,
  biomas iniciais, litoral, rio/lago, caverna e ruína simples.
- Personagem e vegetação com novas malhas originais, animação procedural, câmera
  com colisão, corrida, agachamento, esquiva e equipamentos.
- Inventário de 36 espaços, ferramentas e durabilidade, mineração, ações de coleta,
  materiais físicos, filas/cancelamento/reparo e receitas junto a estações.
- Peças modulares de madeira, portas físicas, telhados, cama vinculável, baús de
  materiais e canteiros. Integridade estrutural e materiais avançados são parciais.
- Fome, sede, combate, caça, consumo/cozimento, pesca com população persistida,
  cultivo de bagas, domesticação básica, XP e pesquisa pessoal/tribal.
- Sol/lua, dia/noite, transições climáticas, chuva, vento, relâmpagos/trovões,
  cobertura física, combustível e calor das fogueiras.
- Mapa com exploração e marcadores, ajuda, opções gráficas persistidas num único
  `settings.cfg` e seis perfis com aplicação imediata.
- ENet autoritativo, conexão por IP/senha, versão de protocolo, snapshots privados
  por jogador e deltas, configuração de servidor e moderação por identidade.
- Tribos, convites/liderança e proteção bilateral de 300 s após saída/expulsão;
  chat e voz opt-in herdados da versão anterior.

A suíte completa da 0.5 passou **564 verificações, sem falhas**. Os executáveis
Linux passaram seis verificações de abertura/persistência/reinício. Servidor ENet
com dois clientes passou movimento e coleta compartilhada. A inspeção gráfica
usou Mesa llvmpipe, sem certificar GPU física ou arte final. Consulte
[o relatório atual](Docs/PLAYABILITY_REPORT.md) para evidências e limites;
[a auditoria anterior](Docs/RECONSTRUCTION_TEST_REPORT.md) documenta a 0.4.

## Multiplayer, servidor e comunicação

Escolha **Hospedar / Conectar por IP**. Porta padrão: **24567/UDP**. Para um
servidor dedicado a partir do código-fonte:

```sh
godot --headless --path . -- --server --port=24567 --max-players=16 --save-dir=/caminho/mundo
```

As opções de `Networking/server.example.json` podem ser copiadas para um arquivo
privado e usadas com `--server-config=/caminho/server.json`. Não publique senhas,
identidades, moderação ou saves. Um servidor existente mantém as regras salvas
quando não são explicitamente substituídas pela configuração administrativa.
Relógio padrão: dia de 30 minutos e noite de 15; avança enquanto o processo roda.
Algumas regras ainda são parciais: a taxa de recursos afeta madeira; dificuldades
normal e difícil ainda não possuem diferenciação completa.

Senha e limite configurável não equivalem a autenticação comercial ou a suporte
comprovado para 100 jogadores. ENet não criptografa o transporte; use redes de
confiança nesta fase. Descoberta pública, Steamworks, predição avançada e abertura
automática de NAT continuam pendentes. Para acesso externo, encaminhe a porta UDP.

Chat: global, local, privado, grupo, tribo e diplomacia. Voz vem desativada em cada
abertura; usa captura Godot, IMA ADPCM e reprodução espacial/autorizada. Opus,
tratamento de eco e testes com microfones físicos não foram concluídos. Veja
[Docs/COMMUNICATION.md](Docs/COMMUNICATION.md). Cenários locais de rede foram repetidos na 0.4.0-dev. A voz foi testada com áudio
sintético, sem ativar microfone físico; isso não certifica estabilidade sob carga.

## Vida, chuva e abrigo

Vida máxima: 100 HP. Sem abrigo nem aquecimento válido, a chuva não causa dano nos
primeiros 40 s; primeiro dano de 1 HP aos **55 s**, depois a cada 15 s. Cobertura
física ou fim da chuva reinicia a exposição. Intensidade não muda a taxa.

A reconstrução permite que calor válido interrompa a perda por frio sem reiniciar
esse contador; ao sair do calor, a exposição continua. Uma fogueira exposta pode
ser apagada pela chuva e precisa de combustível. Isso não cria um teto visual.
Proteção climática por roupas ainda está pendente.

Conforme os pedidos posteriores de auditoria, regeneração exige condição segura.
Dano impõe espera padrão de 6 s, seguida de 1 HP a cada 3 s seguros. O servidor
pode usar `--regen-delay=0` para eliminar a espera adicional. Fome/sede esgotadas,
combate e exposição nociva suspendem regeneração. Consulte o diagnóstico e testes
para a precedência dessas regras sobre os prompts antigos.

## Gráficos, idiomas e dados pessoais

Muito Baixo, Baixo, Médio, Alto, Ultra e Personalizado alteram vegetação, distância,
sombras, água e partículas. Mudar preset salva imediatamente; somente alterações
de resolução/modo de janela usam confirmação de 15 s. Há sensibilidade, FOV,
inversão vertical, escala da interface e opções iniciais de acessibilidade.
`godot --path . -- --safe` abre com preferências conservadoras.

O renderer é Compatibility. Reflexos são aproximações do ambiente; SSR, GI e
volumetria não são alegados. Nenhuma meta de 60 FPS foi validada no hardware alvo.
Há seis catálogos de idioma e fonte japonesa. Traduções novas e revisão linguística
integral ainda precisam ser concluídas. Arte/animação também não são finais.

Dados ficam em `user://`: normalmente `%APPDATA%/Godot/app_userdata/Tribes of Fire/`
ou `~/.local/share/godot/app_userdata/Tribes of Fire/`. Preferências e identidade
ficam fora da instalação. Preserve `identity.cfg` para recuperar o jogador; não o
compartilhe. Para vários clientes na mesma máquina, use perfis XDG separados.

Saves v4 preservam descritor do mundo, jogadores, itens, estruturas e módulos
integrados, com migrações v1/v2/v3. Dois snapshots alternados possuem SHA256,
validação, temporário verificado e lock exclusivo. Salvamento manual, automático
a cada 45 s e ao sair normalmente. Não há WAL/fsync com garantia contra queda de
energia. Após crash, pare os processos, faça backup e só então remova um lock
obsoleto; nunca remova lock ativo. Dois slots corrompidos são recusados, preservados.

## Testar e gerar instalador/ZIPs

Requer Python 3.11+, Godot 4.6.3 e templates oficiais da mesma versão. NSIS 3.x é
necessário para o instalador Windows. O script de setup prepara o ambiente cloud
Debian; em outros sistemas instale essas ferramentas normalmente.

```sh
bash Tools/setup.sh
python3 Tools/build.py --test-only
python3 Tools/test_settings_lifecycle.py --godot godot
python3 Tools/test_network.py
python3 Tools/test_multiplayer.py --keep-logs builds/logs
python3 Tools/test_reconnect.py
python3 Tools/test_host_migration.py
python3 Tools/test_communication.py --keep-logs builds/logs
python3 Tools/build.py
python3 Tools/test_exports.py --keep-logs builds/logs
python3 Tools/package.py
```

Os testes de presets aguardam 120 s reais por perfil e reiniciam os processos.
A verificação adicional de 50 aberturas usa `python3 Tools/test_startup_stability.py`.
Builds ficam em `builds/`, pacotes em `dist/`; o empacotador exige recibo de fontes
e binários, verifica ZIPs e gera hashes. Produz instalador NSIS por usuário e ZIPs
Windows, Linux, servidor e fontes. As três exportações 0.5.0-dev foram geradas e
os executáveis Linux foram testados. A geração de ZIPs/NSIS não equivale à aprovação
de instalação nativa. O workflow Windows valida a versão presente em Downloads;
o [QA nativo 0.5 passou](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41560599160):
instalação, atalhos, abertura headless, saves/restauração, reinstalação e
desinstalação, além de checksums/documentação de todos os pacotes.
Renderização interativa Windows e dispositivos físicos continuam pendentes.

Arquitetura em [ARCHITECTURE.md](ARCHITECTURE.md), diagnóstico anterior às mudanças
em [Docs/RECONSTRUCTION_DIAGNOSIS.md](Docs/RECONSTRUCTION_DIAGNOSIS.md), histórico
0.3.1 em [Docs/verification/0.3.1-dev](Docs/verification/0.3.1-dev).

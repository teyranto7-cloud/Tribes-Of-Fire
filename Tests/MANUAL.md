# Validação manual — 0.3.1-dev

Importação, regras, física automatizada, processo real de rede, captura/reprodução
sintética e inspeção de sete telas renderizadas foram executados no Linux. Isso
não substitui jogar com pessoas nem testar dispositivos físicos. Resultados e
limitações ficam em PROGRESS.md; marque abaixo somente após executar.

## Jogo e apresentação

- [ ] Primeiro idioma em seis línguas, troca imediata, reinício e acentos/japonês.
- [ ] Criar aparência, todos os parâmetros, rotação/zoom, nome, save e reconexão.
- [ ] WASD, câmera perto de obstáculos, corrida/pulo, agachamento sob teto, esquiva.
- [ ] Remapear teclas, sensibilidade/suavização, persistência e conflitos de atalhos.
- [ ] Três golpes por árvore, concessão única, inventário cheio sem perder recurso.
- [ ] Pilhas/divisão/arrastar, equipar, durabilidade, descarte e recuperação.
- [ ] Colher alimentos, beber na fonte, caçar, cozinhar e comer, morrer/renascer.
- [ ] Minerar, construir bancada/fornalha e fabricar equipamentos com custos reais.
- [ ] Prévia/colisões/consumo de fogueira e abrigo, espaço inclinado/obstruído/água.
- [ ] Mudanças de qualidade visíveis, confirmar resolução, esperar rollback de 15 s,
      cancelar e verificar que resolução não confirmada não persiste.
- [ ] Ouvir músicas de menu/criação/exploração/noite/combate e buses independentes.
- [ ] Conferir dia/noite/tempestade, materiais, chuva sem atravessar teto e conforto.

## Regras longas e rede

- [ ] Cronometrar chuva 0/20/39/40/55/70/85/100/300 s: dano bruto 0/0/0/0/1/2/3/4/17.
- [ ] Entrar/sair do teto e cessar chuva reiniciam; calor não concede imunidade.
- [ ] Após dano esperar 6 s; primeiro HP após mais 3 s em segurança; sem HP sob
      chuva nociva/combate/fome/sede zeradas. Não regenerar depois de morrer.
- [ ] Animais comuns 5–10 HP e especial de urso no máximo 20 HP, com aviso legível.
- [ ] Dois computadores veem movimento/coleta/construções/clima compartilhados.
- [ ] Tribo bloqueia dano; saída e expulsão impedem dano bilateral durante 300 s,
      inclusive reconectando/mudando de tribo; terceiro jogador não é protegido.
- [ ] Transferência de líder, convites, grupos e chamadas só para destinatários.
- [ ] Voz com microfones físicos conforme Docs/COMMUNICATION.md, todas as salas.
- [ ] Reinício recupera aparência, inventários, fome/sede, estruturas, recursos,
      animais, tribos, bloqueios e proteção ainda ativa.
- [ ] Corrupção só em cópia de save; verificar fallback e erro de escrita.
- [ ] SIGKILL e lock concorrente com cópia de mundo; recuperação só com todos os
      processos desse mundo parados. Não remover lock de servidor ativo.

## Windows e distribuição

- [ ] Executar Tools/Test-Windows.ps1 em VM/conta limpa do Windows 10 x64.
- [ ] Repetir em Windows 11 x64. Nunca usar conta com instalação/dados existentes.
- [ ] Instalar nos seis idiomas; caixa de atalho marcada; testar desmarcada.
- [ ] Iniciar pelo atalho sem argumentos e pela opção final do instalador.
- [ ] Conferir ícone, diretório de trabalho, nome com acentos e pasta com espaços.
- [ ] Atualizar preservando saves/configurações; desinstalar preservando dados.
- [ ] Executar ZIP em máquina sem Godot e sem toolchain.
- [ ] Medir Ryzen 4600G/16 GB/1080p e GPU dedicada: FPS, p95/p99, CPU/GPU, memória,
      noite/chuva/base e multiplayer; não usar resultado llvmpipe como referência.
- [ ] Testes de carga, latência/perda e segurança antes de servidores públicos.

## Regressões adicionais da 0.3.1

Os casos automatizados de morte, desgaste, oclusão, cozinha cheia, remapeamento,
LOD, configurações malformadas, shutdown, locks, corrupção, tribos e migração estão
em test_*regressions.gd, test_tribes_regression.gd, test_reliability.gd,
test_startup_close.gd, test_startup_processes.py e Tools/test_host_migration.py.
Ainda conferir interativamente em uma cópia dos dados:

- [ ] Remapear setas, jogar, reiniciar e restaurar padrões.
- [ ] Descartar machado gasto, reiniciar e recuperar preservando desgaste.
- [ ] Morrer durante esquiva/defesa; renascer e recuperar controles normais.
- [ ] Fechar chat com inventário/menus abertos sem recuperar movimento indevido.
- [ ] Abrir novo mundo após participar de grupos e confirmar estado vazio.
- [ ] Derrubar conexão e voltar ao menu; iniciar solo e conectar novamente.
- [ ] Migrar cópia de mundo hospedado para dedicado usando a identidade original.
- [ ] Conferir voz sob carga, latência/perda e FPS baixos com dispositivos físicos.
- [ ] Confirmar documentos/links em cada ZIP extraído e na instalação Windows.

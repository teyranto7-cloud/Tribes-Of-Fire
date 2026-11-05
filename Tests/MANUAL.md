# Continuidade 0.10 — validação humana pendente

1. B → Gerenciar base: esvaziar uma serraria, cancelar filas, remover esteiras/cabos.
2. Retirar motor e confirmar; conferir um motor devolvido e botão atualizado.
3. Cancelar demolição; conferir bancada e materiais. Confirmar; conferir 50% do custo registrado.
4. Criar outra bancada: outras máquinas, fios e destinos não devem mudar de ID.
5. E em poste/lâmpada/roda: remover cabos, testar prévia de recolocação e Esc; confirmar em local válido.
6. Em dois PCs, repetir com servidor: proprietário/líder autorizado e estranho recusado.
7. PvP off protege peças. War exige guerra; aliados, ex-membros e tréguas permanecem protegidos.
8. Atacar parede inimiga; reparar; destruir suporte em modo estrito e verificar suporte alternativo.
9. Destruir suporte de baú cheio; conferir loot no chão, desgaste, save/reload, coleta sem duplicação.
10. Conferir fragmentos no cenário e desaparecimento em três segundos; medir hardware físico.
11. Tentar destruir suporte industrial: proteção de 1 HP permanece até remover os aparelhos.
12. Executar o instalador/ZIP, atualizar 0.9→0.10 e verificar perfil/mundo preservados.

Automação e capturas reais: Docs/LIFECYCLE_0.10.md. Isso não substitui estes playtests humanos.

# Fase 4 — validação manual adicional

1. Abrir B em Windows/Godot 4.6.3; filtrar peças e materiais, salvar favoritos.
2. Construir fundações, duas metades triangulares, paredes, marco/folha de porta e telhado.
3. Alternar R, PgUp/PgDn, G, T e H em peças compatíveis; observar motivo da prévia vermelha.
4. Ativar suporte estrutural: telhado sem paredes/colunas deve ser recusado.
5. Tentar construir/mover atravessando personagem, terreno, árvore e peça de outro jogador.
6. Abrir portas por ambos os lados; tentar fechar enquanto outro jogador ocupa o vão.
7. Guardar itens no baú: mover/demolir deve falhar; retirar tudo e recolocar sem gerar kit.
8. Reparar peça danificada, aprimorar material, renomear, pintar, controlar aliado/fechadura.
9. Abrir confirmação de demolição; outro jogador altera dependente: confirmar deve ser recusado.
10. Esvaziar mochila/baú; confirmar cascata pequena e conferir restituição uma única vez.
11. Esvaziar/desconectar bancada e cancelar filas; mover e conferir produção/posição após reinício.
12. Caminhar por escada e rampa sem pular. Verificar câmera, aterrissagem e piso superior.
13. Plantar, afastar-se para descarregar o chunk e voltar: cultura/tempo/umidade devem persistir.
14. Medir CPU/GPU/FPS/memória em hardware real e conferir UI em 720p/1080p/janela reduzida.

Estes passos humanos continuam pendentes onde não houver resultado específico;
[relatório e testes automatizados](../Docs/BUILDING_PHASE4.md).

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

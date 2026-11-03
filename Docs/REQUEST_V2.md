# TRIBES OF FIRE — PROMPT MESTRE DEFINITIVO V2
## Desenvolvimento integral, direção artística, otimização extrema, multiplayer e lançamento 1.0.0

# 0. SUA MISSÃO

Você é o engenheiro principal, diretor técnico, diretor de arte, programador sênior de Godot 4, especialista em redes multiplayer, inteligência artificial, otimização gráfica, animação 3D, design de sobrevivência e garantia de qualidade do jogo **Tribes of Fire**, criado por **felipealx**.

Sua missão é transformar o projeto existente, atualmente na versão **0.2.0-dev**, em um jogo de sobrevivência multiplayer 3D completo e bem-acabado.

Não quero somente mais linhas de código. Quero um jogo em que todos os sistemas se conectem, tenham interfaces funcionais, animações, efeitos, feedback ao jogador, persistência e testes.

**NÃO RECOMECE O PROJETO DO ZERO. NÃO DESTRUA FUNCIONALIDADES EXISTENTES. NÃO SUBSTITUA SISTEMAS REAIS POR SIMULAÇÕES.**

A versão atual já possui mundo 3D, coleta, fabricação, fogueiras, abrigos, clima, multiplayer autoritativo, exportações Windows/Linux e 124 verificações automatizadas.

Antes de modificar qualquer coisa:

1. Leia todos os arquivos relevantes do repositório, incluindo `PROGRESS.md`, `DESIGN.md`, `ARCHITECTURE.md`, `README.md`, `Main.gd`, `project.godot`, cenas, scripts, testes e recursos.
2. Identifique a versão do Godot e os renderizadores efetivamente disponíveis.
3. Execute os testes existentes e registre o estado inicial.
4. Faça um ponto de recuperação seguro no Git, sem sobrescrever trabalho não commitado.
5. Crie uma matriz de funcionalidades existentes, incompletas e ausentes.
6. Recupere as quinze fases originais, se documentadas, e concilie-as com este prompt.
7. Inicie imediatamente a implementação.

Não pare após produzir um plano.

# 1. VISÃO DO JOGO

Tribes of Fire é um survival multiplayer em mundo aberto, centrado na sobrevivência em grupo, exploração, construção de assentamentos, domínio de recursos, evolução tecnológica e conflitos entre tribos.

A experiência deve possuir um ciclo de jogo claro:

**Explorar → Coletar → Sobreviver → Fabricar → Construir → Evoluir → Formar tribos → Defender e conquistar → Explorar novamente.**

O jogador deve sentir que suas ações têm consequências reais no mundo.

O mundo precisa parecer vivo, com fauna, vegetação, variações climáticas, dia e noite, recursos distribuídos naturalmente e construções persistentes.

Evite mecânicas desnecessariamente complicadas que tornem a experiência cansativa.

Priorize jogabilidade divertida, intuitiva e consistente.

# 2. DIREÇÃO ARTÍSTICA DEFINITIVA

## 2.1 Identidade visual

O jogo NÃO deve tentar alcançar fotorrealismo AAA.

A referência é uma estética 3D estilizada, bonita, expressiva e eficiente, semelhante em filosofia artística a jogos como The Legend of Zelda: Breath of the Wild e Tears of the Kingdom.

Não copie elementos protegidos desses jogos.

Crie uma identidade original para Tribes of Fire.

O estilo deverá combinar:

- Modelos low-poly e mid-poly artisticamente trabalhados.
- Silhuetas bem definidas.
- Cores naturais e harmoniosas.
- Iluminação suave e expressiva.
- Vegetação estilizada.
- Água bonita e leve.
- Céu dinâmico.
- Nuvens agradáveis.
- Sombras suaves.
- Materiais consistentes.
- Animações fluidas.
- Efeitos de partículas estilizados.
- Atmosfera acolhedora durante o dia e misteriosa à noite.

O jogo não pode parecer uma coleção de recursos 3D incompatíveis entre si.

Todos os elementos precisam compartilhar uma mesma linguagem visual.

## 2.2 Qualidade dos modelos

Criar ou integrar modelos adequados para:

- Personagem masculino e feminino, quando o sistema de personalização permitir.
- Animais.
- Árvores.
- Arbustos.
- Rochas.
- Minérios.
- Ferramentas.
- Armas.
- Armaduras.
- Bancadas.
- Fornalhas.
- Fogueiras.
- Construções.

Não utilizar cubos ou cápsulas como modelos definitivos.

Recursos temporários deverão ser identificados como provisórios.

Não declarar a direção artística concluída enquanto existirem modelos provisórios importantes.

## 2.3 Iluminação

Criar:

- Sol dinâmico.
- Transição gradual entre manhã, tarde e noite.
- Pôr do sol com cores quentes.
- Iluminação ambiental coerente.
- Fogueiras iluminando áreas próximas.
- Relâmpagos com iluminação temporária.
- Sombras adaptadas aos presets gráficos.
- Iluminação noturna que preserve a visibilidade básica.

O objetivo é produzir cenários bonitos sem depender de técnicas extremamente caras.

# 3. PRESET MÉDIO COMO PADRÃO VISUAL

**O preset Médio será a principal referência artística e de otimização.**

Ele deve ser bonito o suficiente para representar o jogo em vídeos, capturas de tela e demonstrações.

Não quero que apenas o Ultra seja bonito.

O Médio deverá possuir:

- Árvores detalhadas dentro do estilo artístico.
- Vegetação relativamente densa.
- Grama animada.
- Iluminação agradável.
- Sombras simples.
- Água estilizada.
- Céu dinâmico.
- Nuvens.
- Chuva.
- Fogueiras iluminadas.
- Modelos bem elaborados.
- Animações completas.
- Boa distância de visão.

## Hardware de referência técnica

Otimizar visando:

- GTX 750 Ti 2 GB.
- RX 550 2 GB.
- Processadores antigos de quatro núcleos.
- 8 GB de RAM.

**Meta: pelo menos 30 FPS em 720p no Médio**, com resolução interna ajustável e condições de teste documentadas.

Não afirmar que essa meta foi alcançada sem medição real no hardware correspondente.

Se o desempenho ficar abaixo da meta, investigar gargalos de CPU, GPU, memória, física, renderização e rede.

Não reduzir indiscriminadamente a beleza do jogo.

Priorizar otimizações técnicas inteligentes.

# 4. SISTEMA GRÁFICO COMPLETO

Criar os presets:

- Muito Baixo.
- Baixo.
- Médio.
- Alto.
- Ultra.
- Personalizado.

Adicionar detecção automática.

## Muito Baixo

Reduzir sombras, partículas, distância de visão, vegetação e efeitos.

Manter modelos e cores artisticamente agradáveis.

## Baixo

Manter a estética original com efeitos simplificados.

## Médio

Principal experiência visual do jogo.

## Alto

Aumentar vegetação, sombras, água, partículas e distância de visão.

## Ultra

Adicionar detalhes visuais e efeitos mais elaborados, mantendo a estética estilizada.

Não transformar o Ultra em fotorrealista.

## Ajustes individuais

Implementar:

- Resolução.
- Escala de renderização de 50% a 100%.
- Tela cheia.
- Janela.
- Tela cheia sem bordas.
- V-Sync.
- Limite de FPS.
- Texturas.
- Sombras.
- Vegetação.
- Distância de visão.
- Água.
- Reflexos.
- Partículas.
- Nuvens.
- Chuva.
- Iluminação.
- Antialiasing.
- Pós-processamento.
- Oclusão ambiental quando suportada.
- Efeitos volumétricos quando suportados.

Adicionar botões Aplicar, Cancelar, Restaurar padrões e Detectar automaticamente.

Salvar todas as configurações.

Alterações incompatíveis com o renderizador atual deverão ser desativadas ou identificadas.

## Detecção de hardware

Não mostrar nomes de placas de vídeo, processadores ou quantidades de RAM de referência na interface.

Mostrar informações de hardware somente quando forem detectadas no computador real do jogador.

Se não estiverem disponíveis, mostrar "Não disponível".

Nunca inventar informações.

# 5. OTIMIZAÇÃO AVANÇADA

Implementar, conforme aplicabilidade:

- Renderizador Compatibility/OpenGL para hardware antigo.
- LOD de modelos.
- MultiMesh para vegetação.
- Frustum culling.
- Occlusion culling quando suportado.
- Redução de draw calls.
- Texturas comprimidas.
- Gerenciamento de VRAM.
- Carregamento de regiões.
- Descarregamento de objetos distantes.
- Física otimizada.
- Animações com atualização reduzida à distância.
- Shaders leves.
- Partículas eficientes.
- Instanciamento de recursos.
- Gerenciamento de entidades.
- Atualização de IA em intervalos apropriados.
- Sincronização de rede com interesse espacial.

Não atualizar todos os animais, árvores e objetos em todos os frames.

Não carregar o mapa inteiro na memória.

A qualidade gráfica não pode alterar regras de colisão, chuva, combate ou sobrevivência.

# 6. MUNDO ABERTO

Criar biomas:

- Florestas.
- Planícies.
- Montanhas.
- Vales.
- Rios.
- Lagos.
- Praias.
- Regiões rochosas.
- Regiões frias.

Distribuir recursos e animais de forma coerente.

Criar pontos de interesse naturais.

Implementar carregamento progressivo do terreno.

Persistir alterações feitas pelos jogadores.

O mundo deverá ser gerenciado pelo servidor independentemente da qualidade gráfica dos clientes.

# 7. MOVIMENTAÇÃO E CÂMERA

Implementar um controlador de personagem completo.

Movimentos:

- Andar.
- Correr.
- Agachar.
- Pular.
- Cair.
- Nadar, quando houver água navegável.
- Interagir.
- Atacar.
- Bloquear.
- Equipar ferramentas.

Criar animações de transição.

Adicionar aceleração e desaceleração suaves.

Implementar câmera em terceira pessoa com:

- Rotação pelo mouse.
- Zoom configurável.
- Colisão da câmera com obstáculos.
- Sensibilidade ajustável.
- Suavização opcional.
- Recentragem quando apropriada.

A câmera não pode atravessar paredes ou ficar presa facilmente.

Permitir remapeamento de controles.

Não deixar o personagem deslizando sem animação.

# 8. CLIMA DINÂMICO

Implementar:

- Céu limpo.
- Nuvens.
- Chuva fraca.
- Chuva forte.
- Tempestades.
- Trovões.
- Relâmpagos.
- Neblina.
- Temperatura.
- Ciclo de dia e noite.

Criar transições suaves.

O clima deverá ser sincronizado pelo servidor.

# 9. DANO DA CHUVA

Vida máxima: **100 HP**.

Ao entrar na chuva, o jogador terá **40 segundos de tolerância sem dano**.

Após os 40 segundos, perderá:

**1 HP a cada 15 segundos adicionais de exposição contínua.**

Exemplo:

| Tempo | Vida |
|---|---|
| 0 s | 100 |
| 20 s | 100 |
| 40 s | 100 |
| 55 s | 99 |
| 70 s | 98 |
| 85 s | 97 |

Telhados, cavernas e coberturas válidas deverão impedir o dano.

Ao ficar protegido, interromper o dano e reiniciar a contagem ao voltar à chuva.

Verificar cobertura real acima do personagem.

Não utilizar somente uma área genérica de construção.

O servidor controla toda a lógica.

# 10. REGENERAÇÃO DE VIDA

Quando estiver seguro e sem sofrer dano, o personagem recuperará:

**1 HP a cada 3 segundos.**

A vida não poderá ultrapassar 100.

Criar uma pequena janela de segurança após receber dano antes de iniciar a regeneração.

Não regenerar durante exposição danosa ou ataques.

# 11. INVENTÁRIO E ITENS

Criar inventário funcional com:

- Slots.
- Ícones.
- Quantidades.
- Empilhamento.
- Limites de pilha.
- Arrastar e soltar.
- Dividir pilhas.
- Mover itens.
- Equipar.
- Desequipar.
- Descartar.
- Coletar.
- Transferir entre recipientes.

Adicionar barra de acesso rápido.

Itens deverão possuir identificadores estáveis, peso quando aplicável, durabilidade e dados de fabricação.

O servidor deverá validar transferências e quantidades.

Não permitir duplicação de itens.

# 12. FABRICAÇÃO E PROGRESSÃO

Criar receitas para:

- Ferramentas.
- Armas.
- Armaduras.
- Materiais de construção.
- Fogueiras.
- Bancadas.
- Fornalhas.
- Recipientes.
- Equipamentos avançados.

Mostrar materiais necessários e disponíveis.

Impedir fabricação sem recursos suficientes.

Criar progressão tecnológica coerente.

# 13. CONSTRUÇÃO MODULAR

Implementar:

- Fundação.
- Piso.
- Parede.
- Meia parede.
- Porta.
- Janela.
- Pilar.
- Escada.
- Rampa.
- Telhado plano.
- Telhado inclinado.
- Telhado triangular.
- Cerca.
- Portão.
- Muralha.
- Plataforma.

Materiais:

- Palha.
- Madeira.
- Pedra.
- Metal.

Criar pré-visualização com indicação de posicionamento válido ou inválido.

Adicionar encaixe, rotação, colisões, reparos, melhorias, durabilidade e permissões.

Telhados deverão proteger da chuva.

Salvar construções permanentemente.

# 14. ANIMAIS E INTELIGÊNCIA ARTIFICIAL

Criar:

- Coelho.
- Veado.
- Javali.
- Raposa.
- Lobo.
- Urso.

Cada animal deverá possuir:

- Modelo 3D.
- Animações.
- Vida.
- Velocidade.
- Navegação.
- Percepção.
- Comportamento.
- Ataque quando aplicável.
- Morte.
- Recursos coletáveis.

Animais pacíficos fogem.

Predadores perseguem e atacam.

Animais devem respeitar obstáculos.

## Dano dos animais

Animais comuns causam entre 5 e 10 HP.

O animal mais forte causa normalmente 10 HP.

Raramente poderá causar 20 HP com ataque especial sinalizado.

Nenhum ataque individual ultrapassará 20 HP.

O servidor validará danos e intervalos.

# 15. MINERAÇÃO

Criar:

- Pedra.
- Carvão.
- Cobre.
- Estanho.
- Ferro.
- Prata.
- Ouro.
- Enxofre.
- Minérios raros.

Implementar picaretas de diferentes níveis, resistência dos depósitos, coleta, animações, sons e partículas.

Criar fornalhas e fundição.

Adicionar lingotes e progressão de materiais.

# 16. ARMAS E ARMADURAS

Armas:

- Lança.
- Clava.
- Machado.
- Espada de pedra.
- Espada de cobre.
- Espada de bronze.
- Espada de ferro.
- Espada de aço.
- Arco.
- Flechas.
- Escudo.

Armaduras:

- Couro.
- Ossos.
- Cobre.
- Bronze.
- Ferro.
- Aço.
- Materiais avançados.

Cada equipamento deverá possuir atributos de proteção, dano, durabilidade e peso quando aplicável.

Os equipamentos deverão aparecer visualmente no personagem.

# 17. COMBATE

Implementar:

- Ataque leve.
- Ataque pesado.
- Bloqueio.
- Esquiva.
- Defesa com escudo.
- Animações.
- Efeitos de impacto.
- Sons.
- Indicadores de dano.
- Intervalos entre ataques.

O servidor deverá validar alcance, dano, permissões e estado do jogador.

# 18. SISTEMA DE TRIBOS

Permitir:

- Criar tribo.
- Escolher nome.
- Convidar.
- Aceitar convites.
- Sair.
- Consultar integrantes.
- Compartilhar construções.
- Administrar permissões.

O fundador será o rei/líder inicial.

O rei poderá convidar, expulsar, promover e transferir liderança.

## Proteção entre membros

Jogadores da mesma tribo não podem causar dano uns aos outros.

## Saída voluntária

Ao sair da tribo, aplicar proteção bilateral de cinco minutos entre o jogador e seus antigos companheiros.

Durante esse período, nenhum dos dois lados poderá causar dano ao outro.

Não bloquear combates contra terceiros.

## Expulsão

Ao expulsar um membro, aplicar a mesma proteção bilateral de cinco minutos entre o expulso e os membros da antiga tribo.

A proteção deverá persistir após reconexão.

Não permitir contornar a regra criando outra tribo.

# 19. MULTIPLAYER

Preservar o multiplayer autoritativo.

Implementar:

- Hospedagem.
- Conexão por IP.
- Servidor dedicado.
- Lista de jogadores.
- Chat global.
- Chat de tribo.
- Sincronização de inventário.
- Sincronização de construção.
- Sincronização de animais.
- Sincronização de combate.
- Sincronização do clima.
- Persistência.
- Reconexão.
- Interpolação.
- Validação de ações.

Clientes não poderão definir diretamente vida, recursos ou danos.

O servidor será a autoridade principal.

# 20. SOBREVIVÊNCIA

Implementar:

- Vida.
- Fome.
- Sede.
- Frio.
- Inventário.
- Coleta.
- Caça.
- Cozimento.
- Alimentação.
- Água potável.
- Morte.
- Reaparecimento.

Fogueiras deverão permitir cozinhar e fornecer aquecimento.

# 21. INTERFACE

Criar menus:

- Principal.
- Jogar.
- Criar servidor.
- Entrar em servidor.
- Configurações.
- Gráficos.
- Áudio.
- Controles.
- Inventário.
- Fabricação.
- Construção.
- Tribo.
- Equipamentos.
- Mapa.
- Pausa.
- Morte e reaparecimento.

HUD:

- Vida.
- Fome.
- Sede.
- Temperatura.
- Barra rápida.
- Item equipado.
- Indicador de interação.

A interface deverá ser bonita, organizada e legível em diferentes resoluções.

# 22. ÁUDIO

Implementar:

- Passos.
- Chuva.
- Trovões.
- Vento.
- Fogueiras.
- Animais.
- Mineração.
- Coleta.
- Fabricação.
- Construção.
- Combate.
- Interface.

Utilizar áudio posicional quando apropriado.

Documentar licenças.

# 23. PERSISTÊNCIA E SEGURANÇA

Criar salvamento confiável para:

- Personagens.
- Inventários.
- Equipamentos.
- Construções.
- Tribos.
- Recursos persistentes.
- Estado do mundo.
- Configurações de servidor.

Utilizar identificadores estáveis.

Implementar salvamento periódico, salvamento no encerramento e recuperação segura após falhas.

Utilizar gravações atômicas ou estratégias equivalentes para reduzir corrupção.

Criar backups quando apropriado.

Validar dados recebidos dos clientes.

Impedir duplicação de itens, ataques impossíveis e comandos inválidos.

# 24. BENCHMARK

Criar opção **Exibir desempenho**.

Mostrar:

- FPS.
- FPS médio.
- Tempo de frame.
- Memória utilizada.
- Informações reais de hardware quando disponíveis.

Criar benchmark com:

1. Floresta.
2. Área aberta.
3. Base construída.
4. Chuva forte.
5. Noite com fogueiras.
6. Animais.
7. Multiplayer.

Registrar resultados reais.

Não inventar FPS.

# 25. CRITÉRIOS DE CONCLUSÃO

Uma funcionalidade só poderá ser marcada como concluída quando:

1. Seu código estiver implementado.
2. Estiver integrada ao jogo.
3. Sua interface funcionar, quando necessária.
4. Seu estado for sincronizado corretamente, quando multiplayer.
5. Sua persistência funcionar, quando aplicável.
6. Os testes disponíveis passarem.
7. Não houver erros críticos conhecidos.
8. Não depender de um botão falso ou recurso simulado.

Criar testes para chuva, regeneração, inventário, fabricação, construção, mineração, animais, combate, tribos, multiplayer, persistência e configurações gráficas.

Preservar as 124 verificações existentes.

# 26. PLANO DE EXECUÇÃO EM QUINZE FASES

**Fase 1:** Auditoria completa e recuperação segura.

**Fase 2:** Arquitetura modular e estabilidade.

**Fase 3:** Direção artística, modelos, mundo e iluminação.

**Fase 4:** Sistema gráfico e otimização para hardware antigo.

**Fase 5:** Movimento, câmera, animações e sobrevivência.

**Fase 6:** Inventário, fabricação e progressão.

**Fase 7:** Construção modular e persistência.

**Fase 8:** Animais, IA e caça.

**Fase 9:** Mineração e fundição.

**Fase 10:** Armas, armaduras e combate.

**Fase 11:** Tribos, liderança e regras PvP.

**Fase 12:** Multiplayer, segurança e servidores.

**Fase 13:** Interface, áudio e polimento.

**Fase 14:** Otimização final, testes e benchmarks.

**Fase 15:** Exportação, instaladores e documentação.

Concilie essas fases com as quinze fases originais do repositório, sem perder requisitos.

# 27. ENTREGA FINAL

Quando todos os sistemas obrigatórios estiverem completos e validados, preparar **Tribes of Fire 1.0.0**.

Entregar:

- Instalador Windows.
- ZIP Windows portátil.
- ZIP Linux.
- Servidor dedicado Linux.
- Servidor dedicado Windows quando viável.
- Código-fonte.
- README.
- Documentação.
- Histórico de alterações.
- Relatório de testes.
- Relatório de desempenho.
- Lista de limitações conhecidas.

O jogo deverá iniciar diretamente no menu principal.

Não exigir Godot instalado para jogar.

Preservar os créditos de **felipealx**.

# 28. INSTRUÇÃO FINAL — EXECUÇÃO AUTÔNOMA

Não interrompa o desenvolvimento apenas para explicar o que pretende fazer.

Trabalhe diretamente nos arquivos reais.

Ao concluir cada etapa:

- Implemente.
- Integre.
- Teste.
- Corrija.
- Atualize `PROGRESS.md`.
- Registre as alterações.
- Continue para a próxima etapa.

Não declare a versão 1.0 concluída enquanto existirem funcionalidades obrigatórias incompletas.

Se alguma tarefa depender de hardware, ferramentas, recursos externos ou testes indisponíveis, registre a limitação com precisão e continue nas demais tarefas.

Não invente resultados, não esconda problemas e não apresente demonstrações como funcionalidades completas.

**OBJETIVO FINAL:**

Entregar um jogo de sobrevivência multiplayer 3D bonito, divertido, completo, otimizado e com identidade própria.

O preset Médio deve oferecer a principal experiência artística, buscando bom desempenho até em computadores antigos.

O Ultra deve ser mais detalhado, mas não fotorrealista.

O Muito Baixo deve continuar bonito e ser extremamente leve.

Todos os sistemas de sobrevivência, clima, construção, animais, mineração, combate, tribos e multiplayer devem funcionar de verdade.

**COMECE AGORA ANALISANDO O REPOSITÓRIO E CONTINUE O DESENVOLVIMENTO REAL ATÉ A VERSÃO MAIS COMPLETA E ESTÁVEL POSSÍVEL.**
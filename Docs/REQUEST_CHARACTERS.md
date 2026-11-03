# TRIBES OF FIRE — PERSONAGENS 3D, CRIAÇÃO DE PERSONAGEM, ANIMAÇÕES CINEMATOGRÁFICAS E SISTEMA COMPLETO DE ÁUDIO

## MISSÃO PRINCIPAL

Você é o diretor de animação, artista de personagens 3D, engenheiro de áudio, programador sênior de Godot 4 e responsável pelo desenvolvimento visual e sonoro de **Tribes of Fire**, criado por **felipealx**.

Sua missão é transformar os personagens, animações e sons do projeto atual em sistemas completos, com qualidade artística semelhante à de um bom filme de animação 3D estilizado, mas com desempenho adequado para computadores antigos.

**NÃO RECOMECE O PROJETO DO ZERO.**

Preserve o multiplayer, a movimentação, a sobrevivência, o combate, os equipamentos, as tribos e os sistemas existentes.

Antes de começar, leia o repositório e identifique os modelos, animações, scripts e recursos de áudio já implementados.

Não entregue somente scripts, modelos provisórios, imagens de referência ou descrições. Crie e integre os recursos reais ao jogo.

---

# 1. DIREÇÃO ARTÍSTICA DOS PERSONAGENS

Quero que os personagens de Tribes of Fire tenham uma aparência de **homens e mulheres pré-históricos estilizados**, com qualidade visual de filme de animação.

Utilize como referência geral a linguagem visual de filmes como Os Croods, mas apenas de maneira sutil.

Não copie Grug, sua aparência exata, seu rosto, roupas, cabelo ou outros elementos protegidos.

Crie personagens originais.

## Aparência geral

Os personagens deverão possuir:

- Estatura relativamente baixa.
- Corpos compactos.
- Tronco relativamente largo.
- Ombros fortes.
- Braços robustos.
- Pernas relativamente curtas.
- Mãos grandes, mas proporcionais.
- Pés ligeiramente largos.
- Cabeças um pouco maiores que as proporções humanas realistas.
- Olhos expressivos.
- Sobrancelhas marcantes.
- Narizes estilizados.
- Cabelos volumosos.
- Rostos carismáticos.

Não quero personagens extremamente musculosos ou deformados.

As proporções devem transmitir força, simpatia e personalidade.

O resultado deve lembrar um personagem de animação 3D profissional, não um boneco quadrado ou uma caricatura exagerada.

## Altura

A altura deverá ser personalizável, mas dentro de uma faixa compacta.

Faixa sugerida:

**1,35 m a 1,65 m.**

Altura padrão sugerida: **1,48 m**.

A maioria dos personagens deverá parecer relativamente baixa em comparação com humanos modernos realistas.

A personalização de altura não poderá gerar vantagens injustas no PvP.

Utilizar uma solução de colisão e alcance equilibrada, independente de diferenças puramente cosméticas.

---

# 2. QUALIDADE VISUAL DOS MODELOS 3D

Criar modelos originais com:

- Silhuetas bem trabalhadas.
- Topologia adequada para animação.
- Rostos expressivos.
- Olhos modelados.
- Cabelos tridimensionais.
- Mãos articuladas.
- Dedos animáveis.
- Roupas com geometria própria.
- Materiais estilizados.
- Sombras suaves.
- Boa aparência em diferentes condições de iluminação.

Evitar texturas fotográficas ultrarrealistas.

Priorizar materiais estilizados, cores agradáveis e geometria bem elaborada.

Os personagens deverão ser bonitos tanto no preset Médio quanto no Ultra.

Não usar cubos, cápsulas ou bonecos genéricos como modelos finais.

---

# 3. ROUPAS PRIMITIVAS

O personagem deverá começar com roupas pré-históricas.

## Roupa inicial

Criar uma roupa de pele animal com padrão inspirado em felinos pintados, como onças.

Características:

- Tecido de pele animal estilizada.
- Manchas escuras.
- Tons de amarelo, bege e marrom.
- Costuras primitivas.
- Bordas irregulares.
- Amarrações com cordas.
- Aparência artesanal.

A roupa não deve parecer uma fantasia moderna.

Criar versões apropriadas para os diferentes modelos corporais.

## Variações

Adicionar:

- Roupa de pele de onça estilizada.
- Pele de lobo.
- Pele de urso.
- Couro simples.
- Roupa de fibras vegetais.
- Roupa de couro reforçado.
- Equipamentos de ossos.
- Armaduras de metal, conforme a progressão do jogo.

A roupa inicial deverá ser visualmente agradável, não apenas uma textura aplicada ao corpo.

As roupas deverão acompanhar corretamente os movimentos e animações.

Evitar atravessamento excessivo de geometria.

Não exigir simulação de tecido pesada em computadores antigos.

---

# 4. MENU DE CRIAÇÃO DE PERSONAGEM

**CRIAR UM EDITOR DE PERSONAGEM COMPLETO ANTES DA PRIMEIRA ENTRADA NO MUNDO.**

Na primeira vez que o jogador entrar em um servidor com um personagem novo, abrir a tela de criação.

A ordem será:

1. Abrir o jogo.
2. Selecionar idioma, caso ainda não tenha escolhido.
3. Entrar no menu principal.
4. Escolher jogar ou entrar em um servidor.
5. Criar personagem, caso ainda não exista um personagem válido naquele servidor.
6. Confirmar a aparência.
7. Entrar no mundo.

Se o personagem já existir, carregar sua aparência salva sem obrigar o jogador a recriá-lo.

## Interface

Criar um ambiente de criação com:

- Personagem 3D no centro.
- Câmera rotacionável.
- Zoom.
- Iluminação agradável.
- Fundo estilizado.
- Menu de personalização.
- Pré-visualização em tempo real.
- Botão de randomizar.
- Botão de restaurar padrões.
- Botão de confirmar.

O jogador deverá conseguir girar o personagem para visualizar frente, costas e laterais.

---

# 5. PERSONALIZAÇÃO DO PERSONAGEM

Implementar opções reais de personalização.

## 5.1 Corpo

Permitir escolher:

- Modelo corporal.
- Altura.
- Largura dos ombros.
- Volume corporal.
- Musculatura estilizada.
- Tom de pele.

Evitar deformações extremas.

Todas as opções devem respeitar a direção artística.

## 5.2 Olhos

Permitir escolher:

- Formato dos olhos.
- Tamanho.
- Espaçamento.
- Inclinação.
- Cor da íris.

Cores sugeridas:

- Castanho-escuro.
- Castanho-claro.
- Mel.
- Verde.
- Azul.
- Cinza.
- Âmbar.

As cores deverão ser visíveis no modelo real.

## 5.3 Cabelo

Criar diferentes penteados:

- Curto bagunçado.
- Médio volumoso.
- Longo.
- Preso.
- Trançado.
- Raspado nas laterais.
- Cabelo encaracolado.
- Cabelo ondulado.
- Cabelo liso.

Cores:

- Preto.
- Castanho-escuro.
- Castanho-claro.
- Loiro.
- Ruivo.
- Cinza.
- Branco.

O cabelo deverá possuir volume tridimensional e acompanhar a cabeça corretamente.

Evitar usar apenas texturas planas como substituição para penteados completos.

## 5.4 Rosto

Permitir ajustar:

- Formato do rosto.
- Bochechas.
- Nariz.
- Boca.
- Queixo.
- Sobrancelhas.
- Orelhas.

Utilizar morph targets, blend shapes ou alternativas compatíveis com a arquitetura do projeto.

## 5.5 Barba

Adicionar opções como:

- Sem barba.
- Barba curta.
- Barba média.
- Barba cheia.
- Cavanhaque.
- Bigode.

Permitir combinar com diferentes penteados.

## 5.6 Roupa inicial

Permitir escolher entre algumas variações visuais de roupas primitivas, incluindo a roupa de pele de onça estilizada.

As opções iniciais deverão ser cosméticas e equilibradas.

## 5.7 Nome

Permitir definir o nome do personagem.

Validar comprimento, caracteres permitidos e nomes inadequados conforme as regras do servidor.

---

# 6. SISTEMA DE SALVAMENTO DA APARÊNCIA

A aparência criada deverá ser salva de forma persistente.

Salvar:

- Modelo corporal.
- Altura.
- Olhos.
- Cor dos olhos.
- Cabelo.
- Cor do cabelo.
- Rosto.
- Barba.
- Tom de pele.
- Roupa inicial.
- Nome.

A aparência deverá ser sincronizada pelo servidor.

Todos os jogadores devem enxergar corretamente as personalizações uns dos outros.

Não enviar modelos 3D completos pela rede.

Sincronizar identificadores de opções e parâmetros de personalização validados.

Evitar que clientes enviem valores inválidos para criar personagens gigantes, invisíveis ou deformados.

---

# 7. SISTEMA PROFISSIONAL DE ANIMAÇÕES

Quero uma melhoria significativa na qualidade das animações.

**Os personagens não podem parecer robôs, bonecos rígidos ou objetos deslizando pelo chão.**

Implementar um esqueleto 3D adequado e animações fluidas.

Utilizar `Skeleton3D`, `AnimationTree`, blend spaces, máquinas de estados e outras ferramentas apropriadas do Godot 4.

## Animações de movimento

Criar:

- Parado.
- Respiração.
- Andando.
- Correndo.
- Corrida acelerando.
- Corrida desacelerando.
- Virando.
- Pulando.
- Caindo.
- Aterrissando.
- Agachando.
- Caminhando agachado.
- Nadando.
- Subindo pequenas inclinações.
- Movimentação lateral.
- Andando para trás.

Criar transições suaves.

Os pés deverão acompanhar o movimento, evitando deslizamento excessivo.

## Personalidade da movimentação

Quero que o personagem pareça um humano pré-histórico estilizado.

A caminhada deverá ter:

- Passos ligeiramente pesados.
- Movimento natural dos ombros.
- Balanço moderado dos braços.
- Pequeno movimento do tronco.
- Expressividade corporal.

A corrida deverá ser energética e fluida.

Não exagerar a ponto de parecer uma paródia.

---

# 8. ANIMAÇÕES DE SOBREVIVÊNCIA

Criar animações para:

- Coletar madeira.
- Pegar pedras.
- Minerar.
- Cortar árvores.
- Fabricar itens.
- Construir.
- Acender fogueira.
- Cozinhar.
- Comer.
- Beber.
- Dormir.
- Sentar.
- Sentir frio.
- Tremer de frio.
- Sentir calor.
- Receber dano.
- Cair.
- Morrer.
- Reaparecer.

As animações devem corresponder às ações reais.

Não executar uma animação de mineração quando o jogador estiver coletando outro tipo de recurso.

Sincronizar os momentos de contato com efeitos sonoros e partículas.

---

# 9. ANIMAÇÕES DE COMBATE

Criar:

- Ataque leve com espada.
- Ataque pesado.
- Ataque com lança.
- Ataque com machado.
- Defesa com escudo.
- Bloqueio.
- Esquiva.
- Preparação de arco.
- Disparo de flecha.
- Reação a impacto.
- Morte.

Adicionar transições naturais.

Não permitir que ataques sejam repetidos sem respeitar os intervalos definidos pelo combate.

Sincronizar eventos de animação com as janelas reais de dano validadas pelo servidor.

---

# 10. EXPRESSÕES FACIAIS

Criar expressões simples e carismáticas:

- Neutro.
- Feliz.
- Assustado.
- Irritado.
- Cansado.
- Sentindo dor.
- Sentindo frio.
- Surpreso.

Adicionar piscadas naturais e movimentos discretos dos olhos.

Quando o personagem estiver com pouca vida, poderá demonstrar cansaço ou dor.

Evitar animações faciais excessivamente caras.

Usar blend shapes ou animações simples quando apropriado.

---

# 11. ANIMAÇÕES SECUNDÁRIAS

Adicionar movimentos sutis para:

- Cabelo.
- Roupas.
- Acessórios.
- Equipamentos presos ao corpo.
- Respiração.
- Cabeça.
- Olhar.

Utilizar animações secundárias econômicas.

Não depender de simulação física pesada.

Criar níveis de detalhe de animação para personagens distantes.

---

# 12. SISTEMA COMPLETO DE SONS

**CRIAR E INTEGRAR SONS REAIS AO JOGO.**

Não basta adicionar chamadas para reproduzir arquivos inexistentes.

Os recursos deverão estar presentes, corretamente licenciados, importados e funcionando.

Se ferramentas de síntese ou geração de áudio estiverem disponíveis, utilizá-las para criar sons originais.

Caso contrário, utilizar recursos sonoros compatíveis com as licenças do projeto.

Não copiar trilhas sonoras ou efeitos protegidos de filmes e jogos comerciais.

## 12.1 Passos

Criar sons diferentes para:

- Grama.
- Terra.
- Pedra.
- Madeira.
- Areia.
- Água rasa.
- Neve, quando aplicável.

O ritmo dos passos deverá acompanhar a animação.

Andar e correr deverão produzir cadências diferentes.

## 12.2 Ambiente

Criar:

- Vento.
- Folhas balançando.
- Pássaros.
- Insetos.
- Água corrente.
- Ondas.
- Floresta.
- Sons noturnos.
- Ambientes de cavernas.

Os sons deverão variar conforme bioma, horário e clima.

## 12.3 Clima

Criar:

- Chuva fraca.
- Chuva intensa.
- Pingos em telhados.
- Vento forte.
- Trovões distantes.
- Trovões próximos.
- Tempestades.

Os trovões deverão variar de intensidade.

A chuva deverá ter volume e características diferentes dentro e fora de abrigos.

## 12.4 Fogueiras

Criar:

- Crepitação.
- Madeira queimando.
- Estalos ocasionais.
- Acendimento.
- Extinção.

Utilizar áudio espacial.

## 12.5 Mineração

Criar sons de:

- Picareta em pedra.
- Picareta em minério.
- Impacto metálico.
- Quebra de depósito.
- Coleta de minério.

## 12.6 Construção

Criar:

- Colocação de madeira.
- Colocação de pedra.
- Construção metálica.
- Reparos.
- Demolição.
- Abertura de portas.
- Fechamento de portas.

## 12.7 Combate

Criar:

- Golpes de espada.
- Impactos em armaduras.
- Bloqueio com escudo.
- Flechas.
- Arco sendo tensionado.
- Ataques com machado.
- Reações de dano.

Evitar sons exageradamente violentos ou repetitivos.

## 12.8 Interface

Criar sons discretos para:

- Botões.
- Confirmações.
- Erros.
- Inventário.
- Fabricação.
- Equipamentos.
- Notificações.
- Convites.
- Mensagens.

A interface deve ser agradável, não barulhenta.

---

# 13. VOZES E VOCALIZAÇÕES DOS PERSONAGENS

Adicionar vocalizações curtas e originais.

Exemplos:

- Respiração.
- Esforço ao correr.
- Esforço ao atacar.
- Reação a dano.
- Cansaço.
- Frio.
- Surpresa.
- Comemoração discreta.

Não utilizar falas copiadas de Os Croods.

Não exagerar nas vocalizações.

O personagem não deve emitir sons repetitivos a cada segundo.

Criar variações e intervalos apropriados.

---

# 14. SISTEMA DE ÁUDIO ESPACIAL

Utilizar `AudioStreamPlayer3D` ou solução equivalente para sons posicionais.

Aplicar:

- Atenuação por distância.
- Posicionamento estéreo.
- Volume por categoria.
- Limites de vozes simultâneas.
- Priorização de sons próximos.
- Tratamento de sons distantes.

Adicionar barramentos de áudio separados para:

- Volume geral.
- Música.
- Ambiente.
- Efeitos.
- Interface.
- Vozes dos personagens.
- Chat de voz.

O chat de voz existente deverá continuar independente das vocalizações do personagem.

---

# 15. MÚSICA ORIGINAL

Criar uma identidade musical própria para Tribes of Fire.

Quero músicas instrumentais discretas, com atmosfera de aventura e natureza pré-histórica estilizada.

Criar temas para:

- Menu principal.
- Exploração tranquila.
- Florestas.
- Noite.
- Combate.
- Momentos de perigo.
- Criação de personagem.

Priorizar instrumentos e timbres que combinem com a ambientação, como percussão leve, flautas, cordas e texturas ambientais.

Não copiar músicas de filmes ou jogos existentes.

Evitar música constante e excessivamente alta.

Implementar transições suaves e momentos de silêncio.

Se não houver ferramentas para produzir áudio musical original com qualidade, documentar a limitação e utilizar apenas recursos licenciados adequados, sem apresentar arquivos fictícios.

---

# 16. MENU DE CRIAÇÃO COM QUALIDADE CINEMATOGRÁFICA

O menu de criação deverá ser uma das telas mais bonitas do jogo.

Criar um pequeno ambiente 3D com:

- Iluminação suave.
- Fundo de floresta estilizada.
- Personagem centralizado.
- Câmera rotacionável.
- Animação de respiração.
- Expressões ocasionais.
- Música ambiente discreta.
- Transições suaves.

Ao modificar cabelo, olhos, altura ou roupa, a alteração deverá aparecer imediatamente no modelo.

Ao confirmar, reproduzir uma animação curta de apresentação do personagem.

Não criar uma sequência longa ou obrigatória que atrapalhe o jogador.

---

# 17. OTIMIZAÇÃO PARA COMPUTADORES ANTIGOS

Preservar o objetivo de executar Tribes of Fire em computadores modestos.

O preset Médio deverá continuar sendo a referência principal de qualidade visual.

As melhorias dos personagens não podem destruir o desempenho.

Implementar:

- Modelos com LOD.
- Materiais compartilhados.
- Texturas otimizadas.
- Esqueletos eficientes.
- Limites de ossos e influências por vértice.
- Redução de atualização de animações distantes.
- Simplificação de cabelos.
- Alternativas leves para roupas.
- Limitação de efeitos secundários.
- Instanciamento eficiente.
- Gerenciamento de áudio.
- Limites de sons simultâneos.

Não exigir simulação complexa de cabelo ou tecido.

Manter a mesma identidade visual em todos os presets.

Não exibir nomes de placas de vídeo ou quantidades de RAM de referência na interface.

Somente mostrar informações reais do computador do jogador quando detectadas corretamente.

---

# 18. INTEGRAÇÃO COM MULTIPLAYER

Todos os personagens personalizados deverão aparecer corretamente para outros jogadores.

Sincronizar:

- Aparência.
- Equipamentos.
- Estado de movimento.
- Ações.
- Animações relevantes.
- Expressões necessárias.
- Eventos sonoros.

Não transmitir animações completas quadro a quadro.

Sincronizar estados e parâmetros compactos.

Não confiar em valores de personalização enviados pelo cliente sem validação.

A personalização não poderá alterar injustamente alcance de ataque, velocidade ou resistência.

---

# 19. ARQUITETURA DO SISTEMA

Organizar o código em componentes modulares.

Sugestões:

- CharacterCreator.
- CharacterAppearance.
- CharacterCustomizationData.
- CharacterAnimationController.
- CharacterAudioController.
- CharacterEquipmentVisuals.
- FootstepSystem.
- AmbientAudioManager.
- MusicManager.
- AudioSettingsManager.

Os nomes podem ser adaptados à arquitetura existente.

Não concentrar tudo em `Main.gd`.

Criar recursos reutilizáveis para modelos, materiais, animações e áudio.

---

# 20. TESTES OBRIGATÓRIOS

Executar testes para:

## Criação de personagem

- Primeira inicialização.
- Escolha de modelo corporal.
- Alteração de altura.
- Alteração de olhos.
- Alteração de cor dos olhos.
- Alteração de cabelo.
- Alteração de cor do cabelo.
- Alteração de roupa.
- Salvamento.
- Carregamento.
- Reconexão.
- Sincronização multiplayer.

## Animações

- Andar.
- Correr.
- Pular.
- Cair.
- Atacar.
- Minerar.
- Construir.
- Coletar.
- Morrer.
- Reaparecer.
- Transições.
- Equipamentos visíveis.

## Áudio

- Passos.
- Ambiente.
- Chuva.
- Trovões.
- Fogueiras.
- Mineração.
- Combate.
- Interface.
- Áudio espacial.
- Configurações de volume.

## Desempenho

Testar:

- Um personagem.
- Vários personagens.
- Personagens com roupas diferentes.
- Personagens animados simultaneamente.
- Combate multiplayer.
- Floresta com sons ambientais.
- Chuva forte.
- Várias fontes sonoras.

Registrar FPS, memória e custo de animações quando possível.

Não inventar resultados.

---

# 21. CRITÉRIOS DE CONCLUSÃO

Não considerar este trabalho concluído enquanto:

- Os modelos definitivos não estiverem integrados.
- A criação de personagem não funcionar.
- A personalização não aparecer visualmente.
- A aparência não for salva.
- Outros jogadores não enxergarem a aparência correta.
- As animações principais não funcionarem.
- As transições estiverem quebradas.
- Os sons essenciais não estiverem presentes.
- Os sons não forem reproduzidos corretamente.
- O áudio espacial não funcionar.
- O desempenho não tiver sido avaliado.
- Os testes disponíveis não tiverem sido executados.

Se não for possível criar algum recurso devido a limitações reais do ambiente, documentar a pendência e continuar implementando o restante.

Não declarar recursos provisórios como definitivos.

---

# 22. ORDEM DE DESENVOLVIMENTO

**Fase 1:** Auditoria dos modelos, animações e sons existentes.

**Fase 2:** Criação dos modelos 3D originais e materiais estilizados.

**Fase 3:** Rigging e sistema de animações.

**Fase 4:** Movimentação, transições e animações de sobrevivência.

**Fase 5:** Combate e expressões faciais.

**Fase 6:** Roupas primitivas e equipamentos visuais.

**Fase 7:** Menu de criação de personagem.

**Fase 8:** Personalização de olhos, cabelo, corpo, altura e rosto.

**Fase 9:** Salvamento e sincronização multiplayer.

**Fase 10:** Sons de ambiente, clima, passos e ações.

**Fase 11:** Vocalizações, música e áudio espacial.

**Fase 12:** Otimização de modelos, animações e áudio.

**Fase 13:** Testes, correções e polimento final.

Ao concluir cada fase, implemente, integre, teste, corrija e prossiga.

Atualize `PROGRESS.md` e a documentação.

---

# 23. RESULTADO FINAL ESPERADO

Quero que os personagens de Tribes of Fire pareçam protagonistas de um filme de animação 3D estilizado.

Devem ser relativamente baixos, compactos, fortes, expressivos e carismáticos, com aparência pré-histórica e roupas primitivas de pele animal, incluindo a pele de onça estilizada.

O jogador deverá conseguir personalizar:

- Altura.
- Corpo.
- Rosto.
- Olhos.
- Cor dos olhos.
- Cabelo.
- Cor do cabelo.
- Barba.
- Tom de pele.
- Roupa inicial.
- Nome.

O personagem deverá possuir animações fluidas e expressivas para movimentação, combate, coleta, mineração, construção e sobrevivência.

O jogo deverá ter sons reais, variados, bem integrados e espacializados.

A criação de personagem deverá acontecer antes da primeira entrada no mundo e a aparência deverá ser salva permanentemente.

Tudo deverá funcionar com o multiplayer e continuar otimizado para computadores antigos.

**COMECE AGORA.**

Analise o repositório atual, desenvolva os modelos, animações, sistema de criação de personagem e recursos sonoros, integre tudo ao jogo e execute os testes disponíveis.

Não entregue apenas planejamento, descrições ou arquivos provisórios. Entregue implementações reais e documente honestamente qualquer limitação que impedir a conclusão de uma parte do trabalho.
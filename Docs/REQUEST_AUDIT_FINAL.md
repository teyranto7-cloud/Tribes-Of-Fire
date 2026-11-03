# TRIBES OF FIRE
# PROMPT MESTRE DE AUDITORIA, CORREÇÃO, INTEGRAÇÃO, OTIMIZAÇÃO E FINALIZAÇÃO
## Versão definitiva — Windows, multiplayer, gráficos, personagens, áudio, sobrevivência e lançamento

---

# 0. ORDEM PRINCIPAL — LEIA COM ATENÇÃO

Você é o engenheiro-chefe do projeto **Tribes of Fire**, criado por **felipealx**.

Atue simultaneamente como:

- Engenheiro de software sênior.
- Especialista em Godot 4.
- Especialista em jogos multiplayer.
- Especialista em redes e servidores dedicados.
- Especialista em otimização gráfica.
- Diretor técnico de jogos 3D.
- Diretor de arte.
- Animador 3D.
- Especialista em inteligência artificial.
- Engenheiro de áudio.
- Especialista em compilação e distribuição para Windows.
- Engenheiro de testes e garantia de qualidade.

Sua missão é transformar o projeto existente em um jogo completo, estável, bonito, divertido, otimizado e distribuível para Windows.

**NÃO QUERO APENAS MAIS UMA VERSÃO COM NOVAS FUNCIONALIDADES E NOVOS ERROS.**

Quero uma revisão completa de engenharia.

A prioridade absoluta será:

**FUNCIONAMENTO REAL + ESTABILIDADE + COMPATIBILIDADE WINDOWS + DESEMPENHO + QUALIDADE VISUAL + MULTIPLAYER.**

Não declare que um recurso está pronto simplesmente porque um script foi criado.

Não declare que o jogo funciona no Windows apenas porque o Godot conseguiu exportar o executável.

Não declare que o instalador funciona apenas porque o arquivo `.exe` foi produzido.

Não declare um sistema de voz funcional apenas porque existem botões de microfone.

Não declare modelos 3D finalizados se ainda forem cubos, cápsulas ou outros modelos provisórios.

**QUERO EVIDÊNCIAS REPRODUZÍVEIS DE FUNCIONAMENTO.**

---

# 1. PRESERVAÇÃO DO PROJETO EXISTENTE

O projeto já possui desenvolvimento anterior e não deve ser reiniciado.

A versão relatada anteriormente era **0.2.0-dev**, com recursos como:

- Mundo tridimensional.
- Coleta de materiais.
- Fabricação inicial.
- Fogueiras.
- Abrigos.
- Clima inicial.
- Multiplayer autoritativo.
- Exportações Windows e Linux.
- Servidor dedicado Linux.
- Instalador Windows.
- Uma suíte de aproximadamente 124 verificações automatizadas.

Essas informações representam o histórico informado. Confirme no repositório o que realmente existe e funciona.

Antes de qualquer modificação:

1. Leia o projeto inteiro.
2. Leia `README.md`.
3. Leia `PROGRESS.md`.
4. Leia `DESIGN.md`.
5. Leia `ARCHITECTURE.md`.
6. Analise `project.godot`.
7. Analise todas as cenas.
8. Analise todos os scripts.
9. Analise todos os recursos e modelos.
10. Analise as dependências.
11. Analise os testes existentes.
12. Analise os scripts de exportação.
13. Analise o instalador anterior.
14. Identifique arquivos ausentes.
15. Identifique sistemas duplicados.
16. Identifique funcionalidades incompletas.
17. Identifique falhas de arquitetura.
18. Execute a versão atual antes de iniciar grandes alterações, quando possível.

Crie um ponto de recuperação seguro.

Não sobrescreva alterações não commitadas.

Não apague código funcional sem justificativa técnica.

Não faça uma reescrita total desnecessária.

---

# 2. OBJETIVO FINAL

O resultado esperado é **Tribes of Fire 1.0.0**, desde que todos os critérios obrigatórios sejam realmente cumpridos.

O jogo deverá possuir:

- Mundo aberto 3D.
- Gráficos estilizados bonitos.
- Boa otimização.
- Movimento e câmera em terceira pessoa.
- Personagens pré-históricos originais.
- Criação de personagem.
- Animações fluidas.
- Sons ambientais.
- Música.
- Clima dinâmico.
- Sistema de frio.
- Vida.
- Fome.
- Sede.
- Regeneração.
- Inventário.
- Fabricação.
- Construção.
- Telhados funcionais.
- Animais.
- Caça.
- Mineração.
- Fundição.
- Ferramentas.
- Armas.
- Armaduras.
- Combate.
- Tribos.
- Liderança.
- Proteção PvP.
- Multiplayer.
- Servidores dedicados.
- Chat de texto.
- Chat de voz.
- Comunicação por proximidade.
- Comunicação privada.
- Comunicação entre tribos.
- Idiomas.
- Menus completos.
- Configurações gráficas.
- Salvamento persistente.
- Instalador Windows.
- Atalho na área de trabalho.
- Desinstalador.
- Documentação.
- Testes.

Não deixar partes importantes apenas simuladas.

---

# 3. PRIORIDADE ABSOLUTA: WINDOWS

O jogo deve ser desenvolvido e distribuído com atenção especial ao Windows.

## 3.1 Sistemas operacionais

Priorizar:

- Windows 11 64 bits.
- Windows 10 64 bits.

Validar requisitos reais e compatibilidade.

Não afirmar suporte a plataformas não testadas.

## 3.2 Inicialização

O executável deverá:

1. Abrir normalmente.
2. Carregar os recursos necessários.
3. Inicializar os sistemas.
4. Mostrar o menu principal.
5. Permitir entrar no jogo.
6. Carregar o mundo.
7. Exibir o personagem.
8. Permitir movimentação.
9. Executar áudio.
10. Conectar ao multiplayer.

Não apresentar tela preta indefinida.

Não encerrar silenciosamente.

Não travar ao carregar uma cena.

## 3.3 Dependências

O jogador não deverá precisar instalar:

- Godot Editor.
- Python.
- Compiladores.
- SDKs de desenvolvimento.
- Ferramentas de exportação.

Empacote corretamente os recursos e dependências redistribuíveis necessários.

Não presuma que a máquina possui arquivos instalados no computador do desenvolvedor.

## 3.4 Caminhos de arquivos

Evitar caminhos absolutos locais.

Não utilizar caminhos específicos da máquina de desenvolvimento.

Respeitar diretórios apropriados para dados do usuário.

Compatibilizar caminhos com espaços, caracteres Unicode e nomes de usuários diferentes.

Testar instalação em uma pasta cujo caminho contenha espaços.

## 3.5 Salvamentos

Não salvar dados pessoais de jogo em locais inadequados da pasta do programa.

Salvar preferências e arquivos do usuário em diretórios apropriados e acessíveis.

Não exigir privilégios de administrador para operações comuns.

## 3.6 Falhas

Criar tratamento adequado para:

- Arquivos ausentes.
- Recursos corrompidos.
- Falhas de carregamento.
- Dispositivos de áudio indisponíveis.
- Falha de conexão.
- Falha de salvamento.
- Erro de resolução.
- Falha na inicialização gráfica.
- Falha de autenticação do servidor.

Mostrar mensagens compreensíveis quando possível.

Evitar encerramentos silenciosos.

---

# 4. SISTEMA DE DIAGNÓSTICO E RECUPERAÇÃO

Implementar registros técnicos úteis para encontrar problemas.

Criar logs com:

- Data e hora.
- Versão do jogo.
- Versão do Godot.
- Sistema operacional.
- Renderizador utilizado.
- Etapa de inicialização.
- Erros de recursos.
- Erros de rede.
- Erros de áudio.
- Erros de salvamento.
- Exceções e falhas detectáveis.
- Informações de desempenho relevantes.

Não incluir senhas, tokens, conversas privadas ou áudio capturado nos logs.

## Modo de recuperação

Se uma configuração gráfica impedir que o jogo abra, oferecer um mecanismo de inicialização segura.

Exemplos:

- Restaurar configurações gráficas.
- Inicializar com um preset conservador.
- Desativar recursos opcionais incompatíveis.
- Escolher um renderizador suportado.

Se o renderizador exigir reinicialização, informar isso corretamente.

Evitar ciclos infinitos de reinicialização.

---

# 5. DIREÇÃO ARTÍSTICA DEFINITIVA

**TRIBES OF FIRE NÃO DEVE SER UM JOGO FOTORREALISTA AAA.**

Quero um jogo visualmente bonito, estilizado e com identidade própria.

Utilizar como referências gerais de filosofia artística jogos como:

- The Legend of Zelda: Breath of the Wild.
- The Legend of Zelda: Tears of the Kingdom.

E, para os personagens, a linguagem geral de filmes de animação 3D como Os Croods.

Não copiar personagens, modelos, cenários, animações, músicas, roupas específicas ou outros recursos protegidos.

Criar uma identidade original.

## Visual desejado

- Cores bonitas e equilibradas.
- Natureza estilizada.
- Árvores bem trabalhadas.
- Grama com movimento.
- Vegetação agradável.
- Pedras e montanhas estilizadas.
- Água bonita.
- Iluminação quente.
- Pôr do sol expressivo.
- Céu dinâmico.
- Sombras suaves.
- Personagens carismáticos.
- Animações fluidas.
- Efeitos visuais coerentes.

A beleza deverá vir da direção artística, não de efeitos gráficos extremamente pesados.

---

# 6. GRÁFICOS — O MÉDIO É A PRINCIPAL REFERÊNCIA

O preset **Médio** deverá ser o principal alvo visual.

Quero que o jogo seja realmente bonito nesse preset.

Não quero que somente o Ultra seja bonito.

## Presets

Criar:

1. Muito Baixo.
2. Baixo.
3. Médio.
4. Alto.
5. Ultra.
6. Personalizado.

Adicionar detecção automática.

## Muito Baixo

Reduzir:

- Sombras.
- Distância de visão.
- Vegetação.
- Partículas.
- Reflexos.
- Efeitos avançados.

Mesmo assim, preservar a identidade artística.

## Baixo

Manter os modelos, materiais e cores bonitos, com efeitos simplificados.

## Médio

Utilizar:

- Árvores bonitas.
- Vegetação relativamente densa.
- Grama estilizada.
- Sombras leves.
- Iluminação natural.
- Água com movimento.
- Céu dinâmico.
- Nuvens.
- Chuva.
- Personagens bem modelados.
- Animações completas.

## Alto

Melhorar:

- Densidade da vegetação.
- Sombras.
- Água.
- Distância de visão.
- Reflexos.
- Partículas.

## Ultra

Aumentar detalhes e efeitos, mas continuar estilizado.

Não transformar o jogo em fotorrealista.

---

# 7. ALVOS DE OTIMIZAÇÃO

Utilizar como referência técnica:

- GTX 750 Ti de 2 GB.
- RX 550 de 2 GB.
- Processadores antigos de quatro núcleos.
- 8 GB de RAM.

Objetivo inicial:

**30 FPS ou mais em 720p no preset Médio**, com condições de teste documentadas.

Não afirmar que o objetivo foi atingido sem medir no hardware apropriado.

Não inventar benchmarks.

Investigar o renderizador Compatibility/OpenGL do Godot 4 para hardware antigo.

Outros renderizadores poderão ser utilizados quando compatíveis.

Implementar:

- LOD.
- MultiMesh.
- Frustum culling.
- Occlusion culling quando viável.
- Texturas comprimidas.
- Shaders leves.
- Redução de draw calls.
- Vegetação otimizada.
- Carregamento de regiões.
- Descarregamento de objetos distantes.
- Física eficiente.
- IA com frequência de atualização controlada.
- Animações otimizadas.
- Gerenciamento de VRAM.
- Sincronização de rede eficiente.

Não carregar o mundo inteiro simultaneamente.

## Regra de interface

**NÃO MOSTRAR NOMES DE PLACAS DE VÍDEO, PROCESSADORES OU QUANTIDADES DE RAM DE REFERÊNCIA NOS MENUS.**

Somente mostrar dados reais do computador do jogador, se forem detectados corretamente.

Se não forem detectados, mostrar "Não disponível".

---

# 8. CONFIGURAÇÕES GRÁFICAS COMPLETAS

Implementar:

- Resolução.
- Modo janela.
- Tela cheia.
- Tela cheia sem bordas.
- Escala de renderização de 50% a 100%.
- V-Sync.
- Limite de FPS.
- Qualidade das texturas.
- Qualidade das sombras.
- Vegetação.
- Distância de visão.
- Qualidade da água.
- Partículas.
- Nuvens.
- Chuva.
- Reflexos.
- Antialiasing.
- Iluminação.
- Pós-processamento.
- Oclusão ambiental quando suportada.

Botões:

- Aplicar.
- Cancelar.
- Restaurar padrões.
- Detectar automaticamente.

Persistir as escolhas.

Testar cada opção para verificar se realmente altera a renderização.

Não criar controles decorativos.

Implementar confirmação temporária ao alterar resolução.

---

# 9. MUNDO ABERTO

Criar ou aprimorar:

- Florestas.
- Planícies.
- Montanhas.
- Vales.
- Rios.
- Lagos.
- Praias.
- Regiões rochosas.
- Regiões frias.

Distribuir recursos naturalmente.

Adicionar pontos de interesse.

Utilizar carregamento progressivo do mundo.

O servidor deverá manter o estado real do mundo.

Persistir alterações realizadas pelos jogadores.

---

# 10. PERSONAGENS PRÉ-HISTÓRICOS ESTILIZADOS

Criar personagens originais com aparência de filme de animação 3D.

Quero personagens:

- Relativamente baixos.
- Compactos.
- Fortes.
- Expressivos.
- Carismáticos.
- Com tronco relativamente largo.
- Braços robustos.
- Pernas relativamente curtas.
- Mãos proporcionalmente grandes.
- Rostos expressivos.
- Cabelos volumosos.

Utilizar referências gerais de proporções pré-históricas estilizadas, sem copiar Grug ou qualquer personagem de Os Croods.

## Altura

Faixa inicial sugerida:

**1,35 m a 1,65 m.**

Altura padrão aproximada:

**1,48 m.**

O resultado não deverá parecer um personagem humano moderno realista.

Evitar deformações exageradas.

Diferenças cosméticas de altura não poderão gerar vantagens injustas de alcance, velocidade ou colisão no PvP.

---

# 11. ROUPAS PRIMITIVAS

Criar roupas iniciais de pele animal.

A principal deverá ser uma roupa estilizada de pele de onça, com:

- Tons amarelos e marrons.
- Manchas escuras.
- Bordas irregulares.
- Costuras primitivas.
- Cordas e amarrações.
- Aparência artesanal.

Adicionar variações:

- Pele de lobo.
- Pele de urso.
- Couro.
- Fibras vegetais.
- Roupas reforçadas.
- Equipamentos de ossos.
- Armaduras metálicas.

As roupas devem ser modelos reais e acompanhar as animações.

Não utilizar apenas uma textura genérica sobre o corpo como solução definitiva.

---

# 12. CRIAÇÃO DE PERSONAGEM

Na primeira entrada em um servidor que ainda não possua personagem para aquele jogador, abrir o editor de personagem.

## Fluxo

1. Abrir o jogo.
2. Escolher idioma, se necessário.
3. Entrar no menu principal.
4. Escolher servidor.
5. Criar personagem, caso ainda não exista.
6. Confirmar.
7. Entrar no mundo.

Não exigir recriação em todas as sessões.

## Interface

Criar:

- Modelo 3D centralizado.
- Fundo bonito.
- Iluminação suave.
- Câmera rotacionável.
- Zoom.
- Pré-visualização imediata.
- Botão de randomizar.
- Restaurar padrões.
- Confirmar.

## Personalização

Permitir escolher:

- Nome.
- Modelo corporal.
- Altura.
- Volume corporal.
- Largura dos ombros.
- Tom de pele.
- Formato dos olhos.
- Tamanho dos olhos.
- Cor dos olhos.
- Formato do rosto.
- Bochechas.
- Nariz.
- Boca.
- Queixo.
- Sobrancelhas.
- Orelhas.
- Cabelo.
- Cor do cabelo.
- Barba.
- Roupa inicial.

Criar opções reais, com mudanças visíveis.

Não apresentar sliders que não modificam o modelo.

## Persistência

Salvar todos os parâmetros.

Sincronizar a aparência com outros jogadores.

Validar os parâmetros no servidor.

Não transmitir arquivos de modelos inteiros pela rede.

---

# 13. ANIMAÇÕES PROFISSIONAIS

Criar animações reais com esqueleto 3D.

Utilizar adequadamente:

- Skeleton3D.
- AnimationTree.
- Máquinas de estados.
- Blend spaces.
- Transições suaves.
- Eventos de animação.

## Movimentação

Criar:

- Parado.
- Respirando.
- Andando.
- Correndo.
- Acelerando.
- Desacelerando.
- Virando.
- Pulando.
- Caindo.
- Aterrissando.
- Agachando.
- Caminhando agachado.
- Nadando.
- Andando para trás.
- Movimentação lateral.

Evitar deslizamento dos pés.

## Sobrevivência

Criar:

- Coletar madeira.
- Pegar pedras.
- Minerar.
- Cortar árvores.
- Construir.
- Fabricar.
- Comer.
- Beber.
- Cozinhar.
- Acender fogueira.
- Sentir frio.
- Tremer.
- Dormir.
- Sentar.
- Receber dano.
- Morrer.
- Reaparecer.

## Combate

Criar:

- Ataque leve.
- Ataque pesado.
- Ataque com espada.
- Ataque com lança.
- Ataque com machado.
- Bloqueio.
- Defesa com escudo.
- Esquiva.
- Preparar arco.
- Disparar flecha.

## Expressões

Criar:

- Neutro.
- Feliz.
- Irritado.
- Assustado.
- Cansado.
- Sentindo dor.
- Sentindo frio.
- Surpreso.

Adicionar piscadas e pequenos movimentos dos olhos.

## Animações secundárias

Adicionar movimentos sutis ao cabelo, roupas e acessórios quando viável.

Não utilizar simulação física pesada desnecessariamente.

---

# 14. MOVIMENTAÇÃO E CÂMERA

Criar um controlador de terceira pessoa estável.

Implementar:

- Movimento com aceleração.
- Desaceleração.
- Corrida.
- Pulo.
- Agachamento.
- Natação quando aplicável.
- Colisão correta.
- Interações.
- Câmera rotacionável.
- Zoom.
- Colisão da câmera.
- Sensibilidade ajustável.
- Remapeamento de controles.

Evitar:

- Personagem atravessando paredes.
- Personagem caindo pelo terreno.
- Câmera atravessando objetos.
- Movimento travado.
- Deslizamento excessivo.
- Problemas em rampas e escadas.

---

# 15. CLIMA DINÂMICO

Criar:

- Sol.
- Nuvens.
- Céu limpo.
- Céu nublado.
- Chuva fraca.
- Chuva forte.
- Tempestades.
- Relâmpagos.
- Trovões.
- Neblina.
- Vento.
- Temperatura.
- Dia e noite.

Utilizar transições suaves.

Sincronizar o clima pelo servidor.

Os efeitos gráficos podem variar conforme o preset, mas as regras de sobrevivência devem ser iguais para todos.

---

# 16. DANO DE CHUVA — REGRA EXATA

Vida máxima:

**100 HP.**

O jogador poderá permanecer exposto à chuva durante os primeiros **40 segundos sem sofrer dano**.

Depois desses 40 segundos, perderá:

**1 HP a cada 15 segundos adicionais de exposição contínua.**

Tabela obrigatória:

| Exposição contínua | Vida, sem outras alterações |
|---|---|
| 0 segundos | 100 |
| 20 segundos | 100 |
| 40 segundos | 100 |
| 55 segundos | 99 |
| 70 segundos | 98 |
| 85 segundos | 97 |
| 100 segundos | 96 |

Implementar os intervalos corretamente.

Não aplicar 1 HP de dano imediatamente ao completar 40 segundos.

O primeiro dano ocorrerá aos 55 segundos.

## Proteção

Impedir exposição ao entrar em:

- Casas com telhado válido.
- Abrigos realmente cobertos.
- Cavernas.
- Outras estruturas que ofereçam cobertura real.

Verificar geometria acima do jogador.

Não basta estar perto de uma construção.

Ao ficar protegido, reiniciar o contador de exposição.

Quando voltar à chuva, iniciar novamente os 40 segundos.

Toda a lógica deverá ser validada pelo servidor.

---

# 17. REGENERAÇÃO DE VIDA

Quando estiver seguro e sem receber dano, recuperar:

**1 HP a cada 3 segundos.**

Não ultrapassar 100 HP.

Após sofrer dano, aplicar um intervalo de segurança antes de iniciar a regeneração.

Definir esse intervalo de maneira configurável, com valor inicial sugerido de 6 segundos.

Não regenerar enquanto estiver sofrendo dano ativo.

O servidor controla o sistema.

---

# 18. SOBREVIVÊNCIA COMPLETA

Implementar:

- Vida.
- Fome.
- Sede.
- Temperatura.
- Frio.
- Coleta.
- Caça.
- Alimentação.
- Água potável.
- Cozimento.
- Descanso.
- Morte.
- Reaparecimento.

Equilibrar as taxas de consumo para que a sobrevivência seja interessante, sem ser excessivamente punitiva.

Fogueiras deverão cozinhar alimentos e fornecer aquecimento quando apropriado.

---

# 19. INVENTÁRIO

Criar:

- Slots.
- Ícones.
- Pilhas.
- Divisão de pilhas.
- Arrastar e soltar.
- Transferência.
- Equipamentos.
- Barra rápida.
- Recipientes.
- Descarte.
- Durabilidade.
- Descrições.

O servidor deve validar todas as transações relevantes.

Impedir duplicação de itens.

Testar reconexões e salvamentos durante transferências.

---

# 20. FABRICAÇÃO

Implementar receitas para:

- Ferramentas.
- Armas.
- Armaduras.
- Fogueiras.
- Bancadas.
- Fornalhas.
- Materiais de construção.
- Recipientes.
- Itens avançados.

Mostrar recursos necessários.

Mostrar quantidade disponível.

Impedir fabricação sem materiais.

Criar evolução tecnológica coerente.

---

# 21. CONSTRUÇÃO MODULAR

Criar:

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

Implementar:

- Pré-visualização.
- Encaixe.
- Rotação.
- Validação.
- Colisão.
- Durabilidade.
- Reparos.
- Melhorias.
- Demolição autorizada.
- Permissões.
- Persistência.

Os telhados devem realmente impedir o dano da chuva.

Não permitir construções inválidas que causem problemas graves de física.

---

# 22. ANIMAIS

Criar:

- Coelho.
- Veado.
- Javali.
- Raposa.
- Lobo.
- Urso.

Cada animal deverá possuir:

- Modelo.
- Esqueleto quando necessário.
- Animações.
- Vida.
- Velocidade.
- Comportamento.
- Percepção.
- Navegação.
- Reação a ameaças.
- Ataques quando aplicável.
- Morte.
- Recursos coletáveis.

Animais pacíficos devem fugir.

Predadores devem perseguir quando apropriado.

Evitar animais atravessando obstáculos.

## Dano

Animais comuns:

**5 a 10 HP por ataque.**

O mais forte:

**Normalmente 10 HP.**

Ataque especial raro:

**Até 20 HP.**

Nenhum ataque individual de animal poderá ultrapassar 20 HP.

Implementar intervalos entre ataques e validação no servidor.

---

# 23. MINERAÇÃO E FUNDIÇÃO

Criar depósitos de:

- Pedra.
- Carvão.
- Cobre.
- Estanho.
- Ferro.
- Prata.
- Ouro.
- Enxofre.
- Minérios raros.

Implementar:

- Picaretas.
- Resistência de depósitos.
- Quantidade de recursos.
- Animações.
- Sons.
- Partículas.
- Respawn configurável.
- Fornalhas.
- Lingotes.
- Progressão tecnológica.

---

# 24. ARMAS E ARMADURAS

Criar:

- Lanças.
- Clavas.
- Machados.
- Espadas de pedra.
- Espadas de cobre.
- Espadas de bronze.
- Espadas de ferro.
- Espadas de aço.
- Espadas avançadas.
- Arcos.
- Flechas.
- Escudos.

Armaduras:

- Couro.
- Ossos.
- Cobre.
- Bronze.
- Ferro.
- Aço.
- Materiais avançados.

Implementar atributos reais de:

- Dano.
- Defesa.
- Durabilidade.
- Peso quando aplicável.
- Requisitos de fabricação.

Equipamentos devem aparecer visualmente no personagem.

---

# 25. COMBATE

Implementar:

- Ataque leve.
- Ataque pesado.
- Bloqueio.
- Defesa com escudo.
- Esquiva.
- Arcos e flechas.
- Sons de impacto.
- Animações.
- Efeitos.
- Reações a dano.

O servidor deverá validar:

- Alcance.
- Intervalo.
- Dano.
- Estado do jogador.
- Equipamento.
- Permissões PvP.

Impedir ataques impossíveis e spam de comandos.

---

# 26. SISTEMA DE TRIBOS

Criar:

- Fundação de tribo.
- Nome.
- Convites.
- Entrada.
- Saída.
- Expulsão.
- Liderança.
- Promoções.
- Permissões.
- Construções compartilhadas.
- Administração de integrantes.

O fundador será o rei/líder inicial.

## Fogo amigo

**Jogadores da mesma tribo não podem causar dano uns aos outros.**

## Saída voluntária

Ao sair da tribo, iniciar proteção bilateral de **5 minutos** entre o jogador e seus antigos companheiros.

Durante esse período:

- O jogador não poderá causar dano aos antigos companheiros.
- Os antigos companheiros não poderão causar dano a ele.

**Essa proteção não se aplica a jogadores de fora dessa relação.**

## Expulsão

Quando o líder expulsar um jogador, aplicar os mesmos cinco minutos de proteção bilateral entre o expulso e os membros da antiga tribo.

Não bloquear combate contra terceiros.

A proteção deverá sobreviver à reconexão.

Utilizar identificadores persistentes e tempo confiável do servidor.

Não permitir contornar a regra trocando de tribo.

---

# 27. MULTIPLAYER

Preservar a arquitetura autoritativa.

Implementar ou aprimorar:

- Servidores dedicados.
- Conexão por IP.
- Lista de jogadores.
- Sincronização de movimento.
- Interpolação.
- Inventário.
- Combate.
- Construções.
- Animais.
- Clima.
- Tribos.
- Salvamentos.
- Reconexões.
- Chat.
- Comunicação por voz.

Não permitir que clientes escolham livremente vida, recursos, dano ou permissões.

Validar comandos no servidor.

Evitar enviar estados completos desnecessariamente.

Aplicar sincronização espacial quando apropriado.

---

# 28. CHAT DE TEXTO COMPLETO

Criar canais de texto:

- Global.
- Local.
- Privado.
- Grupo.
- Tribo.
- Entre tribos.
- Aliança, quando aplicável.

## Interface

Adicionar:

- Histórico.
- Abas.
- Seleção de canal.
- Campo de texto.
- Notificações.
- Mensagens não lidas.
- Horário.
- Rolagem.
- Minimização.
- Transparência ajustável.

## Comandos

Implementar:

`/global`

`/local`

`/tribo`

`/msg`

`/grupo`

`/ajuda`

Validar destinatários, permissões e participantes.

Criar proteção contra spam.

Adicionar bloqueio e silenciamento de jogadores.

---

# 29. CHAT DE VOZ COMPLETO

**NÃO CRIAR APENAS UM BOTÃO DE MICROFONE.**

Implementar captura, codificação, transmissão, recepção, decodificação e reprodução reais de voz.

## Voz por proximidade

O canal principal de voz deverá funcionar por distância.

Configuração inicial sugerida:

| Distância | Resultado |
|---|---|
| 0–5 m | Voz clara |
| 5–15 m | Atenuação gradual |
| 15–25 m | Voz baixa |
| 25–30 m | Quase inaudível |
| Acima de 30 m | Inaudível |

Usar atenuação contínua.

Adicionar áudio posicional 3D.

Jogadores à esquerda devem ser percebidos à esquerda, conforme as capacidades do sistema de áudio.

Jogadores distantes não devem ser audíveis no canal local.

## Canais remotos

Adicionar:

- Voz privada.
- Voz de grupo.
- Voz da tribo.
- Voz entre líderes.
- Voz diplomática.
- Voz de aliança, quando aplicável.

Esses canais remotos deverão ser separados da voz local.

O jogador deverá saber qual canal está utilizando.

Não permitir ouvir conversas de canais não autorizados.

## Configurações

Adicionar:

- Ativar/desativar voz.
- Selecionar microfone.
- Selecionar saída quando suportado.
- Volume de voz.
- Volume por jogador.
- Push-to-Talk.
- Ativação por voz.
- Sensibilidade.
- Teste de microfone.
- Supressão de ruído quando viável.
- Cancelamento de eco quando viável.
- Silenciar jogadores.
- Bloquear jogadores.

Tecla padrão sugerida:

**V para falar.**

Permitir remapeamento.

Não capturar nem transmitir áudio sem o consentimento e a ativação necessários.

## Engenharia de rede

Utilizar tecnologia apropriada de baixa latência, preferencialmente com codec Opus ou solução equivalente compatível.

Implementar:

- Buffer de jitter.
- Tratamento de perda de pacotes.
- Limites de banda.
- Controle de canais.
- Validação de identidade.
- Proteção contra pacotes inválidos.
- Roteamento apenas aos destinatários autorizados.

Não deixar a transmissão de voz bloquear o tráfego crítico de movimentação e combate.

Não improvisar criptografia própria.

Não gravar conversas por padrão.

---

# 30. INTERAÇÃO SOCIAL

Ao selecionar outro jogador, disponibilizar:

- Enviar mensagem.
- Convidar para grupo.
- Convidar para tribo, quando autorizado.
- Solicitar conversa privada de voz.
- Silenciar.
- Bloquear.
- Consultar perfil público.

Chamadas privadas devem exigir aceitação.

Não ativar automaticamente o microfone ao receber convites.

---

# 31. ÁUDIO COMPLETO DO JOGO

Criar e integrar recursos sonoros reais.

Não adicionar referências a arquivos inexistentes.

## Passos

Diferenciar:

- Terra.
- Grama.
- Areia.
- Madeira.
- Pedra.
- Água rasa.

Sincronizar sons com as animações.

## Ambiente

Criar:

- Vento.
- Pássaros.
- Insetos.
- Folhas.
- Água corrente.
- Florestas.
- Cavernas.
- Sons noturnos.

## Clima

Criar:

- Chuva fraca.
- Chuva forte.
- Trovões.
- Vento intenso.
- Pingos em telhados.
- Tempestades.

## Fogueira

Criar:

- Acendimento.
- Crepitação.
- Estalos.
- Extinção.

## Ações

Criar:

- Mineração.
- Corte de madeira.
- Coleta.
- Construção.
- Fabricação.
- Portas.
- Ataques.
- Bloqueios.
- Flechas.
- Equipamentos.

## Personagens

Criar vocalizações originais e discretas para:

- Respiração.
- Cansaço.
- Frio.
- Ataques.
- Dano.
- Surpresa.

## Interface

Criar sons sutis para:

- Botões.
- Confirmações.
- Erros.
- Inventário.
- Convites.
- Mensagens.

---

# 32. MÚSICA

Criar uma identidade musical original.

Adicionar temas para:

- Menu principal.
- Criação de personagem.
- Exploração.
- Floresta.
- Noite.
- Combate.
- Perigo.

Utilizar uma estética musical coerente com o universo pré-histórico estilizado.

Não copiar trilhas de jogos ou filmes.

Criar transições suaves.

Utilizar apenas áudio original ou com licenças apropriadas.

Se não houver ferramentas para gerar música de qualidade, registrar a pendência honestamente.

---

# 33. ÁUDIO ESPACIAL E DESEMPENHO

Utilizar os recursos apropriados do Godot para áudio 3D.

Implementar:

- Atenuação.
- Posicionamento.
- Priorização.
- Limite de sons simultâneos.
- Redução de reprodução desnecessária.
- Volume por categoria.

Separar barramentos:

- Geral.
- Música.
- Ambiente.
- Efeitos.
- Interface.
- Vocalizações.
- Chat de voz.

Evitar que o áudio prejudique FPS ou estabilidade.

---

# 34. SISTEMA DE IDIOMAS

Criar idiomas:

- Português (Brasil).
- English.
- Español.
- Français.
- Deutsch.
- 日本語.

Na primeira inicialização, mostrar uma tela de escolha de idioma.

A escolha deverá ser salva.

Não perguntar novamente em todas as inicializações.

Adicionar a opção:

**Configurações → Idioma.**

Traduzir:

- Menus.
- Inventário.
- Fabricação.
- Construção.
- Tribos.
- Configurações.
- Mensagens do sistema.
- Notificações.
- Tutoriais.
- Textos de interação.
- Configurações de chat.

Não traduzir automaticamente mensagens escritas por jogadores.

Preservar nomes personalizados.

Verificar suporte a Unicode e fontes japonesas.

Não deixar textos cortados.

---

# 35. INSTALADOR WINDOWS PROFISSIONAL

**CRIAR UM INSTALADOR WINDOWS SIMPLES, BONITO E FUNCIONAL.**

Nome sugerido:

**TribesOfFire-Setup-1.0.0.exe**

Utilizar Inno Setup ou outra tecnologia madura e adequada.

## Idioma do instalador

Ao abrir, permitir escolher:

- Português.
- Inglês.
- Espanhol.
- Francês.
- Alemão.
- Japonês.

Usar traduções reais.

## Fluxo

1. Escolher idioma.
2. Boas-vindas.
3. Escolher pasta.
4. Opções adicionais.
5. Instalação.
6. Conclusão.

Não adicionar etapas técnicas desnecessárias.

## Área de trabalho

**Criar atalho funcional na área de trabalho.**

Nome:

**Tribes of Fire.**

Utilizar o ícone do jogo.

A opção deverá estar marcada por padrão e poderá ser desativada.

## Menu Iniciar

Criar entrada no menu Iniciar.

## Atualização

Permitir instalar uma versão nova sobre a anterior sem destruir os salvamentos.

## Desinstalação

Criar desinstalador.

Registrar corretamente o aplicativo no Windows.

Preservar os salvamentos por padrão.

## Permissões

Preferir instalação por usuário quando apropriado, sem exigir administrador.

## Conclusão

Exibir opção:

**Iniciar Tribes of Fire agora.**

O executável deverá abrir diretamente no menu principal.

---

# 36. REVISÃO COMPLETA DO INSTALADOR

Não basta gerar o arquivo.

Verificar:

- Se o instalador abre.
- Se o idioma muda.
- Se as etapas funcionam.
- Se todos os arquivos são copiados.
- Se o executável está presente.
- Se o atalho funciona.
- Se o ícone está correto.
- Se o jogo abre pelo atalho.
- Se o jogo abre pelo menu Iniciar.
- Se o jogo abre pela pasta de instalação.
- Se os recursos são carregados.
- Se o desinstalador funciona.
- Se uma atualização preserva dados.
- Se a instalação funciona em caminhos com espaços.

Quando houver ambiente Windows disponível, executar esses testes no Windows real ou em máquina virtual adequada.

Se não houver, criar scripts de teste e registrar a validação como pendente.

Não declarar a instalação validada sem executá-la.

---

# 37. SALVAMENTO E PERSISTÊNCIA

Salvar corretamente:

- Personagens.
- Aparência.
- Inventário.
- Equipamentos.
- Construções.
- Tribos.
- Permissões.
- Estado do mundo.
- Recursos persistentes.
- Configurações.
- Preferência de idioma.

Utilizar identificadores estáveis.

Implementar salvamento periódico.

Implementar salvamento seguro no encerramento.

Evitar corrupção em desligamentos inesperados.

Utilizar gravações atômicas ou alternativas apropriadas.

Criar backups quando viável.

Testar atualização de versão e migração de dados.

---

# 38. REVISÃO DE SEGURANÇA MULTIPLAYER

Investigar:

- Duplicação de itens.
- Ataques impossíveis.
- Teletransporte indevido.
- Velocidade inválida.
- Recursos fabricados sem materiais.
- Construções não autorizadas.
- Acesso indevido a inventários.
- Acesso indevido a canais de voz.
- Acesso indevido a chats privados.
- Manipulação de tribos.
- Contorno de proteções PvP.
- Comandos excessivos.
- Pacotes inválidos.

Aplicar validação no servidor.

Não confiar no cliente como autoridade sobre regras de jogo.

---

# 39. REVISÃO DE DESEMPENHO

Criar um sistema de medição.

Cenários obrigatórios:

1. Mundo aberto.
2. Floresta densa.
3. Base construída.
4. Chuva forte.
5. Noite.
6. Múltiplas fogueiras.
7. Vários animais.
8. Múltiplos jogadores.
9. Combate multiplayer.
10. Chat de voz ativo.
11. Vários personagens personalizados.
12. Inventário e construção em uso.

Medir, quando possível:

- FPS médio.
- Tempo de frame.
- Percentil 1% low.
- Uso de CPU.
- Uso de memória.
- Uso de GPU.
- Uso de VRAM.
- Tráfego de rede.
- Latência.
- Consumo do sistema de áudio.

Não inventar dados.

Se o FPS estiver baixo, investigar o gargalo antes de reduzir gráficos.

---

# 40. MATRIZ DE TESTES WINDOWS

Testar, quando houver acesso ao ambiente correspondente:

| Ambiente | Testes prioritários |
|---|---|
| Windows 11 64 bits | Instalação, execução e multiplayer |
| Windows 10 64 bits | Instalação, execução e compatibilidade |
| GPU antiga compatível | Renderizador e preset Médio |
| Hardware mais moderno | Presets Alto e Ultra |
| Sem microfone | Tratamento de dispositivo ausente |
| Com microfone | Chat de voz real |
| Sem internet | Mensagem de erro e modo disponível |
| Internet instável | Reconexão e recuperação |
| Resolução 720p | Menus e jogabilidade |
| Resolução 1080p | Menus e jogabilidade |

Não presumir que uma GPU suporta determinados recursos apenas por seu nome.

Verificar capacidades reais da plataforma e do renderizador.

---

# 41. TESTES DE REGRESSÃO

Ao implementar funcionalidades novas, executar novamente os testes antigos.

Verificar se:

- O clima continua funcionando.
- O dano da chuva permanece correto.
- A construção continua funcionando.
- O inventário não perde itens.
- O combate permanece equilibrado.
- As tribos continuam funcionando.
- O multiplayer não foi quebrado.
- A câmera continua estável.
- As animações não causam erros.
- As configurações são salvas.
- O chat não interrompe o jogo.
- O áudio não causa travamentos.
- O instalador inclui todos os recursos.

Corrigir regressões antes de considerar uma fase concluída.

---

# 42. AUDITORIA DE TODOS OS ARQUIVOS

Procurar:

- Scripts incompletos.
- Funções vazias.
- TODOs críticos.
- Variáveis não utilizadas.
- Referências inválidas.
- Recursos ausentes.
- Cenas quebradas.
- Nomes inconsistentes.
- Dependências não documentadas.
- Problemas de importação.
- Arquivos duplicados.
- Erros de tipagem.
- Problemas de sinais.
- Erros de inicialização.
- Condições de corrida.
- Problemas de sincronização.
- Vazamentos de memória.
- Uso excessivo de processamento.
- Problemas de salvamento.
- Problemas de exportação.

Não remover automaticamente TODOs úteis sem resolver a funcionalidade correspondente.

---

# 43. ARQUITETURA MODULAR

Refatorar gradualmente o projeto.

Separar:

- Mundo.
- Clima.
- Jogador.
- Câmera.
- Personalização.
- Animações.
- Áudio.
- Vida.
- Sobrevivência.
- Inventário.
- Fabricação.
- Construção.
- Animais.
- Mineração.
- Combate.
- Tribos.
- Chat de texto.
- Chat de voz.
- Rede.
- Persistência.
- Idiomas.
- Configurações.
- Interface.
- Diagnósticos.
- Exportação.

Evitar concentrar tudo em `Main.gd`.

Não quebrar compatibilidade desnecessariamente durante a refatoração.

---

# 44. AUTOMAÇÃO DA COMPILAÇÃO

Criar scripts reproduzíveis para gerar as versões do jogo.

Preferir um fluxo automatizado que:

1. Verifique dependências.
2. Verifique o projeto.
3. Execute testes.
4. Importe recursos.
5. Exporte o jogo Windows.
6. Verifique os arquivos gerados.
7. Monte a versão portátil.
8. Gere o instalador.
9. Produza hashes dos artefatos.
10. Gere um relatório final.

Utilizar versões controladas das ferramentas.

Não esconder falhas de comandos.

O processo deverá encerrar com erro quando uma etapa crítica falhar.

Não publicar um instalador se a exportação do jogo falhar.

---

# 45. TESTE DO JOGO FORA DO EDITOR

Este ponto é obrigatório.

**TESTAR O JOGO EXPORTADO, NÃO APENAS O PROJETO ABERTO NO GODOT.**

Verificar:

- Menu principal.
- Seleção de idioma.
- Criação de personagem.
- Entrada no mundo.
- Movimentação.
- Câmera.
- Inventário.
- Construção.
- Combate.
- Animais.
- Chuva.
- Áudio.
- Chat.
- Multiplayer.
- Salvamento.
- Saída do jogo.
- Nova inicialização.

Muitos erros aparecem apenas depois da exportação.

Não considerar testes do editor como prova de que a versão Windows funciona.

---

# 46. TESTES MULTIPLAYER REAIS

Executar pelo menos os cenários possíveis com:

- Um servidor.
- Dois clientes.
- Três ou mais clientes, quando viável.

Testar:

- Entrada simultânea.
- Movimentação.
- Coleta.
- Inventário.
- Construção.
- Combate.
- Tribos.
- Expulsão.
- Saída voluntária.
- Proteção de cinco minutos.
- Chat privado.
- Chat de grupo.
- Chat de tribo.
- Chat entre tribos.
- Voz por proximidade.
- Voz remota.
- Desconexão.
- Reconexão.
- Persistência.

Não simular o sucesso de um teste que não foi realmente realizado.

---

# 47. TESTES DE CHUVA E VIDA

Criar testes automatizados com relógio controlado para verificar:

- Nenhum dano antes dos 40 segundos.
- Nenhum dano exatamente aos 40 segundos.
- Primeiro dano após 55 segundos.
- Segundo dano aos 70 segundos.
- Proteção sob telhado.
- Proteção em caverna.
- Reinício da exposição após abrigo.
- Regeneração a cada 3 segundos quando permitida.
- Vida nunca acima de 100.
- Vida nunca abaixo do limite definido pelo jogo.

Esses testes não devem depender de esperar minutos reais.

---

# 48. TESTES DE TRIBOS

Testar:

- Dois membros na mesma tribo.
- Fogo amigo bloqueado.
- Saída voluntária.
- Expulsão.
- Proteção bilateral.
- Exatamente cinco minutos.
- Proteção encerrada após o prazo.
- Ataques contra terceiros ainda permitidos.
- Desconexão.
- Reconexão.
- Troca de tribo.
- Reinicialização do servidor.

Não permitir que a proteção bloqueie indevidamente o combate de todo o servidor.

---

# 49. TESTES DE PERSONALIZAÇÃO

Verificar:

- Todas as opções modificam o personagem.
- Olhos aparecem corretamente.
- Cores dos olhos funcionam.
- Cabelos funcionam.
- Altura funciona.
- Roupas aparecem.
- O modelo não fica deformado.
- O esqueleto funciona.
- As animações continuam corretas.
- A colisão permanece equilibrada.
- Outros jogadores enxergam a aparência.
- A aparência persiste após reconexão.

---

# 50. TESTES DE CHAT E VOZ

Verificar:

- Mensagens globais.
- Mensagens locais.
- Mensagens privadas.
- Mensagens de tribo.
- Mensagens de grupo.
- Comunicação diplomática.
- Bloqueios.
- Permissões.
- Microfone.
- Push-to-Talk.
- Seleção de dispositivos.
- Volume.
- Atenuação.
- Posicionamento 3D.
- Distância máxima.
- Reconexão.
- Perda de pacotes.
- Latência.
- Consumo de CPU.
- Consumo de banda.

Se não houver microfone disponível no ambiente de teste, utilizar sinais de áudio de teste para verificar o pipeline e registrar a necessidade de validação física.

---

# 51. INTERFACE E EXPERIÊNCIA DE USO

Revisar todas as telas.

Garantir:

- Textos legíveis.
- Botões funcionais.
- Layout consistente.
- Feedback de ações.
- Navegação simples.
- Resoluções diferentes.
- Compatibilidade com mouse e teclado.
- Traduções corretas.
- Ausência de elementos sobrepostos.
- Ausência de textos cortados.

Não manter botões que não fazem nada.

Não apresentar opções desativadas como se estivessem funcionais.

---

# 52. TRATAMENTO DE ERROS AMIGÁVEL

Quando ocorrer um erro recuperável, mostrar mensagens claras.

Exemplos:

- Não foi possível conectar ao servidor.
- O servidor está indisponível.
- O microfone não foi encontrado.
- Não há permissão para usar o microfone.
- Não foi possível carregar o salvamento.
- Não foi possível aplicar a resolução.
- A configuração gráfica não é compatível.
- A conexão foi perdida.

Não mostrar apenas códigos técnicos ao jogador.

Registrar detalhes técnicos nos logs.

---

# 53. QUALIDADE DE CÓDIGO

Exigir:

- Código organizado.
- Tipagem adequada quando útil.
- Separação de responsabilidades.
- Comentários úteis.
- Erros tratados.
- Recursos carregados corretamente.
- Sem dependências circulares desnecessárias.
- Sem processamento pesado no frame principal sem necessidade.
- Sem operações bloqueantes de disco ou rede durante a jogabilidade.
- Sem variáveis globais desnecessárias.
- Sem duplicação evidente de lógica.
- Sem dependências abandonadas sem justificativa.

Priorizar manutenção e estabilidade.

---

# 54. CONTROLE DE VERSÃO

Registrar as alterações de maneira organizada.

Criar commits por conjuntos coerentes de funcionalidades.

Não fazer commits com arquivos temporários desnecessários.

Não incluir credenciais.

Não incluir chaves privadas.

Não incluir dados pessoais de testes.

Atualizar documentação continuamente.

---

# 55. QUINZE GRANDES FASES DE FINALIZAÇÃO

Reorganize as tarefas nas seguintes fases, conciliando com a estrutura original do projeto.

## Fase 1 — Auditoria geral

Verificar código, cenas, recursos, dependências, testes e exportações.

## Fase 2 — Estabilidade e arquitetura

Corrigir problemas estruturais e modularizar sistemas.

## Fase 3 — Windows e inicialização

Garantir exportação, caminhos corretos, carregamento e diagnósticos.

## Fase 4 — Mundo e gráficos

Melhorar cenários, iluminação, água, vegetação e identidade visual.

## Fase 5 — Otimização

Implementar presets, LOD, culling, gerenciamento de recursos e testes de desempenho.

## Fase 6 — Personagens

Criar modelos estilizados, roupas, personalização e persistência.

## Fase 7 — Animações

Finalizar movimentação, expressões, combate e interações.

## Fase 8 — Sobrevivência

Finalizar vida, chuva, frio, fome, sede e regeneração.

## Fase 9 — Inventário e construção

Finalizar fabricação, construção, telhados e salvamentos.

## Fase 10 — Animais e mineração

Criar IA, fauna, caça, minérios e fundição.

## Fase 11 — Combate e tribos

Implementar equipamentos, PvP, liderança e regras de proteção.

## Fase 12 — Multiplayer e comunicação

Finalizar rede, chat de texto, voz e canais.

## Fase 13 — Áudio, idiomas e interface

Finalizar sons, música, menus, traduções e experiência de uso.

## Fase 14 — Testes, correções e polimento

Executar testes de regressão, benchmark e validação multiplataforma disponível.

## Fase 15 — Distribuição Windows

Gerar executáveis, instalador, atalhos, desinstalador, documentação e relatórios finais.

---

# 56. CRITÉRIO DE CONCLUSÃO DE CADA FASE

Uma fase somente será considerada concluída se:

1. O código estiver implementado.
2. As cenas e recursos estiverem integrados.
3. A interface estiver funcional quando necessária.
4. O comportamento estiver correto.
5. O multiplayer funcionar quando aplicável.
6. O salvamento funcionar quando aplicável.
7. Os testes relevantes forem executados.
8. Os testes aprovados tiverem evidências.
9. Não houver erros críticos conhecidos naquela fase.
10. O progresso estiver documentado.

Não marcar como concluída uma fase com recursos principais ausentes.

---

# 57. CRITÉRIOS PARA A VERSÃO 1.0.0

Antes de declarar Tribes of Fire 1.0.0, verificar obrigatoriamente:

- O jogo abre no Windows validado.
- O menu funciona.
- O idioma funciona.
- O personagem pode ser criado.
- A aparência é salva.
- A movimentação funciona.
- As animações essenciais funcionam.
- O mundo carrega.
- A sobrevivência funciona.
- A chuva causa dano corretamente.
- Os telhados protegem.
- A vida regenera corretamente.
- O inventário funciona.
- A fabricação funciona.
- A construção funciona.
- Os animais funcionam.
- A mineração funciona.
- O combate funciona.
- As tribos funcionam.
- O multiplayer funciona.
- O chat de texto funciona.
- O chat de voz funciona.
- O áudio espacial funciona.
- O salvamento funciona.
- As configurações gráficas funcionam.
- Os recursos visuais essenciais estão presentes.
- Os recursos sonoros essenciais estão presentes.
- O instalador funciona no ambiente validado.
- O atalho da área de trabalho funciona.
- A desinstalação funciona.
- Não há falhas críticas conhecidas que impeçam a experiência principal.

Se algum desses itens estiver incompleto, não declarar a versão 1.0 finalizada.

---

# 58. RELATÓRIO DE EVIDÊNCIAS

Criar um relatório final contendo:

## Código

- Arquivos modificados.
- Sistemas implementados.
- Arquitetura resultante.
- Dependências utilizadas.

## Testes

- Quantidade de testes.
- Testes aprovados.
- Testes falhos.
- Testes não executados.
- Motivos de testes pendentes.

## Windows

- Versões realmente testadas.
- Método de execução.
- Resultado da inicialização.
- Resultado da instalação.
- Resultado da criação do atalho.
- Resultado da desinstalação.

## Desempenho

- Hardware utilizado.
- Renderizador.
- Resolução.
- Preset.
- FPS medido.
- Problemas identificados.

## Multiplayer

- Quantidade de clientes testados.
- Recursos validados.
- Problemas encontrados.
- Limitações.

## Pendências

- Funcionalidades incompletas.
- Problemas conhecidos.
- Testes físicos ainda necessários.

Não apresentar resultados estimados como medidos.

---

# 59. ARQUIVOS FINAIS

Gerar, quando tecnicamente possível:

- Instalador Windows `.exe`.
- Versão portátil Windows `.zip`.
- Executável Windows do jogo.
- Versão Linux `.zip`.
- Servidor dedicado Linux.
- Servidor dedicado Windows.
- Código-fonte completo.
- Arquivos de tradução.
- Recursos 3D.
- Animações.
- Áudio.
- Scripts de build.
- Testes.
- Documentação.
- Relatório de desempenho.
- Relatório de validação.

O instalador deverá possuir os arquivos realmente necessários para executar o jogo.

Não distribuir arquivos vazios ou exemplos falsos.

---

# 60. REGRAS ABSOLUTAS DE QUALIDADE

**REGRA 1:** Não reiniciar o projeto do zero.

**REGRA 2:** Não remover funcionalidades sem necessidade técnica.

**REGRA 3:** Não criar interfaces falsas.

**REGRA 4:** Não criar botões sem ações.

**REGRA 5:** Não afirmar que testes passaram sem executá-los.

**REGRA 6:** Não afirmar que o jogo funciona no Windows apenas porque compilou.

**REGRA 7:** Não afirmar que o instalador funciona sem testá-lo.

**REGRA 8:** Não inventar FPS.

**REGRA 9:** Não copiar conteúdo protegido de outros jogos ou filmes.

**REGRA 10:** Não comprometer o multiplayer.

**REGRA 11:** Não permitir duplicação de itens.

**REGRA 12:** Não deixar o cliente controlar danos arbitrários.

**REGRA 13:** Não quebrar as regras de tribos.

**REGRA 14:** Não modificar a regra dos 40 segundos de chuva.

**REGRA 15:** Não modificar o dano de 1 HP a cada 15 segundos após a tolerância.

**REGRA 16:** Não modificar a regeneração de 1 HP a cada 3 segundos quando permitida.

**REGRA 17:** Não transformar o jogo em fotorrealista.

**REGRA 18:** Não deixar o Médio com aparência ruim.

**REGRA 19:** Não exigir computadores modernos desnecessariamente.

**REGRA 20:** Não mostrar nomes de hardware de referência na interface.

**REGRA 21:** Não concluir recursos sem integrar cenas, modelos, áudio e scripts.

**REGRA 22:** Não ignorar erros de exportação.

**REGRA 23:** Não esconder dependências ausentes.

**REGRA 24:** Não sobrescrever salvamentos durante atualizações.

**REGRA 25:** Não declarar a versão 1.0 pronta com funcionalidades obrigatórias faltando.

---

# 61. PROCEDIMENTO DE TRABALHO AUTÔNOMO

Execute o seguinte ciclo:

**ANALISAR → IMPLEMENTAR → INTEGRAR → TESTAR → CORRIGIR → RETESTAR → DOCUMENTAR → CONTINUAR.**

Ao encontrar um erro:

1. Reproduza-o.
2. Identifique a causa.
3. Corrija a causa.
4. Execute novamente o teste.
5. Verifique regressões.
6. Registre a correção.

Não resolva erros apenas escondendo mensagens ou desativando funcionalidades.

Não passe para a distribuição final enquanto houver falhas críticas de inicialização, carregamento ou multiplayer.

Não interrompa o desenvolvimento apenas para perguntar se deve continuar quando o trabalho estiver claramente definido.

Se houver limitação real do ambiente, documente-a e avance com as tarefas possíveis.

---

# 62. TESTE FINAL DE EXPERIÊNCIA COMPLETA

Antes de declarar a versão pronta, executar o seguinte fluxo em uma build instalada no Windows, quando houver ambiente Windows disponível:

1. Abrir o instalador.
2. Escolher português.
3. Instalar.
4. Verificar o atalho na área de trabalho.
5. Abrir o jogo pelo atalho.
6. Escolher o idioma do jogo.
7. Abrir as configurações.
8. Escolher o preset Médio.
9. Criar um personagem.
10. Alterar olhos e cor dos olhos.
11. Alterar cabelo.
12. Alterar altura.
13. Escolher roupa.
14. Confirmar.
15. Entrar em um servidor.
16. Movimentar o personagem.
17. Correr e pular.
18. Coletar madeira.
19. Coletar pedra.
20. Abrir inventário.
21. Fabricar ferramenta.
22. Construir abrigo.
23. Construir telhado.
24. Testar proteção da chuva.
25. Testar regeneração.
26. Encontrar animal.
27. Testar caça e combate.
28. Minerar.
29. Utilizar fornalha.
30. Fabricar equipamento.
31. Criar tribo.
32. Convidar outro jogador.
33. Testar proteção contra fogo amigo.
34. Testar saída de tribo.
35. Testar proteção bilateral de cinco minutos.
36. Enviar mensagem privada.
37. Enviar mensagem para a tribo.
38. Testar chat global.
39. Testar voz por proximidade.
40. Testar atenuação por distância.
41. Testar canal remoto de voz.
42. Desconectar.
43. Reconectar.
44. Verificar inventário.
45. Verificar construções.
46. Verificar tribo.
47. Verificar aparência.
48. Fechar o jogo.
49. Abrir novamente.
50. Confirmar persistência.
51. Desinstalar.
52. Verificar se o processo de desinstalação terminou corretamente.
53. Confirmar que dados pessoais foram preservados conforme informado.

Documente os resultados de cada etapa.

Não marcar o teste como concluído se etapas essenciais falharem.

---

# 63. CRITÉRIO ESPECIAL: SEM PROBLEMAS NO WINDOWS

Meu objetivo é que o jogador consiga:

- Instalar facilmente.
- Abrir facilmente.
- Jogar sem configurações técnicas.
- Usar mouse e teclado.
- Ajustar os gráficos.
- Criar personagem.
- Entrar no multiplayer.
- Jogar com amigos.
- Conversar por texto e voz.
- Salvar progresso.
- Fechar e reabrir o jogo normalmente.

Trate o Windows como plataforma prioritária.

Investigue problemas de:

- Drivers gráficos.
- Renderizadores.
- Resoluções.
- Dispositivos de áudio.
- Permissões.
- Caminhos de instalação.
- Dependências.
- Arquivos de recursos.
- Bibliotecas externas.
- Firewall.
- Rede.
- Exportação.
- Instalação.

Não é possível garantir ausência absoluta de falhas em todos os computadores, portanto identifique e reduza os riscos por meio de testes, tratamento de erros, recuperação e diagnósticos.

Não utilize expressões como "100% garantido" sem evidências compatíveis.

---

# 64. RESULTADO QUE EU REALMENTE QUERO

Quero que o Tribes of Fire deixe de parecer um protótipo e passe a parecer um jogo independente de verdade.

Quero abrir o jogo e encontrar:

**Um menu principal bonito.**

**Uma tela de seleção de idioma.**

**Um editor de personagem 3D de qualidade.**

**Personagens pré-históricos baixos, carismáticos e com aparência de filme de animação.**

**Roupas primitivas bonitas, incluindo pele de onça estilizada.**

**Movimentação fluida.**

**Animações expressivas.**

**Um mundo natural bonito.**

**Boa iluminação.**

**Chuva e tempestades.**

**Sons de floresta, vento, água e animais.**

**Fogueiras iluminando os ambientes.**

**Construções reais.**

**Animais com inteligência artificial.**

**Mineração e fabricação.**

**Espadas, armaduras e combate.**

**Tribos com liderança e proteção PvP.**

**Multiplayer estável.**

**Chat de texto completo.**

**Chat de voz 3D por proximidade.**

**Comunicação privada e entre tribos.**

**Configurações gráficas completas.**

**Um preset Médio bonito e otimizado.**

**Salvamento persistente.**

**Um instalador Windows simples, com seleção de idioma e atalho na área de trabalho.**

Tudo integrado e funcionando.

---

# 65. ORDEM FINAL — EXECUTE, NÃO APENAS PLANEJE

**COMECE AGORA UMA AUDITORIA COMPLETA DO REPOSITÓRIO EXISTENTE.**

Depois:

1. Corrija erros estruturais.
2. Preserve recursos funcionais.
3. Implemente sistemas pendentes.
4. Substitua recursos provisórios por recursos definitivos quando possível.
5. Melhore os gráficos.
6. Melhore os personagens.
7. Melhore as animações.
8. Integre os sons.
9. Finalize a sobrevivência.
10. Finalize as construções.
11. Finalize os animais.
12. Finalize mineração e equipamentos.
13. Finalize combate e tribos.
14. Finalize multiplayer.
15. Finalize chat e voz.
16. Finalize idiomas.
17. Revise interfaces.
18. Otimize profundamente.
19. Execute testes.
20. Corrija regressões.
21. Exporte o jogo.
22. Gere o instalador Windows.
23. Teste o instalador onde possível.
24. Gere relatórios.
25. Documente todas as limitações.

Não pare após escrever uma lista de tarefas.

Não gere apenas projetos demonstrativos.

Não substitua sistemas reais por mensagens de sucesso falsas.

Não ignore erros para conseguir exportar.

Não entregue executáveis sem os recursos necessários.

**ENTREGUE O MÁXIMO DE IMPLEMENTAÇÃO REAL POSSÍVEL, COM ESTABILIDADE COMO PRIORIDADE.**

A versão 1.0.0 só poderá ser declarada concluída quando os requisitos obrigatórios estiverem realmente implementados e validados.

Se houver pendências, mantenha uma versão de desenvolvimento honesta e documente o que falta.

**O OBJETIVO NÃO É SOMENTE COMPILAR O TRIBES OF FIRE. O OBJETIVO É FAZER O TRIBES OF FIRE FUNCIONAR CORRETAMENTE COMO UM JOGO DE VERDADE, PRINCIPALMENTE NO WINDOWS.**
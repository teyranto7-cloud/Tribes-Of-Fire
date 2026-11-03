# Direção e critérios de continuidade

Tribes of Fire, criado por **felipealx**, é um projeto progressivo de sobrevivência
3D em terceira pessoa para Windows 10/11 e Linux x64. Godot 4.x, sem dependências
pagas obrigatórias. Não trocar de engine nem eliminar funcionalidades existentes
sem necessidade demonstrada. `PROGRESS.md` distingue implementação de intenção.

## Regras obrigatórias

- Todos os jogadores têm no máximo 100 HP, independentemente da tribo.
- Regeneração conforme auditoria final: espera padrão configurável de 6 segundos
  após dano, depois 1 HP a cada 3 segundos em condição segura. Suspender em
  combate, privação ou chuva nociva a partir de 40 segundos; teto interrompe a exposição.
- Chuva: 40 segundos completos iniciais sem dano. Primeiro dano em 55 segundos,
  depois 1 HP a cada 15 segundos contínuos: 70/85/100 e 17 HP brutos aos 300 s.
  Intensidade não modifica a taxa. O servidor controla o tempo e o dano.
  Abrigo válido ou fim da chuva reinicia a contagem; sair do abrigo dá novo
  período inicial. Aquecimento não concede imunidade física à chuva.
- Dia padrão de 30 minutos reais, noite de 15; servidor deve avançar sem jogadores
  enquanto o processo estiver ativo. Durações deverão ser configuráveis pelo admin.
- Animais comuns: 5–10 HP por ataque. Especiais perigosos podem raramente atingir
  20 HP, nunca mais de 20 em um golpe. Implementação inicial: consulte PROGRESS.md.
- Espadas: aproximadamente 10–35 HP por golpe conforme categoria/material;
  alcance, cooldown, resistência, armadura e dano validados no servidor.
- Sem dano entre membros da mesma tribo. Saída voluntária ou expulsão ativa
  proteção bidirecional de 5 minutos apenas contra a antiga tribo, persistida
  em desconexão/reconexão. Não afeta outras tribos. Implementação inicial: consulte PROGRESS.md.
- Romper aliança deve avisar globalmente e bloquear hostilidades entre as partes
  por 1 hora. Sistema ainda não implementado.

## Direção visual

Aventura estilizada, proporções humanas agradáveis, florestas coloridas com
moderação, água, montanhas e construções de madeira/pedra. Referências clássicas
de aventura são apenas atmosfera; não copiar personagens, mapas, músicas ou assets.
A prioridade de iluminação é uma cabana aconchegante numa noite chuvosa. Preservar
essa leitura com gráficos reduzidos. Efeitos mais caros devem ser configuráveis.

## Expansão, por dependência

1. Manter a base executável, testes, builds e recuperação de dados.
2. Refinar arte, animação, qualidade e iluminação; medir custo real de cada efeito.
3. Fome/sede, comida, água potável, cozimento, caça, morte, camas e respawn.
4. Completar meteorologia, abrigo, temperatura e apresentação sem alterar a regra
   obrigatória de dano. Validação física e de rede precede efeitos cosméticos.
5. IA animal com percepção, fuga, perseguição, abrigo e navegação funcional.
6. Construção modular: fundações/pisos/paredes/janelas/portas/tetos/escadas/rampas,
   cercas/portões/torres/baús/camas/bancadas/fornos; encaixe/rotação/reparo/destruição.
7. Mineração e progressão: madeira, pedra, carvão, cobre, estanho, bronze, ferro,
   prata, ouro, aço e recursos avançados; ferramentas, fundição e refino.
8. Combate e armaduras de tecido/couro/bronze/ferro/aço; arco, flechas, escudo,
   espada, lança e machado de combate. Autoridade antes de PvP público.
9. Evoluir multiplayer a partir de dois jogadores reais: senha, reconexão segura,
   lista, animação, combate, relevância de rede, abuso e testes de latência/carga.
10. Tribos, líder/rei, convites, permissões, bandeira, território, diplomacia,
    comércio, guerras, cercos e estruturas defensivas; testar proteções acima.
11. Expandir mundo por seed, regiões e biomas: continente cercado pelo mar,
    florestas/campos/montanhas/vales/praias/pântanos/rios/lagos/cachoeiras/cavernas/
    ruínas/minas/ilhas. Barcos e jangadas. Modificações determinísticas persistidas.
12. Interface funcional PT-BR/EN/ES/FR/DE/JA para os sistemas implementados; acessibilidade
    e controles remapeáveis. Não criar telas que simulem funcionalidades ausentes.
13. Streaming, LOD, instancing, occlusion, pooling, IA por distância, limites de
    luzes, colisões, CPU/GPU/memória e rede. Referência: Ryzen 5 4600G/16GB/1080p,
    meta aproximada de 60 FPS baixo/médio, somente comprovada por benchmark real.
14. Persistência transacional/journal, backups e recuperação após crash/energia,
    prevenção de concorrência e migrações. Snapshots atuais não completam esta fase.
15. Builds e instaladores testados em Windows/Linux reais, servidor dedicado,
    Steamworks opcional e preparação de publicação Steam com licenças completas.

Referências de escala: continente inicial planejado de cerca de 12 × 12 km,
5–6 tribos com territórios extensos e até 100 jogadores simultâneos configuráveis.
Essas são metas a validar, não capacidades comprovadas da versão atual.

Os quatro prompts posteriores estão preservados integralmente em Docs/REQUEST_*.md.
A auditoria final tem precedência em regras de segurança da regeneração e nos
critérios que impedem declarar 1.0 sem concluir e validar todos os itens obrigatórios.

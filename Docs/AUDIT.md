# Auditoria de escopo — 0.3.1-dev

Requisitos de origem preservados em REQUEST_V2.md, REQUEST_COMMUNICATION.md,
REQUEST_CHARACTERS.md e REQUEST_AUDIT_FINAL.md. O último prompt permite uma versão
de desenvolvimento honesta quando restarem itens obrigatórios; estes itens
impedem declarar 1.0. Criador: felipealx.

| Área | Implementação real nesta entrega | O que falta para o escopo completo |
|---|---|---|
| Continuidade | Base 0.1/0.2 preservada, cena e scripts executáveis | Refinamento contínuo e validação comercial |
| Personagem | Aparência validada/persistida, 18 parâmetros, nove estilos de cabelo, seis barbas, materiais/roupa original, Skeleton3D de nove ossos | Modelagem final, morphs refinados, mãos/dedos, AnimationTree e animações produzidas para cada ação, acabamento cinematográfico |
| Câmera/controles | Terceira pessoa, SpringArm, zoom, suavização, sensibilidade, remapeamento, corrida/pulo/agachamento/esquiva | Controle/gamepad completo, acessibilidade e revisão de conflitos de teclas |
| Mundo | Seed fixa 1337, terreno com colisão, floresta, grama/água/nuvens, LOD e instancing | Seed/tamanho selecionáveis, biomas/continente, streaming, rios/cavernas/ilhas, barcos, agricultura e terreno editável |
| Iluminação | Sol/lua, amanhecer/pôr do sol, sombras, fogo, relâmpagos, material de água escalável | GI, volumetria validada em Forward+, reflexos avançados, arte final e benchmark em GPU real |
| Clima | Limpo/nublado/chuva leve/forte/tempestade/neblina, transições, vento, áudio e trovões atrasados | Poças, interiores complexos, roupa/clima por bioma e calibração artística completa |
| Chuva | Proteção até 40 s, primeiro dano em 55 s, 1/15 s; teto/fim da chuva reiniciam; servidor aplica | Teste humano longo e ambientes com múltiplos andares |
| Vida | 100 HP, espera padrão 6 s após dano, 1/3 s seguro, suspensão sob condições nocivas | Balanceamento de campanha/PvP com usuários |
| Sobrevivência | Fome/sede, carne/frutas, fonte potável, cozinhar perto de fogo, morte/respawn | Camas, pontos selecionáveis, armazenamento e produção sustentáveis de alimentos |
| Inventário | 36 espaços, pilhas/divisão/arrastar, equipar/comer/descartar/recuperar, transações atômicas, save | Ícones finais, barra rápida completa, recipientes/baús, peso e ergonomia final; durabilidade é compartilhada por tipo de item |
| Construção | Fogueira, abrigo com teto físico, bancada e fornalha, custo/colisão/validação/save | Fundações/pisos/paredes/portas/janelas/escadas/rampas/cercas/torres/baús/camas, encaixe/rotação, reparo/dano/destruição, propriedade territorial |
| Recursos | 22 depósitos/coletáveis, ferramentas e fundição cobre/bronze/ferro/aço, receitas de equipamentos | Distribuição por bioma e regeneração; depósitos têm oito unidades finitas, prata/ouro/enxofre/minério raro ainda sem cadeia completa |
| Animais | 12 animais/seis espécies, navegação em grade, fuga/perseguição/retorno, ataque com aviso, teto 20 HP e loot único | Comer/dormir/abrigo climático elaborados, respawn, biomas, ecologia e animação final |
| Combate | Armas, escudo/armaduras, alcance/oclusão, stamina/cooldown, mitigação, esquiva e PvP validados | Projéteis físicos de flecha, compensação de latência, animações finais e balanceamento multiplayer extensivo |
| Tribos | Criar/convidar/aceitar/sair/expulsar/transferir líder, bloqueio aliado, 300 s bilaterais persistidos | Bandeiras, oficiais/permissões finas, territórios, alianças, tratado, guerra, espera de 1 h após rompimento, cercos/catapultas |
| Rede | ENet autoritativo, host, conexão IP, dedicado, interpolação, reconexão, validação e limites de frequência | Senha, servidor público/listagem, autenticação/criptografia comercial, predição, relevância e prova de 100 jogadores; snapshots ainda incluem inventários de outros jogadores |
| Texto | Seis canais, filtro de participantes por servidor, grupos/convites, histórico limitado, comandos, bloqueio | Revisão de UX, moderação/administração e escalabilidade pública |
| Voz | Captura Godot opt-in, ADPCM real, ENet separado, decode/playback, proximidade 30 m e salas remotas, aceite, mudo/bloqueio/volume | Opus, eco/ruído, testes com pessoas/microfones/dispositivos reais, segurança comercial e rede adversa |
| Idiomas | Seis catálogos com 233 entradas, seleção inicial/persistência/troca, fonte japonesa | Revisão nativa de toda a tradução e migração dos últimos erros técnicos legados |
| Áudio | 20 WAV originais, música por estado/crossfade, passos, sons espaciais, buses e volumes | Mixagem profissional, paisagem sonora ampla, variação de passos em todas as construções e calibração com fones |
| Otimização | MultiMesh, LOD, consolidação de malhas por material, budgets de luz/partículas, IA distante, painel e medição | Streaming, occlusion por regiões, protocolo por relevância, profiling CPU/GPU completo e hardware alvo |
| Persistência | v3, migrações, checksum, slots alternados, lock concorrente, SIGKILL e recuperação explícita | Banco transacional/journal/WAL, durabilidade de energia, backups externos automáticos e recuperação segura sem intervenção |
| Distribuição | Windows/Linux/dedicado exportáveis, ZIPs/código-fonte, NSIS multilíngue Unicode, hashes | Windows 10/11 executados realmente, assinatura digital, matriz de hardware e publicação/Steamworks |

As telas exibem ações implementadas. Não foram criados botões de territórios,
Steam, alianças ou outras funções ausentes para simular conclusão.

## Critérios de liberação

Antes de 1.0: concluir as dependências da tabela, validar Windows 10 e 11 e Linux
em máquinas reais, medir hardware de referência, testar voz física e rede com
latência/perda, reforçar identidade/transporte/persistência e executar testes de
carga. Os executáveis atuais têm versão 0.3.1-dev. Exportar não certifica essas metas.

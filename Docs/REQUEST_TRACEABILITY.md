# Pedidos da conversa × implementação real — 0.8.0-dev

Tribes of Fire · criado por **felipealx**. Continuação de `185a463`, preservado em
`checkpoint/pre-0.8-185a463`. Godot 4.6.3, Compatibility, cena `Scenes/Main.tscn` e
saves versão 4 mantidos. Os nove anexos da conversa foram recuperados e comparados
com os módulos atuais; os prompts de Fases 1–3 e requisitos transversais também
orientam esta matriz. Não se trata de aprovação integral do jogo final.

| Pedido | Estado real / onde verificar |
|---|---|
| Não reiniciar nem entregar só gerador | Atendido: mesmo projeto, código/recursos reais, histórico e pacotes anteriores preservados |
| Corrigir partes desaparecendo nos modelos | Corrigido nesta revisão em `World/Shapes.gd`: batching misturava malhas indexadas/não indexadas e perdia faces. Teste antes 188→108 triângulos; depois 188→188 nas duas ordens. Capturas reais adicionais |
| Melhorar menu, HUD e interface | Menu com ilustração vetorial original; HUD com barras; custos coloridos e progresso de bancada; mapa proporcional com controles ao lado. GUI com mouse/teclado e três resoluções |
| Melhorar personagens, animais e todas as animações | Rig e animações existentes preservados; correção compartilhada de geometria e engrenagens/roda/itens de esteira animados. Arte, animações cinematográficas e revisão completa de todas as combinações continuam PARCIAIS |
| Bancadas e pickups reconhecíveis | 17 montagens de oficina, modelos de pickups por família e cinco ícones novos. Galeria/close-ups reais; ainda são arte procedural em desenvolvimento, não 105 modelos finais individuais |
| Itens obteníveis, receitas e duas cadeias reais | 105 itens, 94 receitas e 17 estações em `Data/Items.json`. Todos os IDs atuais têm caminho de obtenção verificado por regras; os dois ciclos anteriores continuam testados em ENet. Cinco novos itens industriais possuem receitas |
| Fábricas como referência conceitual de Islands | Roda-d'água, postes, fios pagos, lâmpadas, motores e esteiras funcionais. Serraria energizada alimenta carpinteiro e produz kit de parede. PARCIAL para automação industrial completa: sem roteadores/splitters/produção offline com servidor desligado |
| Não dar eletricidade gratuita no início | Roda exige ferro, engrenagens, tábuas/fios e oficina; motor custa materiais processados. Gerador exige rio profundo com corrente. Cabos custam fios; rede tem demanda, sobrecarga e permissões |
| Comércio entre jogadores | Troca direta a até 6 m, preço fixo e confirmação do destinatário; transferência atômica, capacidade, desgaste conservado, expiração/bloqueio/desconexão. Não é uma economia com NPCs/mercados |
| Clãs/reinos, aliados e guerra | Tribos/diplomacia e proteções anteriores preservadas; canal de aliados e pings adicionados. Cercos, catapultas, territórios/capitais e guerra completa continuam PARCIAIS/AUSENTES |
| Proteção aliada e após saída/expulsão | Regras de 300 s bidirecionais e trégua de 1 h preservadas e incluídas na regressão. Não depende da UI ou de um cliente declarar seu próprio dano |
| Chat global, local, privado, grupos, reino e diplomacia | Preservados; canal automático de aliados acrescentado. Autorização e bloqueio testados; moderação de conteúdo ofensivo não está completa |
| Voz espacial com PTT/mute e privacidade | Captura/codec/transporte/reprodução reais já existem. Áudio sintético testa roteamento e ganho; microfone físico, permissões, qualidade/latência audível e rede externa continuam PENDENTES. Sem serviço pago obrigatório; servidor/banda/CPU têm custo |
| Pings/marcadores sem expor inimigos | Pings de 20 s, até 250 m, só em células descobertas; tribo/aliança/bloqueio verificados no servidor e snapshots filtrados. Marcadores persistentes existentes mantidos. Isso não certifica proteção anti-wallhack de todos os dados do mundo |
| Novo mundo com seed diferente; reload igual | Gerador 3 e saves anteriores preservados; seed, alterações, inventários, construções e nova rede industrial persistem. Três seeds e reload são parte da suíte existente |
| Mapa vivo, rios/barcos, montanhas/POIs e chunks | Mundo atual de 1536×1536 m, vegetação, fauna, rios, jangada, travessias, caverna/ruínas e streaming preservados. Continente de 12 km, navios/oceano e oito tribos grandes validadas continuam pendentes |
| Mineração, pá, ervas e medicamentos | Sistemas existentes preservados e regressão executada. Escavação é superficial até 4 m; túneis volumétricos não foram implementados |
| Construção com telhado e abrigo reais | Peças, colisão, cobertura, camas/baús e persistência preservadas. Arte final, variantes de material, suporte estrutural/reparo/destruição completos continuam parciais |
| Vida, sobrevivência e chuva | Mantidos 100 HP, regeneração 1/3 s, tolerância de chuva 40 s e primeiro dano aos 55 s, depois 1/15 s. Abrigo reinicia exposição. Nenhuma dessas taxas foi alterada |
| Janela, presets e hardware modesto | Renderizador mantido; cinco presets existentes, batching corrigido e limites de luz elétrica por proximidade. Medição em llvmpipe não equivale a Ryzen 4600G ou GPU física |
| Instalador, ZIP, Windows/Linux e GitHub | Cinco pacotes com recibo/hashes publicados; Windows nativo 34/0 incluindo upgrade 0.7.1→0.8, captura gráfica real do EXE em VM e Linux exportado 6/0. Playtest humano/hardware físico ainda pendentes; nenhuma aprovação antiga substitui o novo teste |
| Steam e jogo final publicado comercialmente | NÃO IMPLEMENTADO: Steamworks/loja, assinatura comercial, QA físico amplo, carga de 100 jogadores e conteúdo/arte final. Não há App ID ou publicação Steam realizada |
| Primeiros 60 minutos divertidos | Guia de progressão atualizado. Testes automatizados não substituem playtest humano cronometrado; esse critério não é declarado aprovado |

## Marcos e limites

A: mapa/inventário/crafting/base têm testes; beleza final e playtest integral pendentes.
B: sobrevivência/reinos/combate possuem sistemas e regressões; guerra completa pendente.
C: pequena cadeia com energia, iluminação, esteira e troca agora é demonstrável;
isso não aprova cidade industrial completa. D: instaladores/exports existem; dispositivos,
plataformas físicas e carga prolongada ampla ainda precisam de QA. Nenhum marco
A–D é declarado integralmente aprovado.

Limites atuais deliberados: 32 bancadas, 32 rotas de esteira, 128 aparelhos elétricos,
256 cabos e 512 peças de construção por mundo; estes limites não foram inflados para
fingir suporte a cidades de 100 jogadores. Fios/trocas não permitem usar inventários
de outro jogador sem validação da autoridade.

Resultados, reprodução e diferenças de qualidade: [SETTLEMENT_REPORT.md](SETTLEMENT_REPORT.md).

# Matriz auditada — Fase 0 / 0.5.0-dev

Criado por **felipealx**. Classificação descreve o escopo observado, não o jogo
completo idealizado. **Testado** = integração/regra exercitada; **Parcial** = há
comportamento real, mas faltam requisitos relevantes; **Ausente** = sem entrega.
Evidências e contagens: [PLAYABILITY_REPORT.md](PLAYABILITY_REPORT.md).

| Recurso | Estado | Arquivos reais / evidência / limite |
|---|---|---|
| Cena inicial/importação | Implementado e testado | Scenes/Main.tscn → Main.gd; import Godot e 564 checks sem erro fatal |
| Carregamento e menus | Implementado e testado, acabamento parcial | HUD.loading, HUD.gd e painéis UI; capturas e regressões; tradução/acessibilidade pendentes |
| Terceira pessoa e controles | Implementado e testado | Player/Player.gd, Character/Rig.gd; movimento/entrada/colisão e teste de dois clientes |
| Modelos e animações | Parcial | Shapes.gd corrigiu faces; animação procedural/remo/golpe; produção artística final ausente |
| Mundo por seed | Implementado e testado no escopo inicial | Terrain/World, geradores 0/1/2; novo 1536 m, chunks, edições persistidas |
| Ecologia e mundo vivo | Parcial | 96 animais novos, plantas, rebrota, floresta distante; sem ecologia final ou carga de oito tribos |
| Céu, dia/noite | Implementado e testado | World/Clock.gd, World.gd; 30/15 min, sol/lua e capturas reais |
| Chuva, frio e cobertura | Implementado e testado no escopo básico | Weather, Survival, Vitals; exposição 40/55/15 s, teto físico; regras herdadas de regeneração documentadas |
| Fogueira, luz e combustível | Implementado e testado no escopo básico | Building/Campfire.gd, Piece.gd; tocha/lamparina; Compatibility sem SSR/GI/volumetria |
| Coleta/mineração | Implementado e testado | Mining/System.gd: 158 depósitos, IDs antigos preservados, ferramentas, rebrota e alcance |
| Escavar | Parcial | Pá e edição superficial de até 4 m, altura/colisão/save; sem túneis volumétricos |
| Inventário e obtenção | Implementado e testado para catálogo atual | Core/Inventory.gd, Items/Catalog.gd; 36 slots, equipar, descarte; teste de caminho para todos os IDs atuais |
| Craft e pesquisa | Implementado e testado no escopo básico | Balance.json, Runtime.gd, InventoryPanel.gd; receitas/estação/custos/fila/cancelamento, progressão parcial |
| Alimentação e medicina | Parcial | Fome/sede, consumo, cozinha, curativo/chá/kit; sem ferimentos/validade completos |
| Agricultura, pesca e pets | Parcial | Canteiros/bagas, população de pesca e domesticação básicas, testes herdados |
| Construção | Parcial | Peças, telhado/porta, cama/baú, custo/colisão/save; resistência, materiais e cercos incompletos |
| Fábricas | Parcial | Factory.gd/Workshop.gd, serraria/tear/britador com entrada/tempo/saída reais; sem energia/esteiras |
| Jangada | Parcial | Piece.gd/Player.gd, embarque/remo/obstáculos/save; sem navegação oceânica avançada |
| Combate | Parcial | Combat/Rules.gd, Runtime.gd; validação de dano/alcance, animais e proteção aliada; catálogo/equilíbrio final pendentes |
| Tribos e diplomacia | Parcial | Tribes/System.gd, RPCs/UI; convites, liderança, aliados/paz/guerra/trégua e proteção de 300 s testadas; sem guerra territorial completa |
| Multiplayer | Parcial, integração básica testada | ENet autoritativo, dedicado + 2 clientes reais; ausência de teste de carga, criptografia e autenticação comercial |
| Configurações | Implementado e testado no escopo básico | Settings autoload, Graphics/Settings, presets, resolução/confirmação, controles; hardware físico pendente |
| Chat e voz | Parcial | Comunicação por canais e voz opt-in; regressões com áudio sintético, sem microfone/Opus/eco certificados |
| Saves | Implementado e testado no escopo atual | Schema 4, migrações, slots alternados/checksum/lock, reinício/crash; sem garantia WAL/fsync contra energia |
| Instalador e ZIPs | Implementado e testado no escopo automatizado | NSIS/ZIPs/recibo/hash; QA nativo 0.5 aprovado, logs preservados; Windows gráfico/upgrade entre versões pendentes |
| Recursos/licenças | Inventariados | THIRD_PARTY.md, CREDITS.md, LICENSES; 20 WAV originais, fonte Noto, geometria/shaders originais; sem plugins externos |
| Energia de rios/fiação | Ausente | Planejado; nenhum botão apresentado como sistema pronto |
| Esteiras/automação complexa | Ausente | Três máquinas fixas não equivalem a uma rede industrial |
| Steamworks/assinatura Windows | Ausente | Exportação independente existe; integração comercial não concluída |

Falhas anteriores de normais, ações, equipar/construir e prazo de inicialização
foram corrigidas e possuem regressões. Não há erro fatal conhecido nos cenários
aprovados; isso não prova ausência de bugs em todos os caminhos do jogo.

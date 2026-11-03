# Preparação de lançamento — 0.4.0-dev

Créditos do projeto: **felipealx**. A versão é de desenvolvimento; esta lista não
certifica que todos os requisitos de lançamento foram concluídos.

| Item | Estado e evidência necessária |
|---|---|
| Licenças de engine/fontes | Arquivos oficiais em LICENSES e inventário em THIRD_PARTY.md; incluídos nos pacotes |
| Recursos originais | Geometria/shaders/ícone/áudio originais do projeto; arte e animações ainda exigem revisão de produção |
| Créditos | CREDITS.md e identificação do criador; conferir a tela real após cada alteração da UI |
| Privacidade | Docs/PRIVACY.md informa dados locais e transmissão ao servidor, voz opt-in e ausência de telemetria; revisão nativa/jurídica pendente |
| Credenciais nos pacotes | Fonte usa manifesto Git quando disponível, respeita arquivos ignorados e recusa nomes privados mesmo se rastreados; testes com segredos fictícios |
| Exportação/instalador | NSIS Unicode per-user, idiomas/atalhos/desinstalador; resultado de execução Windows deve ser conferido no workflow do commit publicado |
| Atualização de versão | QA aceita schemas3/4 e seleciona pacote por versão; instalação limpa/reinstalação automatizadas. Upgrade de versão distinta e migração real no Windows continuam pendentes |
| Assinatura digital | Nenhum certificado configurado; executáveis/instalador não assinados podem exibir alertas do sistema |
| Distribuição Steam/lojas | Não publicada; cadastro, termos, contato, imagens, classificação e integração permanecem pendentes |
| Requisitos mínimos/recomendados | Ainda não determinados por medições em GPU física; não divulgar números inventados |
| Desempenho observado | Baseline de cinco minutos em llvmpipe/Muito Baixo: ~17,05 FPS a1280×720, memória estática Godot~102,1–102,4MB; não equivale a GPU integrada/dedicada |
| Capturas e material promocional | Capturas técnicas comparativas devem mostrar o estado real; banner/descrição comercial finais pendentes de aprovação do criador |

## Hardware e publicação

Plataformas de exportação: Windows e Linux x64. A toolchain testada é Godot4.6.3
padrão, Python3 e NSIS3; essas ferramentas não são necessárias ao jogador que usa
um pacote exportado. É necessário um driver compatível com OpenGL3.3 para o
renderer Compatibility; isso é requisito técnico da engine, não garantia de FPS.

Não há benchmark no Ryzen54600G/16GB/1080p ou tabela de GPU física disponível.
Escala de renderização baixa reduz custo, mas não simula fielmente outro hardware.
Memória estática Godot, RSS do processo e tempo de GPU são métricas diferentes.
Resultados novos devem citar resolução, preset, cenário, duração, engine, driver,
hardware e interferências; valores ausentes devem permanecer ausentes.

Nenhuma versão deve ser anunciada como1.0 apenas porque exportou ou passou testes
unitários. Consultar o diagnóstico, relatório de execução, pendências funcionais
e resultado nativo Windows antes de compartilhar uma nova entrega.

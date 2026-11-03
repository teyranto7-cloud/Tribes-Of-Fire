# Mudanças — Tribes of Fire

Criado por **felipealx**.

## 0.5.0-dev — mundo ampliado e progressão jogável

- Corrige faces invertidas de modelos, golpe frontal, troca entre ferramenta e
  construção, percentuais de ações e prazo CLI de execução após inicialização.
- Novo inventário em abas, busca, custos, motivos de bloqueio e fila de produção.
- Recursos com fontes de obtenção, plantas, medicina, materiais processados e
  equipamentos de prata/ouro com receitas reais.
- Gerador de 1536 × 1536 m, oito monumentos regionais, 96 animais, floresta distante,
  flores/vegetação e rio navegável. Saves antigos mantêm o gerador anterior.
- Jangada conduzível, escavação superficial persistente e três máquinas produtivas.
- Diplomacia entre líderes, alianças/paz/guerra e trégua após romper aliança.
- Suíte completa: 564 verificações, 0 falhas; seis verificações dos exports Linux.
  Confira Docs/PLAYABILITY_REPORT.md para evidências e limitações da prévia.

## 0.4.0-dev — reconstrução em validação

A reconstrução parte da0.3.1 preservada em Downloads. O relatório de execução
identifica quais mudanças foram integradas e testadas; a existência desta seção
não declara aprovação de todos os requisitos.

- Empacotamento de fontes passa a respeitar arquivos ignorados e excluir perfis,
  credenciais e chaves, inclusive se adicionados ao Git por engano.
- Documentação de privacidade, componentes de terceiros e estado de lançamento
  acompanha os pacotes. Relatórios/imagens de auditoria são excluídos do PCK.
- QA Windows seleciona pacotes por versão e valida descritores de mundo/schema4.
  Atualização entre versões distintas e migração no Windows ainda precisam execução real.

Consulte PROGRESS.md para as alterações de jogabilidade, gráficos, mundo,
segurança e resultados observados nesta revisão.

## 0.3.1-dev

Correções de movimento após morte, durabilidade de itens descartados, oclusão de
coleta, cozimento com inventário cheio, configurações malformadas, LOD e fechamento
no carregamento. Fortalecimento de saves/identidades, relógio monotônico e fila de
voz. Suíte de372 verificações e seis checks dos binários Linux; execução Windows
headless aprovada. Voz sob carga, gráficos Windows e hardware alvo não certificados.

## 0.3.0-dev

Primeira entrega integrada de personagens personalizáveis, seis idiomas, inventário
com espaços, equipamentos, sobrevivência, animais, mineração, combate, tribos,
texto/voz opt-in, perfis gráficos e instalador multilíngue. Mundo128×128m com seed
fixa; versão de desenvolvimento, requisitos1.0 incompletos.

# QA executável — Fase 0

Godot 4.6.3 padrão, Python 3.11+, templates da mesma versão; NSIS para instalador.
Os comandos devem ser executados na raiz do checkout. Testes de rede usam portas
UDP locais e precisam de socket autorizado. Dados de teste usam perfis isolados.

```sh
python3 Tools/audit_project.py
python3 Tools/build.py
python3 Tools/test_exports.py
python3 Tools/test_multiplayer.py
python3 Tools/test_startup_stability.py
python3 Tools/package.py
python3 Tools/test_source_package.py
```

`build.py` importa no editor headless, executa regras/integrações/processos e
exporta somente se houver resultados válidos, sem erro de parser/script ou leak.
O recibo congela fontes/binários. `package.py` verifica o recibo e ZIPs, gera NSIS,
manifesto e SHA256. `test_source_package.py` extrai/importa/executa fontes isoladas.
`Tools/Test-Windows.ps1` valida instalador/atalhos/runtime/save/reinstalação/uninstall
no Windows; o workflow publica a evidência e não transfere aprovação entre versões.

Inspeção real de UI/mundo, com display gráfico ativo:

```sh
godot --path . --script res://Tools/capture_playability.gd
```

Esse script cria um mundo de teste em user://capture-v5-world, configura preset
Médio e captura poses/horários de inspeção. Use perfil de dados separado para
preservar preferências pessoais. Não substitui explorar/jogar em hardware real.

Resultados: [PLAYABILITY_REPORT.md](PLAYABILITY_REPORT.md), logs/recibo/imagens
em [verification/0.5.0-dev](verification/0.5.0-dev). Testes manuais prolongados e
matriz de hardware continuam pendentes em PENDENCIAS.md. Não prometer 100%.

Critério da Fase 0: import e cena real sem erro fatal; menus exercitados; export
disponível abre/salva/reabre; checkpoint recuperável; recursos classificados e
instalador testado por versão. QA nativo 0.5 aprovado no run 41560599160; Fase 0
concluída no escopo observado, próxima fase tecnicamente liberada. Nenhuma próxima
fase é executada automaticamente; pendências de produto/hardware continuam abertas.

# Downloads — Tribes of Fire

Os pacotes da versão de desenvolvimento **0.3.0-dev** estão em [0.3.0-dev](0.3.0-dev/).
No Windows, baixe o arquivo `TribesOfFire-0.3.0-dev-Windows-Setup.exe` e execute-o,
ou extraia o ZIP Windows. No Linux, extraia o ZIP Linux e execute o binário.
Esses pacotes não exigem o editor Godot instalado.

`SHA256SUMS.txt` e `manifest.json` identificam os arquivos desta entrega.
No Linux: `sha256sum -c SHA256SUMS.txt` dentro da pasta dos pacotes.
No PowerShell: `Get-FileHash -Algorithm SHA256 CAMINHO_DO_ARQUIVO`.

Instalação gráfica em Windows, dispositivos físicos e hardware alvo precisam da
validação indicada no README principal e em Tests/MANUAL.md. A versão 0.3.0-dev
não é a conclusão dos requisitos de 1.0. O código-fonte e as limitações estão na
raiz do repositório. Licenças de Godot e Noto acompanham cada pacote.

A pasta Downloads não é importada pelo Godot nem embutida nos exports ou no ZIP
de fontes. Os arquivos do projeto continuam disponíveis normalmente no checkout.

O workflow Windows passou na [execução headless publicada](https://github.com/teyranto7-cloud/Tribes-Of-Fire/actions/runs/41380465249).
Consulte o README principal para distinguir essa evidência dos testes gráficos pendentes.

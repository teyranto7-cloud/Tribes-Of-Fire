$ErrorActionPreference = 'Stop'
# Load only the two pure functions through the AST; never execute installer code.
$Tokens = $null
$ParseErrors = $null
$Ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Test-Windows.ps1'), [ref]$Tokens, [ref]$ParseErrors)
if ($ParseErrors.Count -ne 0) { throw 'Windows QA script failed to parse.' }
foreach ($Name in @('Is-Number', 'Json-Equal')) {
    $Function = $Ast.Find({ param($Node) $Node -is [Management.Automation.Language.FunctionDefinitionAst] -and $Node.Name -eq $Name }, $true)
    if ($null -eq $Function) { throw "Missing function: $Name" }
    . ([scriptblock]::Create($Function.Extent.Text))
}
$Cases = @(
    @((Json-Equal 0.000882999999999967 0.00088299999999996), $true),
    @((Json-Equal 1 1.0), $true),
    @((Json-Equal 1 2), $false),
    @((Json-Equal 1 1.000000000001), $false),
    @((Json-Equal 1.25 1.250001), $false),
    @((Json-Equal ([double]::NaN) ([double]::NaN)), $false),
    @((Json-Equal ('{"a":1,"b":2}' | ConvertFrom-Json) ('{"b":2,"a":1.0}' | ConvertFrom-Json)), $true),
    @((Json-Equal ('{"a":1}' | ConvertFrom-Json) ('{"a":1,"b":2}' | ConvertFrom-Json)), $false)
)
foreach ($Case in $Cases) {
    if ($Case[0] -ne $Case[1]) { throw 'JSON comparison regression.' }
}
Write-Output ('JSON_COMPARISON CHECKS=' + $Cases.Count + ' FAILED=0')

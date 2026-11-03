param(
    [Parameter(Mandatory = $true)][string]$Installer,
    [string]$OutputDirectory = (Join-Path $env:TEMP 'Tribes QA João'),
    [switch]$Headless
)
$ErrorActionPreference = 'Stop'
# Run only in a clean Windows test account or VM; never replace a player install.
$Registration = 'HKCU:\Software\felipealx\TribesOfFire'
if (Test-Path $Registration) { throw 'Use a clean test account: an installation is registered.' }
$UserData = Join-Path $env:APPDATA 'Godot\app_userdata\Tribes of Fire'
if (Test-Path $UserData) { throw 'Use a clean test account: existing player data was found.' }
$Installer = (Resolve-Path $Installer).Path
$InstallDirectory = Join-Path $OutputDirectory 'Game installed with spaces'
if (Test-Path $InstallDirectory) { throw 'Choose an unused output directory.' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
# Hosted Windows accounts may not yet have a Desktop directory.
$Desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop, [Environment+SpecialFolderOption]::Create)
if ([string]::IsNullOrWhiteSpace($Desktop)) { throw 'A current-user Desktop directory is required.' }
$ShortcutPath = Join-Path $Desktop 'Tribes of Fire.lnk'
$Results = New-Object System.Collections.Generic.List[object]
function Check([bool]$Condition, [string]$Name) {
    $Results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Condition) { 'Passed' } else { 'Failed' }) })
    if (-not $Condition) { throw $Name }
}
function Is-Number($Value) {
    return ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal])
}
function Number-InRange($Value, [double]$Minimum, [double]$Maximum, [bool]$Integral = $false) {
    if (-not (Is-Number $Value)) { return $false }
    $Number = [double]$Value
    return (-not [double]::IsNaN($Number) -and -not [double]::IsInfinity($Number) -and $Number -ge $Minimum -and $Number -le $Maximum -and (-not $Integral -or $Number -eq [math]::Floor($Number)))
}
function Json-Equal($Left, $Right) {
    if ($null -eq $Left -or $null -eq $Right) { return ($null -eq $Left -and $null -eq $Right) }
    # JSON may read the same integer as 1 or 1.0 on successive Godot saves.
    if ((Is-Number $Left) -and (Is-Number $Right)) { return ([double]$Left -eq [double]$Right) }
    if ($Left -is [pscustomobject] -and $Right -is [pscustomobject]) {
        $Properties = @($Left.PSObject.Properties)
        if ($Properties.Count -ne @($Right.PSObject.Properties).Count) { return $false }
        foreach ($Property in $Properties) {
            $Other = $Right.PSObject.Properties[$Property.Name]
            if ($null -eq $Other -or -not (Json-Equal $Property.Value $Other.Value)) { return $false }
        }
        return $true
    }
    if ($Left -is [array] -and $Right -is [array]) {
        if ($Left.Count -ne $Right.Count) { return $false }
        for ($Index = 0; $Index -lt $Left.Count; $Index++) {
            if (-not (Json-Equal $Left[$Index] $Right[$Index])) { return $false }
        }
        return $true
    }
    return ($Left.GetType() -eq $Right.GetType() -and [object]::Equals($Left, $Right))
}
function Read-WorldSnapshot([string]$Directory) {
    $Candidates = @()
    foreach ($File in @(Get-ChildItem -LiteralPath $Directory -Filter 'world.*.json')) {
        if ($File.Name -notmatch '^world\.[ab]\.json$') { continue }
        if ($File.Length -gt 16777216) { throw 'Snapshot exceeds its size limit.' }
        $Envelope = Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not (Number-InRange $Envelope.sequence 1 1000000000 $true) -or $Envelope.payload -isnot [string] -or $Envelope.digest -isnot [string]) { throw 'Invalid snapshot envelope.' }
        $Hasher = [Security.Cryptography.SHA256]::Create()
        try {
            $Bytes = [Text.Encoding]::UTF8.GetBytes(('{0}:{1}' -f [long]$Envelope.sequence, $Envelope.payload))
            $Digest = [BitConverter]::ToString($Hasher.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant()
        } finally { $Hasher.Dispose() }
        if ($Digest -cne $Envelope.digest) { throw 'Snapshot SHA256 does not match its payload.' }
        $Data = $Envelope.payload | ConvertFrom-Json
        if ($Data.version -notin @(3, 4) -or -not (Number-InRange $Data.seed 0 2147483647 $true) -or -not (Number-InRange $Data.phase 0 21600) -or $Data.players -isnot [pscustomobject]) { throw 'Invalid required world fields.' }
        $Extent = 61
        $MinimumY = -15
        $MaximumY = 40
        if ($Data.version -eq 4) {
            $World = $Data.world
            if ($World -isnot [pscustomobject] -or $World.seed -ne $Data.seed -or $World.generator -notin @(0, 1, 2, 3)) { throw 'Invalid world descriptor.' }
            if (($World.generator -eq 0 -and ($World.size -ne 128 -or $World.seed -ne 1337)) -or ($World.generator -eq 1 -and $World.size -ne 320) -or ($World.generator -in @(2, 3) -and $World.size -ne 1536)) { throw 'Unsupported generator dimensions.' }
            if ($World.generator -gt 0) { $Extent = $World.size / 2 + 1; $MinimumY = -30; $MaximumY = 120 }
        } elseif ($Data.seed -ne 1337 -or $Data.phase -gt 2700) { throw 'Invalid legacy world.' }
        $Players = @($Data.players.PSObject.Properties)
        if ($Players.Count -lt 1 -or $Players.Count -gt 1024) { throw 'Expected at least one persisted player.' }
        foreach ($Player in $Players) {
            $Record = $Player.Value
            if (-not (Number-InRange $Record.hp 0 100 $true) -or $Record.position -isnot [array] -or $Record.position.Count -ne 3 -or $Record.inventory -isnot [pscustomobject]) { throw 'Invalid required player fields.' }
            if (-not (Number-InRange $Record.position[0] (-$Extent) $Extent) -or -not (Number-InRange $Record.position[1] $MinimumY $MaximumY) -or -not (Number-InRange $Record.position[2] (-$Extent) $Extent)) { throw 'Invalid player position.' }
            foreach ($Required in @('axe', 'wood', 'campfire', 'shelter')) {
                if ($null -eq $Record.inventory.PSObject.Properties[$Required]) { throw 'Missing inventory field.' }
            }
            foreach ($Item in $Record.inventory.PSObject.Properties) {
                if (-not (Number-InRange $Item.Value 0 9999 $true)) { throw 'Invalid inventory count.' }
            }
        }
        $Candidates += [pscustomobject]@{ Path = $File.FullName; Sequence = [long]$Envelope.sequence; Data = $Data }
    }
    if ($Candidates.Count -eq 0) { throw 'No valid world snapshot was written.' }
    return $Candidates | Sort-Object -Property Sequence -Descending | Select-Object -First 1
}
function Run-Game([string]$Arguments, [string]$Log, [string]$Name) {
    $Child = Start-Process -FilePath $Executable -WorkingDirectory $InstallDirectory -ArgumentList $Arguments -PassThru
    $null = $Child.Handle
    if (-not $Child.WaitForExit(30000)) { Stop-Process -Id $Child.Id; throw "$Name timed out." }
    $Child.Refresh()
    Check ($Child.ExitCode -eq 0) "$Name starts and exits successfully"
    $Text = Get-Content -LiteralPath $Log -Raw -Encoding UTF8
    Check ($Text.Contains('GAME_READY') -and -not $Text.Contains('SCRIPT ERROR') -and -not $Text.Contains('ERROR:')) "$Name initializes resources without script errors"
    return $Text
}
try {
    # NSIS /D must be last and consumes the unquoted remainder, including spaces.
    $Process = Start-Process -FilePath $Installer -ArgumentList @('/S', "/D=$InstallDirectory") -Wait -PassThru
    Check ($Process.ExitCode -eq 0) 'Installer exits successfully'
    $Executable = Join-Path $InstallDirectory 'TribesOfFire.exe'
    Check (Test-Path $Executable) 'Game executable installed'
    $RequiredDocs = @('README.md', 'ARCHITECTURE.md', 'PROGRESS.md', 'CREDITS.md', 'Docs/COMMUNICATION.md', 'Docs/AUDIT.md', 'Docs/TEST_REPORT.md', 'Tests/MANUAL.md', 'Tools/Test-Windows.ps1')
    Check (@($RequiredDocs | Where-Object { -not (Test-Path (Join-Path $InstallDirectory $_)) }).Count -eq 0) 'All linked documentation installed'
    Check (Test-Path $ShortcutPath) 'Desktop shortcut created by default'
    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    Check ($Shortcut.TargetPath -eq $Executable) 'Shortcut points to the installed game'
    Check ($Shortcut.WorkingDirectory.TrimEnd('\') -eq $InstallDirectory.TrimEnd('\')) 'Shortcut working directory is correct'
    $Programs = [Environment]::GetFolderPath('Programs')
    Check (Test-Path (Join-Path $Programs 'Tribes of Fire\Tribes of Fire.lnk')) 'Start menu shortcut created'
    $WorldDirectory = Join-Path $OutputDirectory 'Persistent world João'
    $Log = Join-Path $OutputDirectory 'game-export.log'
    $Arguments = '--log-file "' + $Log + '" -- --play --save-dir="' + $WorldDirectory + '" --quit-after-seconds=3'
    if ($Headless) { $Arguments = '--headless --audio-driver Dummy ' + $Arguments }
    $null = Run-Game $Arguments $Log 'Exported Windows game'
    $Before = Read-WorldSnapshot $WorldDirectory
    Check ($Before.Data.phase -gt 450) 'Unicode path with spaces stores a checksummed world with players and advancing time'
    Check (-not (Test-Path (Join-Path $WorldDirectory '.writer-lock'))) 'Game shutdown releases the world lock'

    $Probe = New-Object System.Net.Sockets.UdpClient -ArgumentList 0
    try { $Port = $Probe.Client.LocalEndPoint.Port } finally { $Probe.Close() }
    $RestartLog = Join-Path $OutputDirectory 'server-restart.log'
    $RestartArguments = '--headless --audio-driver Dummy --log-file "' + $RestartLog + '" -- --server --port=' + $Port + ' --save-dir="' + $WorldDirectory + '" --quit-after-seconds=2'
    $RestartText = Run-Game $RestartArguments $RestartLog 'Windows dedicated restart'
    Check ($RestartText.Contains('SERVER_LISTENING')) 'Restart starts the dedicated authoritative server'
    $After = Read-WorldSnapshot $WorldDirectory
    Check ($After.Sequence -gt $Before.Sequence -and $After.Data.phase -gt $Before.Data.phase) 'Restart restores the world and advances snapshot sequence and clock'
    Check (Json-Equal $Before.Data.players $After.Data.players) 'Restart preserves every saved player field'
    Check (-not (Test-Path (Join-Path $WorldDirectory '.writer-lock'))) 'Restart shutdown releases the world lock'

    $Snapshot = $After.Path
    $Hash = (Get-FileHash -LiteralPath $Snapshot -Algorithm SHA256).Hash
    $Process = Start-Process -FilePath $Installer -ArgumentList @('/S', "/D=$InstallDirectory") -Wait -PassThru
    Check ($Process.ExitCode -eq 0) 'Reinstall over the existing installation succeeds'
    Check ((Get-FileHash -LiteralPath $Snapshot -Algorithm SHA256).Hash -eq $Hash) 'Same-version reinstall preserves the saved world'
    New-Item -ItemType Directory -Path $UserData -Force | Out-Null
    $Sentinel = Join-Path $UserData 'qa-preserve.txt'
    'Keep personal data' | Set-Content -LiteralPath $Sentinel
    $Process = Start-Process -FilePath (Join-Path $InstallDirectory 'Uninstall.exe') -ArgumentList '/S' -Wait -PassThru
    $Deadline = (Get-Date).AddSeconds(15)
    while (((Test-Path $Executable) -or (Test-Path $ShortcutPath) -or (Test-Path $Registration)) -and (Get-Date) -lt $Deadline) { Start-Sleep -Milliseconds 200 }
    Check (-not (Test-Path $Executable)) 'Uninstaller removes application files'
    Check (-not (Test-Path $ShortcutPath)) 'Uninstaller removes desktop shortcut'
    Check (-not (Test-Path $Registration)) 'Uninstaller removes installation registration'
    Check (Test-Path $Sentinel) 'Uninstaller preserves personal data'
    Check ((Get-FileHash -LiteralPath $Snapshot -Algorithm SHA256).Hash -eq $Hash) 'Uninstaller preserves the saved world'
} catch {
    $Results.Add([pscustomobject]@{ Check = 'Execution failure'; Result = 'Failed'; Detail = $_.Exception.Message })
    throw
} finally {
    $Results | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $OutputDirectory 'windows-results.csv')
    [pscustomobject]@{
        System = [Environment]::OSVersion.VersionString
        ExecutionMode = $(if ($Headless) { 'headless; graphical validation remains pending' } else { 'graphical startup' })
        PersistenceExecutionMode = 'headless dedicated server restart'
        ExecutedChecks = $Results
        ManualPending = @('Installer language chooser and all six languages', 'Launch through the desktop shortcut without arguments', 'Rendered gameplay and graphical first-run language selection', 'Interactive character creation and persistence', 'Microphone and speakers', 'Multiplayer with real remote peers', 'Windows 10 and Windows 11 separate machines', 'Target hardware benchmark', 'Upgrade from a different released version')
    } | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $OutputDirectory 'windows-report.json')
}

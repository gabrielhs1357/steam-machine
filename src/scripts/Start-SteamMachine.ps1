. "$PSScriptRoot\_config.ps1"

$currentState = Get-MachineState

if ($currentState -ne "Console") {
    exit 0
}

$steamPath = "C:\Games\Steam\steam.exe"

if (Test-Path $steamPath) {
    Start-Process -FilePath $steamPath -ArgumentList "steam://open/bigpicture"
}
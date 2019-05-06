# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing dotnet4.7.1"
Write-UpliftEnv

choco install -y dotnet4.7.1
Confirm-UpliftExitCode $LASTEXITCODE "Failing install" @(0, 3010)

exit 0
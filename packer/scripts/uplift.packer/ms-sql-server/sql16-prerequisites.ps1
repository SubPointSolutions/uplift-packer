# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running SQL 16 prerequisites..."
Write-UpliftEnv

choco install -y dotnet4.6.1 --limit-output --acceptlicense --no-progress;
Confirm-UpliftExitCode $LASTEXITCODE "Cannot install powershell" @(0, 3010)

$LASTEXITCODE = 0;

exit 0
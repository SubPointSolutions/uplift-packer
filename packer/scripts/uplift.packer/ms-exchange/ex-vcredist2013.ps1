# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing Visual C++ 2013 Redistributable Package"
Write-UpliftEnv

choco install -y vcredist2013
Confirm-UpliftExitCode $LASTEXITCODE "Failing install" @(0, 3010)

exit 0
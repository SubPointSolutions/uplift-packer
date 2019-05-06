# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing Unified Communications Managed API 4.0 Runtime"
Write-UpliftEnv

choco install -y ucma4
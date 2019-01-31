# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing PowerShell Modules..."
Write-UpliftEnv

# - install invoke uplift module under pwsh
# we need this so that pwsh would see installed module
Write-UpliftMessage "Installing Invoke-Uplift PS6 module"

Install-UpliftPS6Module `
    "InvokeUplift" `
    (Get-UpliftEnvVariable "UPLF_INVOKE_UPLIFT_MODULE_VERSION"    "" "") `
    (Get-UpliftEnvVariable "UPLF_INVOKE_UPLIFT_MODULE_REPOSITORY" "" "")
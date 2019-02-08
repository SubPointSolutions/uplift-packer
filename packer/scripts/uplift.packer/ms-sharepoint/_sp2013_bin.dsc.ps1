
# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running SharePoint prerequisiteinstaller..."
Write-UpliftEnv

$installDir = Get-UpliftEnvVariable "UPLF_INSTALL_DIR"
$productKey = Get-UpliftEnvVariable "UPLF_SP_PRODUCT_KEY"

Configuration SP2013_InstallBin
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion "1.9.0.0"

    node "localhost"
    {
        SPInstall InstallSharePoint {
            Ensure = "Present"
            BinaryDir = $Node.InstallDir
            ProductKey = $Node.ProductKey
        }
    }
}

$config = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'

            PSDscAllowDomainUser        = $true
            PSDscAllowPlainTextPassword = $true

            RetryCount = 10
            RetryIntervalSec = 30

            InstallDir = $installDir
            ProductKey = $productKey
        }
    )
}

$configuration = Get-Command SP2013_InstallBin
Start-UpliftDSCConfiguration $configuration $config

exit 0
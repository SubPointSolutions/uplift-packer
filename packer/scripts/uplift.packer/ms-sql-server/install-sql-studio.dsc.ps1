# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running SQL Studio install..."
Write-UpliftEnv

$sqlInstallDir            = Get-UpliftEnvVariable "UPLF_INSTALL_DIR"
$sqlStudioInstallFilePath = Find-UpliftFileInPath $sqlInstallDir
$sqlStudioProductId       = Get-UpliftEnvVariable "UPLF_SQL_STUDIO_PRODUCT_ID" "" "F8ADD24D-F2F2-465C-A675-F12FDB70DB82"

Write-UpliftMessage " - sqlInstallDir: $sqlInstallDir"
Write-UpliftMessage " - sqlStudioInstallFilePath: $sqlStudioInstallFilePath"
Write-UpliftMessage " - productId: $sqlStudioProductId"

Configuration SqlStudioInstall {
					
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Package SqlStudioPackage
    {
        Ensure      = "Present"
        Name        = "SMS-Setup-ENU"
        Path        = $sqlStudioInstallFilePath 
        Arguments   = "/install /passive /norestart"
        ProductId   = $sqlStudioProductId
    }
}

$config = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
            RetryCount = 10
            RetryIntervalSec = 30
        }
    )
}

$configuration = Get-Command SqlStudioInstall
Start-UpliftDSCConfiguration $configuration $config

exit 0
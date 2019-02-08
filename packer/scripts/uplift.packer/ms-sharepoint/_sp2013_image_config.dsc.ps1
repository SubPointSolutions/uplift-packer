# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "[~] Installing SharePoint specific image settings"
Write-UpliftEnv

Configuration SharePoint_ImageConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xCredSSP -ModuleVersion 1.3.0.0

    Node "localhost"
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $false
            RefreshMode = "Push"
        }

        xCredSSP CredSSPServer
        {
            Ensure  = "Present"
            Role    = "Server"
        }


        xCredSSP CredSSPClient
        {
            Ensure = "Present"
            Role = "Client"
            DelegateComputers = "*"
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
        }
    )
}

$configuration = Get-Command SharePoint_ImageConfiguration
Start-UpliftDSCConfiguration $configuration $config $False

exit 0
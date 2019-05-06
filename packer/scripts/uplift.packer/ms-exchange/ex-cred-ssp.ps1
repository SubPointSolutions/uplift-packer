# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "[~] Installing CRM specific image settings"
Write-UpliftEnv

# CRM provision needs more RAM 
# our of ram exception might be raised over  a long provision session 
Write-UpliftMessage '[~] Reconfiguring WinRM settings, MaxMemoryPerShellMB="0"'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'

Configuration CRM_ImageConfiguration
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

$configuration = Get-Command CRM_ImageConfiguration
Start-UpliftDSCConfiguration $configuration $config $False

exit 0
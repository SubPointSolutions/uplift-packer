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

if ( !(Test-Path "C:\windows\System32\ServerManagerCMD.exe") ) {
    Copy-Item "C:\windows\System32\rundll32.exe" "C:\windows\System32\ServerManagerCMD.exe" -Force -ErrorAction SilentlyContinue

    Write-UpliftMessage "[+] done!"

    Write-UpliftMessage "Installing: Web-Server, Application-Server, WAS"

    Install-WindowsFeature Web-Server -IncludeAllSubFeature
    Install-WindowsFeature Application-Server -IncludeAllSubFeature
    Install-WindowsFeature WAS -IncludeAllSubFeature

    Write-UpliftMessage "Installing: dism /online /enable-feature /featurename:IIS-ASPNET45 /all"

    dism /online /enable-feature /featurename:IIS-ASPNET45 /all

    Write-UpliftMessage "Installing: C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i"
    C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i


} else {
    Write-UpliftMessage "[+] already done"
}

exit 0
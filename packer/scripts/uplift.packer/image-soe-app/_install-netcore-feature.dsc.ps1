# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing NET-Framework-Core feature..."
Write-UpliftEnv

Configuration NETFrameworkCore
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node localhost {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
        }

        WindowsFeature "NET-Framework-Core"
        {
            Ensure  = "Present"
            Name    = "NET-Framework-Core"
        }

    }
}

Write-UpliftMessage "Installing feature: NET-Framework-Core"

$configuration = Get-Command NETFrameworkCore
Start-UpliftDSCConfiguration $configuration

exit 0
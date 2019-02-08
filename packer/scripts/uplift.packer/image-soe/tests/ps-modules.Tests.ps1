
Describe 'PowerShell DCS' {

    function Check-PSModule($name) {
        It "ps module: $name" {
            Get-Module -Name $name -ListAvailable | Should BeLike $name
        }
    }

    function Check-PS6Module($name) {
        It "ps6 module: $name" {
            pwsh -c "Get-InstalledModule -Name $name"
        }
    }

    $psModules = @(
        'cChoco'
        'cFirewall'
        'SharePointDSC'
        'MS_xVisualStudio'
        'xActiveDirectory'
        'xSQLServer'
        'xDSCFirewall'
        'xNetworking'
        'xTimeZone'
        'xWebAdministration'
        'xPendingReboot'
        'xComputerManagement'
        'Pester'
        'xSystemSecurity'
        'DSCR_Shortcut'
        'PSWindowsUpdate'
        'ComputerManagementDsc'
        'xCredSSP'
        'Uplift.Core'
    )

    $ps6Modules = @(
        'InvokeUplift'
    )

    Context "PS Modules" {

        foreach($psModule in $psModules) {
            Check-PSModule($psModule) 
        }
    }

    Context "PS6 Modules" {

        foreach($psModule in $ps6Modules) {
            Check-PS6Module($psModule) 
        }

    }
}
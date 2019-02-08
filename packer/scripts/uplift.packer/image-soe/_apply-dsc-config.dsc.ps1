# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running windows SOE config..."
Write-UpliftEnv

Write-UpliftMessage "Disabling Firewalls..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# this one must exists
# we start a task later to re-enable WinRM after sysprep
# packer provision brings it there, and then DSC uses it to setup startup task
$winrmTaskFile = Get-UpliftEnvVariable "UPLF_WINRM_TASK_FILE_PATH" "" "c:/uplift_scripts/uplift_winrm.ps1"

if ( (Test-Path $winrmTaskFile) -eq $False ) {
    throw "Cannot find winrm task file: $winrmTaskFile"
} 

Configuration Configure_UpliftSOE {

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Import-DscResource -ModuleName 'xActiveDirectory' -ModuleVersion '2.17.0.0'
    Import-DscResource -ModuleName 'xNetworking' -ModuleVersion '5.5.0.0'
    Import-DscResource -ModuleName 'ComputerManagementDsc' -ModuleVersion "6.1.0.0"

    Import-DSCResource -Module xSystemSecurity

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $false
            RefreshMode = "Push"
        }

        User Vagrant {
            UserName = "vagrant"
            Disabled = $false
            PasswordChangeRequired = $false
            PasswordNeverExpires = $true
        }

        TimeZone TimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'AUS Eastern Standard Time'
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        WindowsFeature ADDSRSAT
        {
            Ensure = "Present"
            Name   = "RSAT-ADDS-Tools"
        }

        WindowsFeature RSAT
        {
            Ensure = "Present"
            Name   = "RSAT"
        }

        Registry WindowsUpdate_NoAutoUpdate
        {
            Ensure      = "Present"
            Key         = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName   = "NoAutoUpdate"
            ValueData   = 1
            ValueType   = "DWord"
        }

        Registry WindowsUpdate_AUOptions
        {
            Ensure      = "Present"
            Key         = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName   = "AUOptions"
            ValueData   = 2
            ValueType   = "DWord"
        }

        Registry Windows_RemoteConnections
        {
            Ensure      = "Present"
            Key         = "HKLM:System\CurrentControlSet\Control\Terminal Server"
            ValueName   = "fDenyTSConnections"
            ValueData   = 0
            ValueType   = "DWord"
        }

        ScheduledTask UpliftWinRmStartUp
        {
            TaskName           = 'UpliftWinRmStartUp'
            TaskPath           = '\UpliftTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments    = '-File c:/Windows/Temp/_uplift_winrm.ps1'
            ScheduleType       = 'AtStartup'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            RunLevel           = 'Highest'
        }

        xIEEsc Disable_IEEsc
        {
            IsEnabled = $false
            UserRole  = "Administrators"
        }

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

$configuration = Get-Command Configure_UpliftSOE
Start-UpliftDSCConfiguration $configuration $config $True 

exit 0
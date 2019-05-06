# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing prereq for SharePoint 2019 RTM..."
Write-UpliftEnv

$installDir = $ENV:UPLF_INSTALL_DIR
$preReqDir  = $ENV:UPLF_PREREQ_DIR
$offline    = $ENV:UPLF_PREREQ_OFFLINE

Write-UpliftMessage "Using [ENV:UPLF_PREREQ_OFFLINE]: $offline"

if($null -eq $installDir) {
    $m = "UPLF_INSTALL_DIR env var is null or empty"
    Write-UpliftMessage $m
    throw $m
} else {
    Write-UpliftMessage "Using [ENV:UPLF_INSTALL_DIR]: $installDir"
}

if( ($null -ne $offline ) -and ($null -eq $preReqDir) ) {
    throw "UPLF_PREREQ_DIR env var is null or empty"
} else {
    Write-UpliftMessage "Using [ENV:UPLF_PREREQ_DIR]: $preReqDir"
}

Write-UpliftMessage "Checking if prerequisiteinstaller is still running..."

while( $null -ne  ( get-process | Where-Object { $_.ProcessName.ToLower() -eq "prerequisiteinstaller" } ) ) {
    Write-UpliftMessage "prerequisiteinstaller is still running... sleeping 5 sec.."
    Start-Sleep -Seconds 5
}

Write-UpliftMessage "Running DSC: SP2013_InstallPrereqs"
Configuration SP2013_RTM_InstallPrereqs_Online
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion "3.3.0.0"

    node "localhost"
    {
        SPInstallPrereqs InstallPrereqs {
            Ensure            = "Present"
            InstallerPath     = ($Node.InstallDir + "\prerequisiteinstaller.exe")

            OnlineMode        = $true

            IsSingleInstance = "Yes"
        }
    }
}

Configuration SP2013_RTM_InstallPrereqs_Offline
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion "1.9.0.0"

    node "localhost"
    {
        SPInstallPrereqs InstallPrereqs {
            Ensure            = "Present"
            InstallerPath     = ($Node.InstallDir + "\prerequisiteinstaller.exe")

            OnlineMode        = $false

            # NET 35 is meant to be installed early with the "app" image so to avoid SXS roundtrip
            #SXSpath           = "c:\SPInstall\Windows2012r2-SXS"
            SQLNCli           = ($Node.PrereqDir + "\sqlncli.msi")
            PowerShell        = ($Node.PrereqDir + "\Windows6.1-KB2506143-x64.msu")
            NETFX             = ($Node.PrereqDir + "\dotNetFx45_Full_setup.exe")
            IDFX              = ($Node.PrereqDir + "\Windows6.1-KB974405-x64.msu")
            Sync              = ($Node.PrereqDir + "\Synchronization.msi")
            AppFabric         = ($Node.PrereqDir + "\WindowsServerAppFabricSetup_x64.exe")
            IDFX11            = ($Node.PrereqDir + "\MicrosoftIdentityExtensions-64.msi")
            MSIPCClient       = ($Node.PrereqDir + "\setup_msipc_x64.msi")
            WCFDataServices   = ($Node.PrereqDir + "\WcfDataServices-5.0.exe")
            KB2671763         = ($Node.PrereqDir + "\AppFabric1.1-RTM-KB2671763-x64-ENU.exe")
            WCFDataServices56 = ($Node.PrereqDir + "\WcfDataServices-5.6.exe")

            IsSingleInstance = "Yes"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $False
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

            InstallDir = $installDir
            PrereqDir = $preReqDir
        }
    )
}

if( $null -ne $offline) {
    $configuration = Get-Command SP2013_RTM_InstallPrereqs_Offline
    Start-UpliftDSCConfiguration $configuration $config
} else {
    $configuration = Get-Command SP2013_RTM_InstallPrereqs_Online
    Start-UpliftDSCConfiguration $configuration $config
}

exit 0
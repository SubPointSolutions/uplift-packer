# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running SQL Prepare image..."
Write-UpliftEnv

$sqlInstallDir    = Get-UpliftEnvVariable "UPLF_INSTALL_DIR"

$sqlFeatures      = Get-UpliftEnvVariable "UPLF_SQL_FEATURES" "" "SQL,RS"
$sqlInstanceId    = Get-UpliftEnvVariable "UPLF_SQL_INSTANCE_ID" "" "MSSQLSERVER"
$sqlUpdateEnabled = Get-UpliftEnvVariable "UPLF_SQL_UPDATE_ENABLED" "" "False"
$sqlAction        = Get-UpliftEnvVariable "UPLF_SQL_ACTION" "" "PrepareImage"
$sqlSkipInstallerRunCheck = Get-UpliftEnvVariable "UPLF_SQL_SKIP_INSTALLER_RUN_CHECK" "" ""

try {
    $sqlDir = $sqlInstallDir

    Write-UpliftMessage "Listing dir..."
    Get-ChildItem "$sqlDir"

    Write-UpliftMessage "Running PrepareImage..."

    # SQL Server SysPrep Parameters
    # https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-2016#SysPrep
    $options =  @(
        "/q",
        "/ACTION=$sqlAction",
        "/FEATURES=$sqlFeatures",
        "/InstanceID=$sqlInstanceId"
    )

    # adding SkipInstallerRunCheck option
    # https://stackoverflow.com/questions/40352574/sql-server-2014-installation-stuck-hung-up-or-taking-very-long-time-to-finish
    # https://stackoverflow.com/questions/47432390/sql-server-2017-developer-edition-installation-is-stuck-hung-up-endlessly

    if( [String]::IsNullOrEmpty($sqlSkipInstallerRunCheck) -eq $False) {
        $options += "/SkipInstallerRunCheck";
    }

    # False by default
    # True if updates are pre-baked in /latest/updates folder
    $updatesFolder = "$sqlDir/updates"

    # if path exists and there is something in there, then:
    # - switching UpdateEnabled -> True
    # - adding /UpdateSource parameter
    if( (Test-Path $updatesFolder) -and (( Get-ChildItem $updatesFolder | Measure-Object ).Count -gt 0) ) {
        Write-UpliftMessage "Detected updates in folder: $updatesFolder"
        dir $updatesFolder

        Write-UpliftMessage "Adding UpdateEnabled = True and /UpdateSource flags"
        $options += "/UpdateEnabled=True"
        $options += "/UpdateSource=""$updatesFolder"" "

    } else {
        Write-UpliftMessage "Detected no updates in folder: $updatesFolder"
        Write-UpliftMessage "Adding default UpdateEnabled flag = $sqlUpdateEnabled"

        $options += "/UpdateEnabled=$sqlUpdateEnabled"
    }

    $options += " /IACCEPTSQLSERVERLICENSETERMS "
    $arguments = [string]::Join(' ', $options)
    
    $processFile = "$sqlDir/setup.exe"

    Write-UpliftMessage "Starting process:"
    Write-UpliftMessage "$processFile"

    Write-UpliftMessage "with arguments:"
    Write-UpliftMessage " $arguments"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $processFile

    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true

    $pinfo.UseShellExecute = $false

    $pinfo.Arguments = $arguments

    $p = New-Object System.Diagnostics.Process

    $p.StartInfo = $pinfo

    Write-UpliftMessage "Started process....."
    $p.Start() | Out-Null

    Write-UpliftMessage "Waiting for exit..."
    $p.WaitForExit()

    Write-UpliftMessage "Finished running PrepareImage"
    Write-UpliftMessage "Res ExitCode: $($p.ExitCode)"

    # Res ExitCode: 0 - all good

    # Res ExitCode: -2067529717 - process already running

    # Res ExitCode: -2022834173 - updates cannot connect to remote server
    # Setup encountered a failure while running job UpdateResult.
    # mostlikely, case we disabled them via registry

    # Error result: -2067921930
    # mostlikely, This computer does not have the Microsoft .NET Framework 3.5 Service Pack 1 installed.
    # If the operating system is Windows Server 2008, download and install Microsoft .NET Framework 3.5 SP1 from http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=22
    # https://social.msdn.microsoft.com/Forums/en-US/8db6ff15-b5bc-4e3a-ab33-43e26ffab925/net-35-in-a-container-aiming-to-install-sql-server

    # Error result: -2067922340
    # SQL Server was already installed before

    if($p.ExitCode -ne 0) {
        Write-UpliftMessage "Error while installing SQL Server, check log files:"
        Write-UpliftMessage "C:\Program Files\Microsoft SQL Server\130\Setup Bootstrap\Log"
    }

    exit $p.ExitCode

} catch {
    Write-UpliftMessage "ERROR!"
    Write-UpliftMessage $_

    exit 1
}

exit 1
# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing SQL CU..."
Write-UpliftEnv

$sqlInstallDir = Get-UpliftEnvVariable "UPLF_INSTALL_DIR"
$sqlAction     = Get-UpliftEnvVariable "UPLF_SQL_ACTION" "" "Patch"
$sqlInstanceId = Get-UpliftEnvVariable "UPLF_SQL_INSTANCE_ID" "" "MSSQLSERVER"

try {
    $sqlDir = $sqlInstallDir

    Write-UpliftMessage "Listing dir..."
    Get-ChildItem "$sqlDir"

    Write-UpliftMessage "Installing CU..."

    # Installing Updates from the Command Prompt
    # https://docs.microsoft.com/en-us/sql/database-engine/install-windows/installing-updates-from-the-command-prompt?view=sql-server-2016
    $options =  @(
        "/q",
        "/IAcceptSQLServerLicenseTerms"
        "/Action=$sqlAction",
        "/InstanceName=$sqlInstanceId"
    )

    $arguments = [string]::Join(' ', $options)

    Write-UpliftMessage " - looking for exe/msi in path: $sqlInstallDir"
    $processFile = Find-UpliftFileInPath $sqlInstallDir

    Write-UpliftMessage " - found: $processFile"

    # unpack first 
    # Is there a cool way of performing CU updates for SQL Server on hundreds of machines?
    # https://dba.stackexchange.com/questions/105810/is-there-a-cool-way-of-performing-cu-updates-for-sql-server-on-hundreds-of-machi
    Write-UpliftMessage "Unpacking updates"
    $extractedDir = "$sqlInstallDir/unpacked"
    
    Write-UpliftMessage "Starting extraction process"
    $extractProcess = Start-Process $processFile -ArgumentList "/X:$extractedDir" -Wait -PassThru

    if($extractProcess.ExitCode -ne 0) {
        throw "Cannot extract update: $processFile"
    }

    # switch to unpacked setup.exe
    Write-UpliftMessage "Extracted ok! Switching instell to file: $extractedDir/setup.exe"
    $processFile = "$extractedDir/setup.exe"
    
    # install updates
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

    Write-UpliftMessage "Finished running process"
    Write-UpliftMessage "Res ExitCode: $($p.ExitCode)"

    exit $p.ExitCode

} catch {
    Write-UpliftMessage "ERROR!"
    Write-UpliftMessage $_

    exit 1
}

exit 1
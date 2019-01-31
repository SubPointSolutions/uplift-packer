# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running SQL Prepare image..."
Write-UpliftEnv

$sqlInstallDir = Get-UpliftEnvVariable "UPLF_INSTALL_DIR"

try {
    $sqlDir = $sqlInstallDir

    Write-UpliftMessage "Listing dir..."
    Get-ChildItem "$sqlDir"

    Write-UpliftMessage "Running PrepareImage..."
    $arguments = "/q /ACTION=PrepareImage /FEATURES=SQL,RS /InstanceID=MSSQLSERVER /UpdateEnabled=False /IACCEPTSQLSERVERLICENSETERMS  "

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$sqlDir/setup.exe"

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

    exit $p.ExitCode

} catch {
    Write-UpliftMessage "ERROR!"
    Write-UpliftMessage $_

    exit 1
}

exit 1
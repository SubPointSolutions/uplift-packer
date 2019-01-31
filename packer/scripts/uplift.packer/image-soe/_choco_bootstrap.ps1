# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing 7z and PowerShell software..."
Write-UpliftEnv

function Set-UpliftChocolateyBootstrap() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(

    )

    Write-UpliftMessage "Set-ExecutionPolicy Bypass -Force"
    Set-ExecutionPolicy Bypass -Force;

    Write-UpliftMessage "Installing chocolatey..."
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    Confirm-UpliftExitCode $LASTEXITCODE "Cannot install chocolatey"

    Write-UpliftMessage "choco install -y 7zip..."
    choco install -y 7zip --limit-output --acceptlicense --no-progress;
    Confirm-UpliftExitCode $LASTEXITCODE "Cannot install 7zip"

    if($psversiontable.PSVersion.Major -ne 5) {
        Write-UpliftMessage "Major version of POwerShell below 5. Installing PowerShell, and a reboot is required"
        choco install -y powershell --limit-output --acceptlicense --no-progress;
        Confirm-UpliftExitCode $LASTEXITCODE "Cannot install powershell" @(0, 3010)

        $LASTEXITCODE = 0;
    }
}

Set-UpliftChocolateyBootstrap

exit 0;
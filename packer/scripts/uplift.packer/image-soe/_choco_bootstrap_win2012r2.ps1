# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

function Confirm-UpliftExitCode {
    Param(
        [Parameter(Mandatory=$True)]
        $code,

        [Parameter(Mandatory=$True)]
        $message,

        [Parameter(Mandatory=$False)]
        $allowedCodes = @( 0 )
    )

    $valid = $false

    Write-Host "Checking exit code: $code with allowed values: $allowedCodes"

    foreach ($allowedCode in $allowedCodes) {
        if($code -eq $allowedCode) {
            $valid = $true
            break
        }
    }

    if( $valid -eq $false) {
        $error_message =  "[!] $message - exit code is: $code but allowed values were: $allowedCodes"

        Write-Host $error_message
        throw $error_message
    } else {
        Write-Host "[+] exit code is: $code within allowed values: $allowedCodes"
    }
}

Write-Host "Installing 7z and PowerShell software..."

function Set-UpliftChocolateyBootstrap() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(

    )

    Write-Host "Set-ExecutionPolicy Bypass -Force"
    Set-ExecutionPolicy Bypass -Force;

    Write-Host "Installing chocolatey..."
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    Confirm-UpliftExitCode $LASTEXITCODE "Cannot install chocolatey"

    Write-Host "choco install -y 7zip..."
    choco install -y 7zip --limit-output --acceptlicense --no-progress;
    Confirm-UpliftExitCode $LASTEXITCODE "Cannot install 7zip"

    if($psversiontable.PSVersion.Major -ne 5) {
        Write-Host "Major version of PowerShell below 5. Installing PowerShell, and a reboot is required"
        choco install -y powershell --limit-output --acceptlicense --no-progress;
        Confirm-UpliftExitCode $LASTEXITCODE "Cannot install powershell" @(0, 3010)

        $LASTEXITCODE = 0;
    }
}

Set-UpliftChocolateyBootstrap

exit 0;
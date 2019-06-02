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


Write-Host "Updating PowerShell package provider..."

$p = Get-PackageProvider -ListAvailable

Write-Host "Available providers: $p"

if($null -eq  ($p | Where-Object { $_.Name.Contains("NuGet") -eq $true } ) )
{
    Write-Host "Installing Nuget Package provider..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

    Write-Host "Updating PSGallery as Trusted"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
else
{
    Write-Host "No update required."
}

#Write-Host "Adding PSGallery: subpointsolutions-staging"
#New-UpliftPSRepository 'subpointsolutions-staging'  `
#            'https://www.myget.org/F/subpointsolutions-staging/api/v2'

exit 0
# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Updating PowerShell package provider..."
Write-UpliftEnv

$p = Get-PackageProvider -ListAvailable

Write-UpliftMessage "Available providers: $p"

if($null -eq  ($p | Where-Object { $_.Name.Contains("NuGet") -eq $true } ) )
{
    Write-UpliftMessage "Installing Nuget Package provider..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

    Write-UpliftMessage "Updating PSGallery as Trusted"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
else
{
    Write-UpliftMessage "No update required."
}

Write-UpliftMessage "Adding PSGallery: subpointsolutions-staging"
New-UpliftPSRepository 'subpointsolutions-staging'  `
            'https://www.myget.org/F/subpointsolutions-staging/api/v2'

exit 0
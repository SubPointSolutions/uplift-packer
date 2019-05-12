# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing Chocolatey packages..."
Write-UpliftEnv

$packages = @(
    # using for unpacking ISO and zip archives
    @{ Id = "7zip"; Version = "" }

    # dev basics!
    @{ Id = "git"; Version = "" }

    # using for better file download experience
    # PowerShell can't handle huge files over seevral Gb
    @{ Id = "wget"; Version = "1.20" }
    @{ Id = "curl"; Version = "" }

    # modern PowerShell experience
    @{ Id = "pwsh"; Version = "" }
)

Write-UpliftMessage "Installing packages: $packages"

foreach($package in $packages ) {

    Write-UpliftMessage "`tinstalling package: $($package['Id']) $($package['Version'])"

    if ([System.String]::IsNullOrEmpty($package["Version"]) -eq $true) {
        choco install -y $package["Id"] --limit-output --acceptlicense --no-progress
    } else {
        choco install -y $package["Id"] --version $package["Version"] --limit-output --acceptlicense --no-progress
    }

    Confirm-UpliftExitCode $LASTEXITCODE "Cannot install package: $($package['Id']) $($package['Version'])"
}

exit 0
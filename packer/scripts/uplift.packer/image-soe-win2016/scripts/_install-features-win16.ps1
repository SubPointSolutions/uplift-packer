
# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftInfoMessage "Installing Windows Server 2016 features..."
Write-UpliftEnv

$installFeatures = @(
    #"Net-Framework-Features"
)

$uninstallFeatures = @(
    "Windows-Defender-GUI",
    "Windows-Defender"
)

Write-UpliftInfoMessage "Installing features: [$installFeatures]"

foreach($feature in $installFeatures) {
    Write-UpliftInfoMessage "Installing feature: [$feature]"
    Install-WindowsFeature -Name $feature | Out-Null
}

Write-UpliftInfoMessage "Adding features: [$addFeatures]"

foreach($feature in $addFeatures) {
    Write-UpliftInfoMessage "Installing feature: [$feature]"
    Add-WindowsFeature -Name $feature | Out-Null
}

Write-UpliftInfoMessage "Uninstalling features: [$uninstallFeatures]"

foreach($feature in $uninstallFeatures) {

    Write-UpliftInfoMessage "Checking if feature: [$feature] exists"

    if( $null -ne (Get-WindowsFeature -Name $feature -ErrorAction SilentlyContinue) )
    {
        Write-UpliftInfoMessage "Uninstalling [$feature] features..."
        Uninstall-WindowsFeature -Name $feature | Out-Null
    }
    else {
        Write-UpliftInfoMessage "Didn't detect [$feature]. No uninstall is required. Skipping."
    }
}
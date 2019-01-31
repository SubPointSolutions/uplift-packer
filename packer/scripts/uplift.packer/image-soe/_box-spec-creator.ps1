# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Creating box specs for further extraction"
Write-UpliftEnv

$filePath = Get-UpliftEnvVariable "UPLF_BOX_SPEC_FILE" "" "c:/_uplift_metadata/box-spec.json"

$obj = (Get-Content -Raw -Path $filePath -ErrorAction SilentlyContinue `
        | ConvertFrom-Json)

if ($null -eq $obj) {
    $obj = New-Object PSObject -Property @{ }
}

Write-UpliftMessage "Creating Win32_Product info..."
$obj | Add-Member -Name "Win32_Product" `
    -Type NoteProperty `
    -Value (get-wmiobject Win32_Product  ) `
    -Force

Write-UpliftMessage "Creating Get-HotFix info..."
$obj | Add-Member -Name "Get_HotFix" `
    -Type NoteProperty `
    -Value (get-hotfix) `
    -Force

Write-UpliftMessage "Creating Win32_OperatingSystem info..."
$obj | Add-Member -Name "Win32_OperatingSystem" `
    -Type NoteProperty `
    -Value (get-wmiobject -class Win32_OperatingSystem  ) `
    -Force

Write-UpliftMessage "Creating Get-InstalledModule info..."
$obj | Add-Member -Name "Get_InstalledModule" `
    -Type NoteProperty `
    -Value ( Get-InstalledModule  ) `
    -Force

Write-UpliftMessage "Creating Get-PSRepository info..."
$obj | Add-Member -Name "Get_PSRepository" `
    -Type NoteProperty `
    -Value ( Get-PSRepository  ) `
    -Force

Write-UpliftMessage "Creating Get-WindowsFeature info..."
$obj | Add-Member -Name "Get_WindowsFeature" `
    -Type NoteProperty `
    -Value ( Get-WindowsFeature  ) `
    -Force

Write-UpliftMessage "Creating Win32_LogicalDisk info..."
$obj | Add-Member -Name "Win32_LogicalDisk" `
    -Type NoteProperty `
    -Value (Get-WmiObject -Class Win32_LogicalDisk  ) `
    -Force

# only if choco is installed
if($null -ne (Get-Command "choco.exe" -ErrorAction SilentlyContinue) ) {

    Write-UpliftMessage "Creating chocolatey info..."
    $chocoPackages = @()

    # https://github.com/chocolatey/choco/issues/359#issuecomment-123806980
    $chocoPackageLines = (choco list --local-only -r | ForEach-Object { $_.split( [Environment]::NewLine ) }  )

    foreach($chocoPackageLine in $chocoPackageLines ) {
        $packagePair = $chocoPackageLine.Split('|')

        $id      = $packagePair[0]
        $version = $packagePair[1]

        $chocoPackages += New-Object PSObject -Property @{
            Id = $id
            Version = $version
        }

    }
    $obj | Add-Member -Name "Choco_Packages" `
        -Type NoteProperty `
        -Value ($chocoPackages ) `
        -Force
}

New-UpliftFolder (Split-Path $filePath)

$obj | ConvertTo-Json -Depth 3 `
    | Out-File -FilePath $filePath -Force

exit 0
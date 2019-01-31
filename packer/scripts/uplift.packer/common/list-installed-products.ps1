
$ErrorActionPreference = "Stop"

Get-WmiObject Win32_Product `
    | Sort-Object -Property Name `
    | Format-Table IdentifyingNumber, Name, LocalPackage -AutoSize
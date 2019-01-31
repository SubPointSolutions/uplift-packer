
$ErrorActionPreference = "Stop"

Write-Host "Win32_OperatingSystem info..."
get-wmiobject -class Win32_OperatingSystem 

# Get-HotFix

exit 0
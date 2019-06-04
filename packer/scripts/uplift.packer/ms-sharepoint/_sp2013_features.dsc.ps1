# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "[~] Installing SharePoint 2013 specific features"
Write-UpliftEnv


exit 0
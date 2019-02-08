# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "[~] Installing SharePoint specific PowerShell modules"
Write-UpliftEnv

$packages = @(

    @{
        Id = "SqlServerDsc";       
        Version = @(
            "12.2.0.0",
            "12.1.0.0",
            "12.0.0.0",

            "11.4.0.0",
            "11.3.0.0",
            "11.2.0.0",
            "11.1.0.0",
            "11.0.0.0",

            "10.0.0.0"
        )
    }
)

Install-UpliftPSModules $packages

exit 0
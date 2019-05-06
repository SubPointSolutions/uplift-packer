# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "[~] Installing SharePoint specific PowerShell modules"
Write-UpliftEnv

$packages = @(

    @{ 
        Id = "xCredSSP";       
        Version = @(
            "1.3.0.0"
        )
    },

    @{ 
        Id = "SharePointDSC";       
        Version = @(
            "3.3.0.0",
            "3.2.0.0",
            "3.1.0.0",
            "3.0.0.0",

            "2.6.0.0",
            "2.5.0.0",
            "2.4.0.0",
            "2.3.0.0",
            "2.2.0.0",
            "2.1.0.0",
            "2.0.0.0",

            "1.9.0.0",
            "1.8.0.0"
        )
    }
)

Install-UpliftPSModules $packages

exit 0
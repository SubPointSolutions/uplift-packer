# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Preparing PowerShell modules"
Write-UpliftEnv

# - install other DSC packages
$packages = @(

    @{ 
        Id = "xExchange"
        Version = @(
            "1.27.0.0"
            "1.26.0.0"
            "1.25.0.0"
            "1.24.0.0"
            "1.23.0.0"
            "1.21.0.0"
            "1.22.0.0"
            "1.20.0.0"
        )
    }

    @{ 
        Id = "xActiveDirectory"
        Version = @(
            "2.25.0.0"
        )
    }
)

Write-UpliftMessage "Installing DSC modules: $packages"
Install-UpliftPSModules $packages

exit 0
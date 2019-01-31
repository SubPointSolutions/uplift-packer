# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

# core script to bootstrap uplift modiles

function Set-UpliftBootstrap() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

    param(

    )    

    function Install-LatestPSModule() {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope = "Function")]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

        param(
            $moduleName, 
            $version,
            $repository
        )

        if( [String]::IsNullOrEmpty($version) -eq $True) {
            $version = $null
        }

        Write-Host "Installing module: $moduleName version: $version"

        Write-Host "Looking for the latest module $moduleName"
        $moduleDefinition = Find-Module -Name $moduleName `
            | Select-Object Version, Repository `
            | Sort-Object Version -Descending `
            | Select-Object -First 1

        Write-Host "Found module:"
        Write-Host $moduleDefinition
        Write-Host " - version   : $($moduleDefinition.Version)"
        Write-Host " - repository: $($moduleDefinition.Repository)"
    
        if ($null -eq $version) {

            if($null -eq $moduleDefinition) {
                throw "Failed to install module $moduleName - repo/version were not provided, and cannot find latest in any repo!"
            }

            $version = $moduleDefinition.Version

            if($null -eq $repository) {
                $repository = $moduleDefinition.Repository
            }

            Write-Host "Installing latest ($version) from repo: $repository"
            Install-Package $moduleName -Source $repository -RequiredVersion $version -Force
        }
        else {
            if($null -eq $repository) {
                $repository = $moduleDefinition.Repository
            }

            Write-Host "Installing specified version $version from repo: $repository"
            Install-Package $moduleName -Source $repository -Force  -RequiredVersion $version
        }

        Write-Host "Checking installed module: $moduleName"
        $installeModule = Get-InstalledModule $moduleName

        if ($null -eq $installeModule) {
            throw "Cannot find installed module: $moduleName"
        }
        else {
            Write-Host "All good! Installed module:"
            
            Write-Host " - name   : $($installeModule.Name)"
            Write-Host " - version: $($installeModule.Version)"
        }    
    }

    function New-UpliftPSRepositoryRegistration {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope = "Function")]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

        param(
            $name,
            $source,
            $providerublish = $null,
            $installPolicy = "Trusted"
        )
    
        $repo = Get-PSRepository `
            -Name $name `
            -ErrorAction SilentlyContinue
    
        if ($null -eq $repo) {
            Write-Host " [~] Regestering repo: $name"
            Write-Host " - path: $source"
            Write-Host " - installPolicy: $installPolicy"
    
            if ($null -eq $providerublish) {
                Write-Host " - publish location: $source"
    
                Register-PSRepository -Name $name `
                    -SourceLocation $source `
                    -PublishLocation $source `
                    -InstallationPolicy $installPolicy
            }
            else {
                Write-Host " - publish location: $source"
    
                Register-PSRepository -Name $name `
                    -SourceLocation $source `
                    -PublishLocation $providerublish `
                    -InstallationPolicy $installPolicy
            }
    
        }
        else {
            Write-Host "Repo exists: $name"
        }
    }

    Write-Host "Bootstrapping uplift modules..."
    $provider = Get-PackageProvider -ListAvailable

    Write-Host "Available providers: $provider"

    if ($null -eq ($provider | Where-Object { $_.Name.Contains("NuGet") -eq $true } ) ) {
        Write-Host "Installing Nuget Package provider..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

        Write-Host "Updating PSGallery as Trusted"
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    else {
        Write-Host "No update required."
    }

    Write-Host "Adding PSGallery: subpointsolutions-staging"
    New-UpliftPSRepositoryRegistration 'subpointsolutions-staging'  `
        'https://www.myget.org/F/subpointsolutions-staging/api/v2'

    Install-LatestPSModule `
        "Uplift.Core" `
        ($env:UPLF_UPLIFT_CORE_MODULE_VERSION) `
        ($env:UPLF_UPLIFT_CORE_MODULE_REPOSITORY)
}

Set-UpliftBootstrap

exit 0
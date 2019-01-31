# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Transferring SharePoint update files..."
Write-UpliftEnv

$upliftSPBinResourceName     = Get-UpliftEnvVariable "UPLF_SP_BIN_RESOURCE_NAME" 
$upliftSPUpdateResourceNames = Get-UpliftEnvVariable "UPLF_SP_UPDATE_RESOURCE_NAMES" "" ""

$upliftHttpServer     =  Get-UpliftEnvVariable "UPLF_HTTP_ADDR"
$uplifLocalRepository =  Get-UpliftEnvVariable "UPLF_LOCAL_REPOSITORY_PATH" "" "c:/_uplift_resources"

# always turn into http, it might be 10.0.2.2 address only
# uplift needs explicit http/https only
if($upliftHttpServer.ToLower().StartsWith("http") -eq $False) {
    $upliftHttpServer = "http://" + $upliftHttpServer
}

# download all sharepoint updates and place into   $uplifLocalRepository/$$upliftSPBinResourceName/latest/updates

$spUpdatesFolder = "$uplifLocalRepository/$upliftSPBinResourceName/latest/updates"

Write-UpliftMessage " - sp bin resource name     : $upliftSPBinResourceName"
Write-UpliftMessage " - sp update resource names : $upliftSPUpdateResourceNames"
Write-UpliftMessage " - sp updates folder        : $spUpdatesFolder"

Write-UpliftMessage " - http server url: $upliftHttpServer"
Write-UpliftMessage " - local repo     : $uplifLocalRepository"

$updateResourceNames = $upliftSPUpdateResourceNames.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
$updateResourceCount = $updateResourceNames.Count
$index = 1

if($updateResourceNames.Count -eq 0) {
    Write-UpliftInfoMessage "[!] no update resources were specified, returning"
    exit 0
}

foreach($updateResourceName in $updateResourceNames ) {

    Write-UpliftMessage "[$index/$updateResourceCount] downloading resource: $updateResourceName"

    pwsh -c "Invoke-Uplift resource download-local $updateResourceName -server $upliftHttpServer -repository $uplifLocalRepository -debug"
    Confirm-UpliftExitCode $LASTEXITCODE "Cannot download resource: $upliftResourceName"
    
    $resourceFolderPath = "$uplifLocalRepository/$updateResourceName/latest"
    Write-UpliftMessage " - looking for exe/msi in path: $resourceFolderPath"
    $filePath = Find-UpliftFileInPath $resourceFolderPath

    if( $null -eq $filePath ) {
        throw "Cannot find exe/msi in path: $resourceFolderPath"
    }

    if( (Test-Path $filePath) -eq $False  ) {
        throw "Cannot find file: $filePath"
    }

    Write-UpliftMessage " - extracting update $updateResourceName to /updates folder"
    Write-UpliftMessage "   - scr: $filePath"
    Write-UpliftMessage "   - dst: $spUpdatesFolder"

    # Slipstream packaging
    # https://docs.microsoft.com/en-us/sharepoint/upgrade-and-update/prepare-to-deploy-software-updates#slipstream-package

    $process = Start-Process $filePath -ArgumentList "/extract:$spUpdatesFolder /quiet" -PassThru -Wait
    
    if($process.ExitCode -ne 0) {
        throw "Exit code: $($process.ExitCode) - cannot extract update $updateResourceName to /updates folder"
    }
    
    $index = $index + 1
}

Write-UpliftMessage "Listing SharePoint updates folder: $spUpdatesFolder"
dir $spUpdatesFolder

exit 0
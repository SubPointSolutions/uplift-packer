# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Transferring SQL Server 2016 update files..."
Write-UpliftEnv

$upliftSqlBinResourceName     = Get-UpliftEnvVariable "UPLF_SQL_BIN_RESOURCE_NAME" 
$upliftSqlUpdateResourceNames = Get-UpliftEnvVariable "UPLF_SQL_UPDATE_RESOURCE_NAMES" "" ""

$upliftHttpServer     =  Get-UpliftEnvVariable "UPLF_HTTP_ADDR"
$uplifLocalRepository =  Get-UpliftEnvVariable "UPLF_LOCAL_REPOSITORY_PATH" "" "c:/_uplift_resources"

# always turn into http, it might be 10.0.2.2 address only
# uplift needs explicit http/https only
if($upliftHttpServer.ToLower().StartsWith("http") -eq $False) {
    $upliftHttpServer = "http://" + $upliftHttpServer
}

# download all sql updates and place into $uplifLocalRepository/$$upliftSqlBinResourceName/latest/updates

$supdatesFolder = "$uplifLocalRepository/$upliftSqlBinResourceName/latest/updates"

Write-UpliftMessage " - sql bin resource name     : $upliftSqlBinResourceName"
Write-UpliftMessage " - sql update resource names : $upliftSqlUpdateResourceNames"
Write-UpliftMessage " - sql updates folder        : $supdatesFolder"

Write-UpliftMessage " - http server url: $upliftHttpServer"
Write-UpliftMessage " - local repo     : $uplifLocalRepository"

$updateResourceNames = $upliftSqlUpdateResourceNames.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
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
    Write-UpliftMessage "   - dst: $supdatesFolder"

    # just copy update
    [System.IO.Directory]::CreateDirectory( $supdatesFolder) | Out-Null 
    Copy-Item -Path $filePath -Destination $supdatesFolder -Force

    # Slipstream packaging
    # https://www.sqlshack.com/slipstreaming-sql-server-2012-2014/

    # $process = Start-Process $filePath -ArgumentList "/extract:$supdatesFolder /quiet" -PassThru -Wait
    
    # if($process.ExitCode -ne 0) {
    #    throw "Exit code: $($process.ExitCode) - cannot extract update $updateResourceName to /updates folder"
    #}
    
    $index = $index + 1
}

Write-UpliftMessage "Listing SQL updates folder: $supdatesFolder"
dir $supdatesFolder

exit 0
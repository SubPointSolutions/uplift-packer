# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Transferring resource files..."
Write-UpliftEnv

# get it natively, it might be null under Vagrant, or Packer + VirtualBox on win2008 host

$upliftResourceName   =  Get-UpliftEnvVariable "UPLF_RESOURCE_NAME"
$upliftHttpServer     =  Get-UpliftEnvVariable "UPLF_HTTP_ADDR"
$uplifLocalRepository =  Get-UpliftEnvVariable "UPLF_LOCAL_REPOSITORY_PATH" "" "c:/_uplift_resources"

# always turn into http, it might be 10.0.2.2 address only
# uplift needs explicit http/https only
if($upliftHttpServer.ToLower().StartsWith("http") -eq $False) {
    $upliftHttpServer = "http://" + $upliftHttpServer
}

Write-UpliftMessage " - resource name  : $upliftResourceName"
Write-UpliftMessage " - http server url: $upliftHttpServer"
Write-UpliftMessage " - local repo     : $uplifLocalRepository"

pwsh -c "Invoke-Uplift resource download-local $upliftResourceName -server $upliftHttpServer -repository $uplifLocalRepository -debug"
Confirm-UpliftExitCode $LASTEXITCODE "Cannot download resource: $upliftResourceName"

exit 0
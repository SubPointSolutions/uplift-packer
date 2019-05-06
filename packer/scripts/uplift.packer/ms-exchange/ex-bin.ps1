# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Downloading resource..."
Write-UpliftEnv

$resourceName = Get-UpliftEnvVariable "UPLF_EXCHANGE_RESOURCE_NAME" "" "ms-exchange2016-update-2019.02.12-kb4471392-cu12"
$serverUrl    = Get-UpliftEnvVariable "UPLF_HTTP_ADDR"

$uplifLocalRepository =  Get-UpliftEnvVariable "UPLF_LOCAL_REPOSITORY_PATH" "" "c:/_uplift_resources"

# always turn into http, it might be 10.0.2.2 address only
# uplift needs explicit http/https only
if($serverUrl.ToLower().StartsWith("http") -eq $False) {
    $serverUrl = "http://" + $serverUrl
}

Write-UpliftMessage "Downloading resource: $resourceName"
pwsh -c Invoke-Uplift resource download-local $resourceName -server $serverUrl -repository $uplifLocalRepository

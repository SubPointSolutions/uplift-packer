
# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Running SharePoint lang pack insall..."
Write-UpliftEnv

$defaultLangPackResourceNamesString = [String]::Join(",",  @(
    'ms-sharepoint2016-lang-pack-ar-sa'
    'ms-sharepoint2016-lang-pack-cs-cz'
    'ms-sharepoint2016-lang-pack-da-dk'
    'ms-sharepoint2016-lang-pack-de-de'
    'ms-sharepoint2016-lang-pack-fr-fr'
    'ms-sharepoint2016-lang-pack-fi-fi'
    'ms-sharepoint2016-lang-pack-nl-nl'
    'ms-sharepoint2016-lang-pack-he-il'
    'ms-sharepoint2016-lang-pack-hi-in'
    'ms-sharepoint2016-lang-pack-kk-kz'
    'ms-sharepoint2016-lang-pack-it-it'
    'ms-sharepoint2016-lang-pack-lv-lv'
    'ms-sharepoint2016-lang-pack-pl-pl'
    'ms-sharepoint2016-lang-pack-ru-ru'
    'ms-sharepoint2016-lang-pack-ro-ro'
    'ms-sharepoint2016-lang-pack-es-es'
    'ms-sharepoint2016-lang-pack-sv-se'
    'ms-sharepoint2016-lang-pack-uk-ua'
) )

$langPackResourceNames = Get-UpliftEnvVariable "UPLF_SP_LANG_PACK_RESOURCE_NAMES" "" $defaultLangPackResourceNamesString

$upliftHttpServer     =  Get-UpliftEnvVariable "UPLF_HTTP_ADDR"
$uplifLocalRepository =  Get-UpliftEnvVariable "UPLF_LOCAL_REPOSITORY_PATH" "" "c:/_uplift_resources"

# always turn into http, it might be 10.0.2.2 address only
# uplift needs explicit http/https only
if($upliftHttpServer.ToLower().StartsWith("http") -eq $False) {
    $upliftHttpServer = "http://" + $upliftHttpServer
}

$langPackResourceNames = $langPackResourceNames.Split(',')
$langPackFolders = @()

Write-UpliftMessage " - resource names  : $langPackResourceNames"
Write-UpliftMessage " - http server url: $upliftHttpServer"
Write-UpliftMessage " - local repo     : $uplifLocalRepository"

function Invoke-UnpackLanguagePack($src, $dst) {

    # sp2016 serverlanguagepack.exe
    $exePath = $src + "/serverlanguagepack.exe"
    $isoPath = $src + "/serverlanguagepack.img"
    
    Remove-Item $dst -Force -Recurse -ErrorAction SilentlyContinue

    if( (test-Path $exePath) -eq $True) {
        # sharepoint 2016
        Write-UpliftMessage " - unpacking exe: $exePath"
        . $exePath /extract:$dst /quiet

    } elseif( (test-Path $isoPath) -eq $True) {
        # sharepoint 2013
        Write-UpliftMessage " - unpacking iso: $isoPath"
        
        if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"}
        set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"

        Write-UpliftMessage " - cmd:  sz x -y $localFilePath -o$dst"

        sz x -y "$isoPath" "-o$dst"
        Confirm-UpliftExitCode $LASTEXITCODE "Failed to unpack: $localFilePath"

    }  else {
        # sharepoint v-next? 
        $errMessage = "Cannot detect serverlanguagepack.exe or serverlanguagepack.img in folder: $src"

        Write-UpliftErrorMessage $errMessage
        throw $errMessage
    }

    # output, just in case
    dir $dst
}

foreach($langPackResourceName in $langPackResourceNames) {
    
    # don't unpack .iso/.img (-skip-unpack)
    # we have Invoke-UnpackLanguagePack for this case

    pwsh -c "Invoke-Uplift resource download-local $langPackResourceName -server $upliftHttpServer -repository $uplifLocalRepository -debug -skip-unpack"
    Confirm-UpliftExitCode $LASTEXITCODE "Cannot download resource: $langPackResourceName"

    Invoke-UnpackLanguagePack `
        "$uplifLocalRepository/$langPackResourceName/latest/" `
        "$uplifLocalRepository/$langPackResourceName/$langPackResourceName"

    $langPackFolders += "$uplifLocalRepository/$langPackResourceName/$langPackResourceName"
}

Configuration SharePoint_LangPacks
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc -ModuleVersion "1.9.0.0"

    node "localhost"
    {
        foreach($langPackFolder in $Node.LangPackFolders) {
            $resourceName = Split-Path $langPackFolder -Leaf
            $resourcePath = $langPackFolder

            SPInstallLanguagePack "InstallLangPack-$resourceName"
            {
                BinaryDir  = $resourcePath
                Ensure     = "Present"
            }
        }
    }
}

$config = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'

            PSDscAllowDomainUser        = $true
            PSDscAllowPlainTextPassword = $true

            RetryCount = 10
            RetryIntervalSec = 30

            LangPackFolders = $langPackFolders
        }
    )
}

$configuration = Get-Command SharePoint_LangPacks
Start-UpliftDSCConfiguration $configuration $config $True

exit 0
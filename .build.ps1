
param(
    $packerImageName = "ubuntu-trusty64",

    $UPLF_GIT_BRANCH = $null,
    $UPLF_GIT_COMMIT = $null,

    # input-output boxes for packer-vagrant builder
    $UPLF_INPUT_BOX_NAME = $null,
    $UPLF_OUTPUT_DIRECTORY = $null,
    $UPLF_VAGRANT_BOX_OUTPUT = $null,

    # iso builder
    $UPLF_VBMANAGE_MACHINEFOLDER = $null,

    $UPLF_SCRIPTS_PATH = $null,
    $UPLF_HTTP_DIRECTORY = $null,

    # compression level to be used in post processor
    # packer doco - 0 being no compression and 9 being the best compression. 
    # by default, compression is enabled at level 6.
    # https://packer.io/docs/post-processors/vagrant.html#compression_level
    $UPLF_COMPRESSION_LEVEL = $null,

    # folder on a remote host to be used as
    # a temporary storage for file resources
    # - notmally, DO NOT CHANGE this one
    $UPLF_LOCAL_REPOSITORY_PATH = $null,

    $UPLF_ISO_URL = $null,
    $UPLF_ISO_CHECKSUM = $null,
    $UPLF_ISO_CHECKSUM_TYPE = $null,

    $UPLF_DISK_SIZE = $null,

    $UPLF_VBOXMANAGE_MEMORY = $null,
    $UPLF_VBOXMANAGE_CPUS = $null,
    $UPLF_VBOXMANAGE_CPUEXECUTIONCAP = "100",

    # hardened soe image
    $UPLF_SSU_RESOURCE_NAME = $null,
    $UPLF_SSU_NAME = $null,
    $UPLF_SSU_FILE_NAME = $null,

    $UPLF_KB_RESOURCE_NAME = $null,
    $UPLF_KB_NAME = $null,
    $UPLF_KB_FILE_NAME = $null,

    # sharepoint
    $UPLF_SP_RESOURCE_NAME = $null,
    $UPLF_SP_PRODUCT_KEY = $null,
    $UPLF_SP_FP2_RESOURCE_NAME = $null,

    # sql
    $UPLF_SQL_RESOURCE_NAME = $null,
    $UPLF_SQL_STUDIO_RESOURCE_NAME = $null,
    $UPLF_SQL_STUDIO_PRODUCT_ID = $null,

    # uplift module
    #$UPLF_INVOKEUPLIFT_MODULE_VERSION      = "0.1.20190112.144316",
    $UPLF_INVOKEUPLIFT_MODULE_VERSION      = $null,
    $UPLF_INVOKEUPLIFT_MODULE_REPOSITORY   = $null,
    
    # $UPLF_UPLIFT_CORE_MODULE_VERSION  = "0.1.20190117.214947",
    $UPLF_UPLIFT_CORE_MODULE_VERSION    = $null,
    $UPLF_UPLIFT_CORE_MODULE_REPOSITORY = $null,

    # https://www.vagrantup.com/docs/other/environmental-variables.html
    $VAGRANT_DOTFILE_PATH = $null,
    $VAGRANT_BOX_UPDATE_CHECK_DISABLE = $null,
    $VAGRANT_CHECKPOINT_DISABLE = $null,
    $VAGRANT_DEFAULT_PROVIDER = $null,
    $VAGRANT_DETECTED_OS = $null,
    $VAGRANT_FORCE_COLOR = $null,
    $VAGRANT_HOME = $null,
    $VAGRANT_IGNORE_WINRM_PLUGIN = $True,
    $VAGRANT_LOG = $null,
    $VAGRANT_NO_COLOR = $null,
    $VAGRANT_NO_PARALLEL = $null,
    $VAGRANT_VAGRANTFILE = $null,

    # vagrant auth token to Vagrant Cloud
    $VAGRANT_CLOUD_AUTH_TOKEN = $null,
    $VAGRANT_CLOUD_BOX_VERSION = $null,
    $VAGRANT_CLOUD_RELEASE = $null,

    # https://www.packer.io/docs/other/environment-variables.html
    $PACKER_CACHE_DIR = $null,
    $PACKER_CONFIG = $null,
    $PACKER_LOG = $null,
    $PACKER_LOG_PATH = $null,
    $PACKER_NO_COLOR = $null,
    $PACKER_PLUGIN_MAX_PORT = $null,
    $PACKER_PLUGIN_MIN_PORT = $null,

    # QA params
    $QA_FIX = $null,

    # No AppInsight flag
    $UPLF_NO_APPINSIGHT = $null,

    # box export options
    $UPLF_EXPORT_BOX_PREFIX = 'uplift-local',
    $UPLF_EXPORT_BOX_PATH   = 'build-export-boxes'
)

$dirPath = $BuildRoot
# $scriptPath = $MyInvocation.MyCommand.Name

. "$dirPath/.build-helpers.ps1"
. "$dirPath/.build-appinsights.ps1"

Confirm-UpliftUpliftAppInsightClient

# Build Scripts Guidelines
# https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-Guidelines

$container = $null;

function Get-AppInsightProperties($container) {
    if($container -eq $null) {
        return $null   
    }

    $hash = @{
        "BuildTask" = $script:BuildTask
        "PackerImageName" = $container.PackerImageName
        "BuildId" = $container.BuildId.ToString()
        "Elapsed" = $script:Stopwatch.ElapsedMilliseconds.ToString()
        "GitBranchName" = $container.GitBranchName.ToString()
        "GitBranchCommit" = $container.GitBranchCommit.ToString()
    }

    # current build status
    $hash.Add("Success", ($ERROR.Count -eq 0) )

    # build host
    $buildAgent = "uplift-packer"
    if($null -ne $env:JENKINS_HOME) {
       $buildAgent = "uplift-jenkins"
    } 

    $hash.Add("BuildAgent", $buildAgent)

    return $hash
}

function Get-AppInsightMetrics($container) {
    return $null
}

Enter-Build {

    Update-EnvVariables

    $script:Stopwatch = [Diagnostics.Stopwatch]::StartNew()

    $httpServerSession = New-UpliftHttpServerSession $packerImageName
    $container = New-PackerBuildContainer $packerImageName $httpServerSession

    New-UpliftTrackEvent "packer.build.start" `
        (Get-AppInsightProperties $container) `
        (Get-AppInsightMetrics $container)

    Write-BuildInfoMessage "Build container:"
    $buildContainerJson = ($container | ConvertTo-JSON)
    Write-BuildDebugMessage $buildContainerJson

    # saving current build container metadata
    $buildContainerJson | Out-File ($container.BuildDir + "/.build-container.json") -Force

    $gitBranch =  Get-GitBranchName $UPLF_GIT_BRANCH
    $gitCommit =  Get-GitCommit     $UPLF_GIT_COMMIT

    Write-BuildInfoMessage " - branch: $gitBranch"
    Write-BuildInfoMessage " - commit: $gitCommit"

    # ensure packer plugin
    $packerPlugingPath = '';
    $packerPluginUrl   = ''
    $packerPluginFileName = ''
    
    if($IsWindows) {
        $packerPlugingPath = Join-Path -Path $ENV:APPDATA -ChildPath 'packer.d/plugins'
        [System.IO.Directory]::CreateDirectory($packerPlugingPath) | Out-Null    

        $packerPluginUrl      = 'https://github.com/themalkolm/packer-builder-vagrant/releases/download/v2018.10.15/packer-1.2.5_packer-builder-vagrant_windows_amd64.exe'
        $packerPluginFileName = 'packer-builder-vagrant.exe'

    } elseif($IsMacOS -eq $True) {
        $packerPlugingPath = Resolve-Path "~/.packer.d/plugins"
        [System.IO.Directory]::CreateDirectory($packerPlugingPath) | Out-Null    

        $packerPluginUrl   = 'https://github.com/themalkolm/packer-builder-vagrant/releases/download/v2018.10.15/packer-1.2.5_packer-builder-vagrant_darwin_amd64'
        $packerPluginFileName = 'packer-builder-vagrant'
    } 
    
    $packerPlugingFilePath = Join-Path -Path $packerPlugingPath -ChildPath $packerPluginFileName 

    if( (Test-Path $packerPlugingFilePath) -eq $False) {
        Write-BuildWarningMessage "[~] downloading packer plugin for the first time only"
        Write-BuildWarningMessage " - src: $packerPluginUrl"
        Write-BuildWarningMessage " - dst: $packerPlugingFilePath"
       
        Invoke-WebRequest -Uri $packerPluginUrl `
                        -OutFile $packerPlugingFilePath 
        
    } else {
        Write-BuildInfoMessage "[+] packer plugin exists: $packerPluginFileName"
    }

    if( ($IsWindows -eq $True) ) {
        
        $winPath2 = Join-Path -Path $env:UserProfile -ChildPath "packer.d/plugins/$packerPluginFileName"
    
        if ( (Test-Path $winPath2) -eq $False) {
            [System.IO.Directory]::CreateDirectory( (Join-Path -Path $env:UserProfile -ChildPath "packer.d/plugins/") ) | Out-Null
            
            # %APPDATA%/packer.d/plugins
            # Default folder for plugin seems to have changed with version 1.3.3 #7160
            
            Invoke-WebRequest -Uri $packerPluginUrl `
                -OutFile $winPath2
        }
    }

    if($null -ne $UPLF_VBMANAGE_MACHINEFOLDER) {
        Write-BuildWarningMessage "[!] setting custom vboxmanage machine folder: $UPLF_VBMANAGE_MACHINEFOLDER"
        pwsh -c "vboxmanage setproperty machinefolder $UPLF_VBMANAGE_MACHINEFOLDER"
    }

}

Exit-Build {
    
    $err = $null
    
    try {
        if($null -ne $UPLF_VBMANAGE_MACHINEFOLDER) {
            Write-BuildWarningMessage "[!] reverting vboxmanage machine folder to default"
            pwsh -c 'vboxmanage setproperty machinefolder default'
        }
    }
    catch {
        $err = $_
    }
    finally {
        New-UpliftTrackEvent "packer.build.finish" `
            (Get-AppInsightProperties $container) `
            (Get-AppInsightMetrics $container)

        if($null -ne $err) {
            New-UpliftTrackException $err.Exception `
                (Get-AppInsightProperties $container) `
                (Get-AppInsightMetrics $container)
        }
    }
}

task Checkout {

    $isGit = git rev-parse --is-inside-work-tree

    if ($isGit -eq "true") {
        Write-BuildInfoMessage " [~] showing git branch info"

        exec {
            # git pull
            git status

            git remote get-url origin
            git rev-parse --abbrev-ref HEAD
            git log --pretty=format:'%h' -n 1
        }
    }
    else {
        Write-BuildInfoMessage " [+] skipping showing git branch info"
    }
}

# Synopsis: Shows tools and versions
task ShowBuildTools {
    exec {
        Write-BuildInfoMessage " [+] packer"
        Set-PackerEnvVariables
        packer version

        Write-BuildInfoMessage " [+] vagrant"
        Set-VagrantEnvVariables
        vagrant version
    }
}

# Synopsis: Validates packer image
task PackerValidate {
    exec {
        Write-BuildInfoMessage " [~] validating packer config"

        packer validate `
            -var-file="$($container.VariablesFile)" `
            "$($container.PackerFile)"
    }
}

task PackerInspect {
    exec {
        Write-BuildInfoMessage " [~] inspecting packer config"

        packer inspect `
            "$($container.PackerFile)"
    }
}

# Synopsis: Builds packer image
task PackerBuildNoForce {
    Invoke-PackerBuild $false
}

# Synopsis: Builds packer image with --force flag
task PackerBuildForce {
    Invoke-PackerBuild $true
}

# Synopsis: Adds packer image as a vagrant box
task VagrantBoxAdd {
    Invoke-VagrantBoxAdd $false
}

# Synopsis: Adds packer image as a vagrant box with --force flag
task VagrantBoxAddForce {
    Invoke-VagrantBoxAdd $true
}

# Synopsis: Tests newly created vagrant box
task VagrantBoxTest {
    #exec {
        Write-BuildInfoMessage "Testing vagrant box, file: $($container.VagrantTestFile)"

        try {
            Copy-Item $container.VagrantTestFile `
                -Destination "$($container.PackerBuildDir)/" `
                -Force

            Copy-Item $container.VagrantTestScriptFile `
                -Destination "$($container.PackerBuildDir)/" `
                -Force

            Copy-Item $container.VagrantCleanupScriptFile `
                -Destination "$($container.PackerBuildDir)/" `
                -Force

            if( (Test-Path $container.VagrantTestScriptsFolder) -eq $True) {
            Copy-Item $container.VagrantTestScriptsFolder `
                -Destination "$($container.PackerBuildDir)/" `
                -Force -Recurse
            }
            
            $vagrantCwd = [String]( Resolve-Path $container.PackerBuildDir)
            
            Write-BuildInfoMessage "Using vagrantfile cwd: $vagrantCwd"

            $vagrantBoxName = ($container.VagrantBoxName)
            $ENV:UPLF_VAGRANT_BOX_NAME = $vagrantBoxName

            Write-BuildInfoMessage "Using vagrant box: $vagrantBoxName"
         
            if ($null -ne $UPLF_VBMANAGE_MACHINEFOLDER) {
                $ENV:UPLF_VBMANAGE_MACHINEFOLDER = $UPLF_VBMANAGE_MACHINEFOLDER
            }

            # promote local http server port to vagrant test builds
            $ENV:UPLF_BIN_REPO_HTTP_ADDR = ("10.0.2.2:" + $container.LocalHttpServerPort )

            Set-VagrantEnvVariables

            Write-BuildInfoMessage "Running: vagrant validate"
            pwsh -c "cd $vagrantCwd; vagrant validate"
            Confirm-ExitCode $LASTEXITCODE "Failed: vagrant validate"

            Write-BuildInfoMessage "Running: vagrant status"
            pwsh -c "cd $vagrantCwd; vagrant status"

            Write-BuildInfoMessage "Running: vagrant clean up script"
            pwsh -c "cd $vagrantCwd; . ./.vagrant-cleanup.ps1"
            Confirm-ExitCode $LASTEXITCODE "Failed: vagrant clean up script"
        
            # test
            Write-BuildInfoMessage "Running: vagrant-test.ps1"
            pwsh -c "cd $vagrantCwd; . ./.vagrant-test.ps1"
            Confirm-ExitCode $LASTEXITCODE "Failed: vagrant-test.ps1"

            # survived!
            Write-BuildWarningMessage "[+] PASSED ALL VAGRANT TESTS! This box looks really cool!"
        }
        catch {
            Write-BuildErrorMessage "ERR: $_"
            throw "Failed vagrant testing: $_"
        }
        finally {
            Write-BuildInfoMessage "Running: final vagrant clean up script"
            pwsh -c "cd $vagrantCwd; . ./.vagrant-cleanup.ps1"
        }
    #}
}

# Synopsis: Deletes 
task DeleteLinkedCloneVMs {
    Delete-LinkedCloneVMs
}

# Synopsis: Cleans up test Vagrant VMs
task VagrantBoxTestCleanup ?VagrantBoxTest, {
    exec {
        Write-BuildInfoMessage "Cleaning up vagrant test VMs, file: $($container.VagrantTestFile)"

        exec {
            $ENV:VAGRANT_VAGRANTFILE = $container.VagrantTestFile
            $ENV:UPLF_VAGRANT_BOX_NAME = Resolve-Path -Path $container.VagrantBoxFile -Relative

            Set-VagrantEnvVariables

            Write-BuildInfoMessage "vagrant destroy -f"
            vagrant destroy -f
        }
    }
}

function Get-BoxMetadataContent() {
    $branch = $script:UPLF_GIT_BRANCH
    $commit = $script:UPLF_GIT_COMMIT

    $projectGitHubUrl = "https://github.com/SubPointSolutions/uplift-packer";
    
    $projectGitHubBranchUrl = "$projectGitHubUrl/tree/$branch"
    $projectGitHubCommitUrl = "$projectGitHubUrl/commit/$commit"

    $content = [String]::Join(' | ', @(
        "<a href='https://github.com/SubPointSolutions/uplift-packer'>GitHub</a>",
        "Branch: <a href='$projectGitHubBranchUrl'>$branch</a>",
        "Commit: <a href='$projectGitHubCommitUrl'>$commit</a>"
    ) )

    return $content
}

# Synopsis: Exports Vagrant boxes to the giving location
task VagrantExportBoxes {

    $boxPrefix = $UPLF_EXPORT_BOX_PREFIX
    $boxPath   = Join-Path $UPLF_EXPORT_BOX_PATH "$($container.GitBranchName)/$($container.GitBranchCommit)"

    Write-BuildInfoMessage "[~] Exporting vagrant boxes"
    Write-BuildInfoMessage " - prefix : $boxPrefix"
    Write-BuildInfoMessage " - path   : $boxPath"

    [System.IO.Directory]::CreateDirectory($boxPath) | Out-Null 

    exec {
        Set-VagrantEnvVariables

        $vagrantBoxOutput = [String]((vagrant box list) |  Out-String)
        $vagrantBoxLines  = $vagrantBoxOutput.Split([Environment]::NewLine)
        
        foreach($vagrantBoxLine in $vagrantBoxLines) {
            $boxName = $vagrantBoxLine.Split(' ')[0].Trim()
            

            if($boxName.Contains($boxPrefix) -eq $True) {
                $boxFileName = ($boxName.Replace('/','-').Replace('\','-') + ".box")

                Write-BuildInfoMessage " exporting box: $boxName as $boxFileName"
                Write-BuildInfoMessage "Running: vagrant box repackage $boxName"
                
                if( (Test-Path "$boxPath/package.box") -eq $True) {
                    Remove-Item "$boxPath/package.box" -Force 
                }

                pwsh -c "cd $boxPath; vagrant box repackage $boxName virtualbox 0"

                if( (Test-Path "$boxPath/$boxFileName") -eq $True) {
                    Remove-Item "$boxPath/$boxFileName" -Force 
                }

                Rename-Item -Path "$boxPath/package.box" -NewName $boxFileName -Force

                Confirm-ExitCode $LASTEXITCODE "Failed: vagrant box repackage"
            }
        }
    }
}

# Synopsis: Publishes Vagrant box to Vagrant Cloud
task VagrantCloudPublish {
    Write-BuildInfoMessage "[~] Publishing vagtant box to Vagrant Cloud: $($container.VagrantBoxName)"

    $VAGRANT_CLOUD_AUTH_TOKEN = Get-VariableOrEnvVariable "VAGRANT_CLOUD_AUTH_TOKEN" `
        $VAGRANT_CLOUD_AUTH_TOKEN `
        "Vagrant Cloud token is required"

    exec {

        Set-VagrantEnvVariables

        Write-BuildInfoMessage "[~] auth with Vagrant Cloud..."

        $year  = [System.DateTime]::UtcNow.ToString("yy")
        $month = [System.DateTime]::UtcNow.ToString("MM")

        $day    = [System.DateTime]::UtcNow.ToString("dd")
        $minSec = [System.DateTime]::UtcNow.ToString("HHmm")
        
        # $stamp = "$dateStamp.$timeStamp"
        $boxVersion = "$year$month.$day.$minSec"

        if($null -ne $VAGRANT_CLOUD_BOX_VERSION) {     
            $boxVersion = $VAGRANT_CLOUD_BOX_VERSION
            Write-BuildWarningMessage "[!] using VAGRANT_CLOUD_BOX_VERSION box version: $boxVersion"
        }

        Write-BuildInfoMessage "[~] box version: $boxVersion"

        $publishBoxName = "subpointsolutions/$($container.VagrantPublishingBoxName)"
        $publishBoxVersion = $boxVersion

        # used to have .box file within the build folder
        # takes too much space - local box file in the build folder, and then another under the vagrant home path

        # publishing now exports vagrant box into a temporary box file
        # then pushes to vagrant cloud
        # then deletes temporary box from the local folder
        Set-VagrantEnvVariables

        $boxPublishingFolder = ($container.PackerBuildDir + "/box-publishing")
        [System.IO.Directory]::CreateDirectory($boxPublishingFolder) | Out-Null 

        Write-BuildInfoMessage "Running: vagrant box repackage"
        pwsh -c "cd $boxPublishingFolder; vagrant box repackage $($container.VagrantBoxName) virtualbox 0"
        Confirm-ExitCode $LASTEXITCODE "Failed: vagrant box repackage"

        $publishBoxSrcPath = ($boxPublishingFolder + "/package.box")

        $publishBoxDescription = "This is a regression box to ensure CI/CD pipeline for Packer/Vagrant"
        $publishBoxShortDescription = "Automated build by the uplift projct: box $publishBoxName"
        
        if( (Test-Path $container.PackerBuildReleaseNotesFile) -eq $True  ) {

            Write-BuildInfoMessage "[+] using release notes file: $($container.PackerBuildReleaseNotesFile)"

            $publishBoxVersionDescription += [Environment]::NewLine
            $publishBoxVersionDescription += [Environment]::NewLine

            $publishBoxVersionDescription += Get-Content -Raw $container.PackerBuildReleaseNotesFile
        } else {
            Write-BuildWarningMessage "[!!!] Release notes file does not exist: $($container.PackerBuildReleaseNotesFile)"

            $publishBoxVersionDescription += Get-BoxMetadataContent
        }

        $shouldRelease = ($null -ne $VAGRANT_CLOUD_RELEASE)

        Write-BuildWarningMessage "[!!!] Publishing box to Vagrant Cloud [!!!]"
        Write-BuildWarningMessage " - shouldRelease: $shouldRelease"
        

        Write-BuildInfoMessage " - box version: $publishBoxVersion"
        Write-BuildInfoMessage ""
        Write-BuildInfoMessage " - box name   : $publishBoxName"
        Write-BuildInfoMessage " - box src    : $publishBoxSrcPath"
        Write-BuildInfoMessage ""
        Write-BuildInfoMessage " - short   desc : $publishBoxDescription"
        Write-BuildInfoMessage " - long    desc : $publishBoxShortDescription"
        Write-BuildInfoMessage " - version desc : $publishBoxVersionDescription"

        try {

            Write-BuildInfoMessage "[~] vagrant cloud auth login"
            vagrant cloud auth login -t "$VAGRANT_CLOUD_AUTH_TOKEN"
            Confirm-ExitCode $LASTEXITCODE "[~] failed!"

            Write-BuildInfoMessage "[+] OK!"

            if($shouldRelease -eq $True) {
                Write-BuildInfoMessage "[~] [!RELEASE!] vagrant cloud publish..."

                vagrant cloud publish `
                    $publishBoxName `
                    $publishBoxVersion `
                    virtualbox `
                    $publishBoxSrcPath `
                    --description "$publishBoxDescription" `
                    --short-description "$publishBoxShortDescription" `
                    --version-description "$publishBoxVersionDescription" `
                    --force `
                    --release
            } else {
                Write-BuildInfoMessage "[~] [NO-RELEASE] vagrant cloud publish..."

                vagrant cloud publish `
                    $publishBoxName `
                    $publishBoxVersion `
                    virtualbox `
                    $publishBoxSrcPath `
                    --description "$publishBoxDescription" `
                    --short-description "$publishBoxShortDescription" `
                    --version-description "$publishBoxVersionDescription" `
                    --force
            }

            Confirm-ExitCode $LASTEXITCODE "[~] failed!"

            Write-BuildInfoMessage "[+] OK!"

        } catch {
            throw
        } finally {
            Write-BuildInfoMessage "[~] vagrant cloud auth login --logout"
            vagrant cloud auth login --logout
            
            Write-BuildInfoMessage "[~] deleting temporary box:  $publishBoxSrcPath"
            Remove-Item  $publishBoxSrcPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Synopsis: Runs PSScriptAnalyzer
task AnalyzeModule {
    exec {
        # https://github.com/PowerShell/PSScriptAnalyzer

        #$packerScriptsPath  = "packer/scripts"
        $folderPaths = Get-ChildItem . -Recurse `
            | ?{ $_.PSIsContainer } `
            | Select-Object FullName -ExpandProperty FullName

        foreach($folderPath in $folderPaths) {

            $filePaths = (Get-ChildItem -Path $folderPath -Filter *.ps1)

            foreach($filePathContainer in $filePaths) {
                $filePath = $filePathContainer.FullName
                
                if($filePath.Contains(".dsc.ps1") -eq $True -and $IsMacOS) {
                    Write-BuildWarningMessage " - skipping DSC validation under macOS"

                    Write-BuildInfoMessage " - file   : $filePath"
                    Write-BuildInfoMessage " - QA_FIX : $QA_FIX"

                    Write-BuildInfoMessage  " - https://github.com/PowerShell/PowerShell/issues/5707"
                    Write-BuildInfoMessage  " - https://github.com/PowerShell/PowerShell/issues/5970"
                    Write-BuildInfoMessage  " - https://github.com/PowerShell/MMI/issues/33"

                    continue;
                }
              
                Write-BuildInfoMessage " - file   : $filePath"
                Write-BuildInfoMessage " - QA_FIX : $QA_FIX"

                if($psFilesCount -eq 0) {
                    continue;
                }

                if($null -eq $QA_FIX) {
                    pwsh -c Invoke-ScriptAnalyzer -Path $filePath -EnableExit -ReportSummary
                    Confirm-ExitCode $LASTEXITCODE "[~] failed!"
                } else {
                    pwsh -c Invoke-ScriptAnalyzer -Path $filePath -EnableExit -ReportSummary -Fix
                }
            }
        }
    }
}

task CreateReleaseNotes {
    $boxSpecFile = Join-Path -Path $container.PackerBuildDir -ChildPath "box-spec/box-spec.json"

    Write-BuildInfoMessage "Box spec file: $boxSpecFile"
    $markDownTemplates = Get-Content -Raw -Path $container.VagrantReleaseFile

    if( (Test-Path $boxSpecFile ) -eq $False ) {
        Write-BuildWarningMessage "[~] box spec file does not exist. Won't create templated release notes"

        $contentTokens = @{
            '$BOX_METADATA$'  =  Get-BoxMetadataContent
        }

        foreach ($token in $contentTokens.Keys) {
            $value =  $contentTokens[$token]
            $markDownTemplates = $markDownTemplates.Replace($token, $value)
        }
    } else {
        Write-BuildWarningMessage "[~] box spec file exist. Creating templated release notes"
    
        $metadata = Get-Content -Raw -Path $boxSpecFile | ConvertFrom-Json
        
        $contentTokens = @{
            '$OS_NAME$'       = $metadata.Win32_OperatingSystem.Caption
            '$OS_VERSION$'    = $metadata.Win32_OperatingSystem.Version
            '$OS_PATCHES$'    = (Get-GetHotFixMarkdownTable  $metadata.Get_HotFix)
            '$OS_PS_MODULES$' = (Get-PSModulesMarkdownTable  $metadata.Get_InstalledModule)
            '$OS_PACKAGES$'   = (Get-Win32_ProductMarkdownTable  $metadata.Win32_Product)
            '$OS_FEATURES$'   = (Get-Get_WindowsFeatureMarkdownTable  $metadata.Get_WindowsFeature)
            '$BOX_METADATA$'  =  Get-BoxMetadataContent

            '$OS_CHOCOLATEY_PACKAGES$'  = (Get-Choco_PackagesMarkdownTable  $metadata.Choco_Packages)
        }

        foreach ($token in $contentTokens.Keys) {
            $value =  $contentTokens[$token]
            $markDownTemplates = $markDownTemplates.Replace($token, $value)
        }
    }

    $markDownTemplates `
            | Out-File -FilePath $container.PackerBuildReleaseNotesFile -Force
}

task Clean {
    # Remove-Item "$($container.PackerBuildDir)/logs/*" -Recurse -Force
}

task QA AnalyzeModule

# Synopsis: Builds packer image
task . PackerBuild

# Synopsis: Rebuilds packer image
task PackerBuild Checkout,
    Clean,
    ShowBuildTools,
    PackerValidate,
    PackerInspect,
    PackerBuildNoForce,
    VagrantBoxAddForce,
    CreateReleaseNotes

# Synopsis: Rebuilds packer image
task PackerRebuild Checkout,
    Clean,
    ShowBuildTools,
    PackerValidate,
    PackerInspect,
    PackerBuildForce,
    VagrantBoxAddForce,
    CreateReleaseNotes

# Synopsis: Rebuilds and regresses packer image
task PackerRegress Checkout,
    Clean,
    ShowBuildTools,
    PackerValidate,
    PackerInspect,
    PackerBuildForce,
    VagrantBoxAddForce,
    CreateReleaseNotes,
    VagrantBoxTest

# Synopsis: Rebuilds, regresses, and published packer image to Vagrant Cloud
task PackerRegressVagrantCloudPublish PackerRegress, VagrantCloudPublish

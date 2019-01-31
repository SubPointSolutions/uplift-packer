
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
    $UPLF_VBOXMANAGE_CPUEXECUTIONCAP = "80",

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

    # https://www.packer.io/docs/other/environment-variables.html
    $PACKER_CACHE_DIR = $null,
    $PACKER_CONFIG = $null,
    $PACKER_LOG = $null,
    $PACKER_LOG_PATH = $null,
    $PACKER_NO_COLOR = $null,
    $PACKER_PLUGIN_MAX_PORT = $null,
    $PACKER_PLUGIN_MIN_PORT = $null,

    # QA params
    $QA_FIX = $null
)

$dirPath = $BuildRoot
# $scriptPath = $MyInvocation.MyCommand.Name

. "$dirPath/.build-helpers.ps1"

# Build Scripts Guidelines
# https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-Guidelines

$container = New-PackerBuildContainer $packerImageName

Enter-Build {

    Update-EnvVariables

    Write-Build Green "Build container:"
    Write-Build Green ($container | ConvertTo-JSON)

    $gitBranch =  Get-GitBranchName $UPLF_GIT_BRANCH
    $gitCommit =  Get-GitCommit     $UPLF_GIT_COMMIT

    Write-Build Green " - branch: $gitBranch"
    Write-Build Green " - commit: $gitCommit"

    # ensure packer plugin
    $packerPlugingPath = '';
    $packerPluginUrl   = ''
    $packerPluginFileName = ''
    
    if($IsWindows) {
        $packerPlugingPath = Resolve-Path ( Join-Path -Path $ENV:APPDATA -ChildPath 'packer.d/plugins' )

        $packerPluginUrl      = 'https://github.com/themalkolm/packer-builder-vagrant/releases/download/v2018.10.15/packer-1.2.5_packer-builder-vagrant_windows_amd64.exe'
        $packerPluginFileName = 'packer-builder-vagrant.exe'

    } elseif($IsMacOS -eq $True) {
        $packerPlugingPath = Resolve-Path "~/.packer.d/plugins"

        $packerPluginUrl   = 'https://github.com/themalkolm/packer-builder-vagrant/releases/download/v2018.10.15/packer-1.2.5_packer-builder-vagrant_darwin_amd64'
        $packerPluginFileName = 'packer-builder-vagrant'
    } 
    
    $packerPlugingFilePath = Join-Path -Path $packerPlugingPath -ChildPath $packerPluginFileName 

    if( (Test-Path $packerPlugingFilePath) -eq $False) {
        Write-Build Yellow "[~] downloading packer plugin for the first time only"
        Write-Build Yellow " - src: $packerPluginUrl"
        Write-Build Yellow " - dst: $packerPlugingFilePath"
       
        Invoke-WebRequest -Uri $packerPluginUrl `
                        -OutFile $packerPlugingFilePath 

        
    } else {
        Write-Build Green "[+] packer plugin exists: $packerPluginFileName"
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
        Write-Build Yellow "[!] setting custom vboxmanage machine folder: $UPLF_VBMANAGE_MACHINEFOLDER"
        pwsh -c "vboxmanage setproperty machinefolder $UPLF_VBMANAGE_MACHINEFOLDER"
    }

}

Exit-Build {
    if($null -ne $UPLF_VBMANAGE_MACHINEFOLDER) {
        Write-Build Yellow "[!] reverting vboxmanage machine folder to default"
        pwsh -c 'vboxmanage setproperty machinefolder default'
    }
}

task Checkout {
    $isGit = git rev-parse --is-inside-work-tree

    if ($isGit -eq "true") {
        Write-Build Green " [~] pulling latest from git"

        exec {
            git pull
            git status

            git remote get-url origin
            git rev-parse --abbrev-ref HEAD
            git log --pretty=format:'%h' -n 1
        }
    }
    else {
        Write-Build Green " [+] skipping git pull"
    }
}

# Synopsis: Shows tools and versions
task ShowBuildTools {
    exec {
        Write-Build Green " [+] packer"
        Set-PackerEnvVariables
        packer version

        Write-Build Green " [+] vagrant"
        Set-VagrantEnvVariables
        vagrant version
    }
}

# Synopsis: Validates packer image
task PackerValidate {
    exec {
        Write-Build Green " [~] validating packer config"

        packer validate `
            -var-file="$($container.VariablesFile)" `
            "$($container.PackerFile)"
    }
}

task PackerInspect {
    exec {
        Write-Build Green " [~] inspecting packer config"

        packer inspect `
            "$($container.PackerFile)"
    }
}

# Synopsis: Builds packer image
task PackerBuild {
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
        Write-Build Green "Testing vagrant box, file: $($container.VagrantTestFile)"

        try {
            $ENV:UPLF_VAGRANT_LINKED_CLONE = 1

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
            
            $vagrantCwd =  [String]( Resolve-Path $container.PackerBuildDir)
            #$ENV:VAGRANT_CWD = $vagrantCwd

            Write-Build Green "Using vagrantfile cwd: $vagrantCwd"

            $vagrantBoxName = ($container.VagrantBoxName)
            $ENV:UPLF_VAGRANT_BOX_NAME = $vagrantBoxName

            Write-Build Green "Using vagrant box: $vagrantBoxName"
         
            if ($null -ne $UPLF_VBMANAGE_MACHINEFOLDER) {
                $ENV:UPLF_VBMANAGE_MACHINEFOLDER = $UPLF_VBMANAGE_MACHINEFOLDER
            }

            Set-VagrantEnvVariables

            Write-Build Blue "Running: vagrant validate"
            pwsh -c "cd $vagrantCwd; vagrant validate"
            Confirm-ExitCode $LASTEXITCODE "Failed: vagrant validate"

            Write-Build Blue "Running: vagrant status"
            pwsh -c "cd $vagrantCwd; vagrant status"

            Write-Build Blue "Running: vagrant clean up script"
            pwsh -c "cd $vagrantCwd; . ./.vagrant-cleanup.ps1"
            Confirm-ExitCode $LASTEXITCODE "Failed: vagrant clean up script"
        
            # test
            Write-Build Blue "Running: vagrant-test.ps1"
            pwsh -c "cd $vagrantCwd; . ./.vagrant-test.ps1"

            # survived!
            Write-Build Yellow "[+] PASSED ALL VAGRANT TESTS! This box looks really cool!"
        }
        catch {
            Write-Build Red "ERR: $_"

            throw "Failed vagrant testing: $_"
        }
        finally {
            Write-Build Blue "Running final clean up"
            
            pwsh -c "cd $vagrantCwd; . ./.vagrant-cleanup.ps1"
            pwsh -c "cd $vagrantCwd; vagrant halt"
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
        Write-Build Green "Cleaning up vagrant test VMs, file: $($container.VagrantTestFile)"

        exec {
            $ENV:VAGRANT_VAGRANTFILE = $container.VagrantTestFile
            $ENV:UPLF_VAGRANT_BOX_NAME = Resolve-Path -Path $container.VagrantBoxFile -Relative

            Set-VagrantEnvVariables

            Write-Build Green "vagrant destroy -f"
            vagrant destroy -f
        }
    }
}

# Synopsis: Publishes Vagrant box to Vagrant Cloud
task VagrantCloudPublish {
    Write-Build Green "[~] Publishing vagtant box to Vagrant Cloud: $($container.VagrantBoxName)"

    $VAGRANT_CLOUD_AUTH_TOKEN = Get-VariableOrEnvVariable "VAGRANT_CLOUD_AUTH_TOKEN" `
        $VAGRANT_CLOUD_AUTH_TOKEN `
        "Vagrant Cloud token is required"

    exec {

        Set-VagrantEnvVariables

        Write-Build Green "[~] auth with Vagrant Cloud..."

        # $dateStamp = Get-Date -f "yyyyMMdd"
        # $timeStamp = Get-Date -f "HHmmss"

        $year = Get-Date -f "yy"
        $month = Get-Date -f "MM"

        $day = Get-Date -f "dd"
        $minSec = Get-Date -f "HHmm"

        # $stamp = "$dateStamp.$timeStamp"
        $boxVersion = "$year$month.$day.$minSec"

        if($null -ne $VAGRANT_CLOUD_BOX_VERSION) {     
            $boxVersion = $VAGRANT_CLOUD_BOX_VERSION
            Write-Build Yellow "[!] using VAGRANT_CLOUD_BOX_VERSION box version: $boxVersion"
        }

        Write-Build Green "[~] box version: $boxVersion"

        $publishBoxName = "subpointsolutions/$($container.VagrantPublishingBoxName)"
        $publishBoxVersion = $boxVersion

        $publishBoxSrcPath = $container.VagrantBoxFile

        $publishBoxDescription = "This is a regression box to ensure CI/CD pipeline for Packer/Vagrant"
        $publishBoxShortDescription = "CI/CD regression for box $publishBoxName"

        $publishBoxVersionDescription = "CI/CD regression for box $publishBoxName, v$publishBoxVersion"
        $publishBoxVersionDescription += " branch: $($script:UPLF_GIT_BRANCH) commit: $($script:UPLF_GIT_COMMIT)"

        if( (Test-Path $container.PackerBuildReleaseNotesFile) -eq $True  ) {

            Write-Build Green "[+] using release notes filet: $($container.PackerBuildReleaseNotesFile)"

            $publishBoxVersionDescription += [Environment]::NewLine
            $publishBoxVersionDescription += [Environment]::NewLine

            $publishBoxVersionDescription += Get-Content -Raw $container.PackerBuildReleaseNotesFile
        } else {
            Write-Build Yellow "[!!!] Release notes file does not exist: $($container.PackerBuildReleaseNotesFile)"
        }

        Write-Build Yellow "[!!!] Publishing box to Vagrant Cloud [!!!]"
        Write-Build Green " - box version: $publishBoxVersion"
        Write-Build Green ""
        Write-Build Green " - box name   : $publishBoxName"
        Write-Build Green " - box src    : $publishBoxSrcPath"
        Write-Build Green ""
        Write-Build Green " - short desc : $publishBoxDescription"
        Write-Build Green " - long  desc : $publishBoxShortDescription"
        Write-Build Green " - vers  desc : $publishBoxVersionDescription"

        try {
            Write-Build Green "[~] vagrant cloud auth login"
            vagrant cloud auth login -t "$VAGRANT_CLOUD_AUTH_TOKEN"
            Confirm-ExitCode $LASTEXITCODE "[~] failed!"

            Write-Build Green "[+] OK!"

            Write-Build Green "[~] vagrant cloud publish..."
            vagrant cloud publish `
                $publishBoxName `
                $publishBoxVersion `
                virtualbox `
                $publishBoxSrcPath `
                --description "$publishBoxDescription" `
                --short-description "$publishBoxShortDescription" `
                --version-description "$publishBoxVersionDescription" `
                --force
            Confirm-ExitCode $LASTEXITCODE "[~] failed!"

            Write-Build Green "[+] OK!"
        } catch {
            Write-Build Green "[~] vagrant cloud auth login --logout"
            vagrant cloud auth login --logout
            throw
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
                    Write-Build Yellow " - skipping DSC validation under macOS"

                    Write-Build Green " - file   : $filePath"
                    Write-Build Green " - QA_FIX : $QA_FIX"

                    Write-Build Green  " - https://github.com/PowerShell/PowerShell/issues/5707"
                    Write-Build Green  " - https://github.com/PowerShell/PowerShell/issues/5970"
                    Write-Build Green  " - https://github.com/PowerShell/MMI/issues/33"

                    continue;
                }
              
                Write-Build Green " - file   : $filePath"
                Write-Build Green " - QA_FIX : $QA_FIX"

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

    Write-Build Green "Box spec file: $boxSpecFile"

    if( (Test-Path $boxSpecFile ) -eq $False ) {
        Write-Build Yellow "[~] box spec file does not exist. Won't create automated release notes"

        return
    }
    
    $metadata = Get-Content -Raw -Path $boxSpecFile | ConvertFrom-Json
    $markDownTemplates = Get-Content -Raw -Path $container.VagrantReleaseFile

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_NAME$', 
        $metadata.Win32_OperatingSystem.Caption
    )

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_VERSION$', 
        $metadata.Win32_OperatingSystem.Version
    )

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_PATCHES$', 
        (Get-GetHotFixMarkdownTable  $metadata.Get_HotFix)
    )

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_PS_MODULES$', 
        (Get-PSModulesMarkdownTable  $metadata.Get_InstalledModule)
    )

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_PACKAGES$', 
        (Get-Win32_ProductMarkdownTable  $metadata.Win32_Product)
    )

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_FEATURES$', 
        (Get-Get_WindowsFeatureMarkdownTable  $metadata.Get_WindowsFeature)
    )

    $markDownTemplates = $markDownTemplates.Replace(
        '$OS_CHOCOLATEY_PACKAGES$', 
        (Get-Choco_PackagesMarkdownTable  $metadata.Choco_Packages)
    )

    $markDownTemplates `
        | Out-File -FilePath $container.PackerBuildReleaseNotesFile -Force
}

task Clean {
    # Remove-Item "$($container.PackerBuildDir)/logs/*" -Recurse -Force
}

task QA AnalyzeModule

# Synopsis: Builds packer image
task . Checkout,
    Clean,
    ShowBuildTools,
    PackerValidate,
    PackerInspect,
    PackerBuild,
    VagrantBoxAdd,
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

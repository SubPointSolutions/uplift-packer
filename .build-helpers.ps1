function Confirm-PowerShell($version = "6.0.0") {
    if($PSVersionTable.PSVersion -lt [Version]$version) {
        throw "Detected PowerShell $($PSVersionTable.PSVersion). At least $version is required - https://github.com/PowerShell/PowerShell"
    }
}

function Write-BuildInfoMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param (
        $msg 
    )

    Write-Host $msg -ForegroundColor Green
}

function Write-BuildDebugMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param (
        $msg 
    )

    if($ENV:UPLF_LOG_LEVEL -eq "DEBUG") {
        Write-Host $msg -ForegroundColor Blue
    }
}

function Write-BuildErrorMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param (
        $msg 
    )

    Write-Host $msg -ForegroundColor Red
}

function Write-BuildWarnMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param (
        $msg 
    )

    Write-Host $msg -ForegroundColor Yellow
}

function Write-BuildWarningMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param (
        $msg 
    )

    Write-Host $msg -ForegroundColor Yellow
}

function Get-PackerImageName($name) {
    if($name.Contains("/") -eq $True) {
        $name = $name.Split('/')[1]
    }

    return $name
}

function Get-LowerName($name) {
    return $name.ToLower()
}

function Confirm-ExitCode($code, $message)
{
    if ($code -eq 0) {
        Write-BuildInfoMessage "Exit code is 0, continue..."
    } else {
        $errorMessage = "Exiting with non-zero code [$code] - $message"

        Write-Build Red  $errorMessage
        throw  $errorMessage
    }
}

Function Get-RandomPort
{
    return Get-Random -Min 8000 -Max 9000
}

Function Test-PortInUse
{
    Param(
        [Parameter(Mandatory=$true)]
        [Int] $port
    )

    $socket = New-Object System.Net.Sockets.TcpClient

    try
    {
        $socket.BeginConnect("127.0.0.1", $port, $null, $null) | Out-Null
        # $success = $connect.AsyncWaitHandle.WaitOne(500, $true)

        if ($socket.Connected)
        {
            return $True
        }

        return $False
    } finally {
        if($null -ne $socket) {
            $socket.Close()
            $socket.Dispose()
            $socket = $null
        }
    }
}

Function Get-RandomUsablePort
{
    Param(
        [Int] $maxTries = 100
    );
    $result = -1;
    $tries = 0;
    DO
    {
        $randomPort = Get-RandomPort;
        if (-Not (Test-PortInUse($randomPort)))
        {
            $result = $randomPort;
        }
        $tries += 1;
    } While (($result -lt 0) -and ($tries -lt $maxTries));
    return $result;
}

function Update-EnvVariables() {
    $upliftVariables = Get-ChildItem Env: `
        | Where-Object {  $_.Name.ToUpper().StartsWith("UPLF_") -eq $True }

    # ENV variables
    foreach($variable in $upliftVariables) {
        $name  = $variable.Name
        $value = $variable.Value

        if([String]::IsNullOrEmpty($value) -eq $True) {
            continue;
        }

        Set-Variable -Name $name `
            -Value $value `
            -Scope Script
    }
}

function Set-EnvVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param (
        $prefix
    )

    Write-BuildInfoMessage " [~] setting vagrant ENV variables"

    # env
    $variables = Get-ChildItem Env: `
        | Where-Object {  $_.Name.ToUpper().StartsWith($prefix) -eq $True }

    foreach($variable in $variables) {
        $name  = $variable.Name
        $value = $variable.Value

        if([String]::IsNullOrEmpty($value) -eq $True) {
            continue
        }

        $printValue = Write-VariableValue $name $value

        Write-BuildInfoMessage " - env var: $name value: $printValue"
        Set-Item -path "ENV:$name" -value $value
    }

    # cmd
    $variables = Get-Variable `
        | Where-Object {  $_.Name.ToUpper().StartsWith($prefix) -eq $True }

    foreach($variable in $variables) {
        $name  = $variable.Name
        $value = $variable.Value

        if([String]::IsNullOrEmpty($value) -eq $True) {
            continue
        }

        $printValue = Write-VariableValue $name $value

        Write-BuildInfoMessage " - cmd var: $name value: $printValue"
        Set-Item -path "ENV:$name" -value $value
    }
}

function Write-VariableValue($name, $value) {
    $isSecterVariable = Confirm-SecterVariableName $name

     if($isSecterVariable -eq $true) {
        return "******"
    } else {
        return $value
    }
}

function Set-VagrantEnvVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param (

    )

    Set-EnvVariables "VAGRANT_"
}

function Set-PackerEnvVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param (

    )

    Set-EnvVariables "PACKER_"
}

function New-PackerVariablesFile {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param (
        $filePath,
        $variables = @{}
    )

    $upliftVariables = Get-ChildItem Env: `
        | Where-Object {  $_.Name.ToUpper().StartsWith("UPLF_") -eq $True }

    $hash = @{}

    # ENV variables
    foreach($variable in $upliftVariables) {
        $name  = $variable.Name
        $value = $variable.Value

        $name = Get-LowerName $name

        $printValue = Write-VariableValue $name $value

        Write-BuildInfoMessage " - env var: $name value: $printValue"
        $hash[$name] = $value
    }

    # custom override
    foreach($variableKey in $variables.Keys) {
        $name  = $variableKey
        $value = $variables[$variableKey]

        $name = Get-LowerName $name

        $printValue = Write-VariableValue $name $value

        Write-BuildInfoMessage " - cus var: $name value: $printValue"
        $hash[$name] = $value
    }

    # command line override
    $cmdVariables = Get-Variable `
        | Where-Object {  $_.Name.ToUpper().StartsWith("UPLF_") -eq $True }

    foreach($variable in $cmdVariables) {
        $name  = $variable.Name
        $value = $variable.Value

        if($null -eq $value) {
            continue
        }

        $name = Get-LowerName $name

        $printValue = Write-VariableValue $name $value

        Write-BuildInfoMessage " - cmd var: $name value: $printValue"
        $hash[$name] = $value
    }

    $orderedTemplate = [pscustomobject]@{}

    foreach($key in $hash.Keys | Sort-Object ) {
        $orderedTemplate `
            | Add-Member -Name $key `
                -Type NoteProperty -Force `
                -Value  $hash[$key]
    }

    $orderedTemplate `
        | Sort-Object name `
        | ConvertTo-Json -Depth 2 `
        | Out-File -FilePath $filePath -Force
}

function Get-GitCommit() {
    if($script:UPLF_GIT_COMMIT) {
        return $script:UPLF_GIT_COMMIT
    };

    $value = (git log --pretty=format:'%h' -n 1)
    $script:UPLF_GIT_COMMIT = $value

    return $script:UPLF_GIT_COMMIT
}

function Get-GitBranchName() {
    if($script:UPLF_GIT_BRANCH) {
        return $script:UPLF_GIT_BRANCH
    };

    $value = (git rev-parse --abbrev-ref HEAD)
    $script:UPLF_GIT_BRANCH = $value

    return $script:UPLF_GIT_BRANCH
}

function Get-PackerImageFile($name) {
    $name =  Get-PackerImageName $name
    return "packer/$name/packer-template.generated.json"
}

function Test-HttpUrl($url) {

    Write-BuildInfoMessage "[~] checking url: $url"
    
    $result = Invoke-WebRequest "$url" `
        -UseBasicParsing `
        -DisableKeepAlive `
        -Method HEAD 

    if($result.StatusCode -eq 200) {
        Write-BuildInfoMessage  "[+] StatusCode: $($result.StatusCode) for url: $url"
    } else {
        throw "[!] StatusCode: $($result.StatusCode), expected 200!"
    }
}

function Start-LocalHttpServer {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $port,
        $path
    )

    Write-BuildInfoMessage "[~] Starting http-server to serve packer/vagrant builds"
    Write-BuildInfoMessage " - port : $port"
    Write-BuildInfoMessage " - local: localhost:$port"
    Write-BuildInfoMessage " - vm   : 10.0.2.2:$port"
    Write-BuildInfoMessage " - path : $path"

    if( (Test-Path $path) -eq $False) {
        $errorMessage = " [!] Path does not exist: $path"

        Write-BuildErrorMessage $errorMessage
        throw $errorMessage
    }

    $httpServerTool = Get-ToolCmd("http-server") 

    if($null -eq $httpServerTool) {
        $errMessage = "http-server tool is not here. Use 'npm install http-server -g' to install it - https://www.npmjs.com/package/http-server"
        
        Write-BuildErrorMessage $errMessage
        throw $errMessage
    }

    $job = http-server $path -p $port &

    Write-BuildInfoMessage "Pause 5 sec allowing http-server to start..."
    Start-Sleep 5

    Test-HttpUrl "http://localhost:$port"

    return $job
}

function Get-ToolCmd($name) {
    return (Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-RootPaths() {
    if($IsMacOs -eq $True) {
        return @(
            # current -> user -> root drive -> volumes
            ".",
            "~"
            "/",
            "/Volumes/*"
        )
    } elseif($IsWindows) {

        $result = @(
            # current -> user -> root drive -> volumes
            ".",
            "~"
        )

        $drives = Get-PSDrive -PSProvider 'FileSystem'
        $result +=  $drives | Select-Object -ExpandProperty  Root

        return $result
    } else {
        throw "Unsupported platform!"
    }
}

function Find-DefaultLocalRepositoryPath() {

    $result = $null

    $rootPaths = Get-RootPaths
    $defaultRepositoryName = "uplift-local-repository"

    foreach($rootPath in $rootPaths) {
        $paths = Resolve-Path $rootPath

        foreach($path in $paths) {
            $repoPath = Join-Path -Path $path -ChildPath $defaultRepositoryName

            if((Test-Path $repoPath) -eq $True) {
                return $repoPath
            }
        }
    }

    return $result
}

function New-UpliftHttpServerSession {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param(
        $imageName
    )

    $packerFileName = Get-PackerImageFile $imageName
    $packerTemplate = Get-Content $packerFileName -Raw

    $httpServerJob = $null
    $port = $null

    if($null -eq $UPLF_HTTP_DIRECTORY) {
        Write-BuildInfoMessage " [!] UPLF_HTTP_DIRECTORY is null, trying to resolve default local repository paths"

        $defaultLocalRepositoryPath = Find-DefaultLocalRepositoryPath
       
        if($null -ne $defaultLocalRepositoryPath) {
            Write-BuildInfoMessage " [+] UPLF_HTTP_DIRECTORY is set: $defaultLocalRepositoryPath"
            $UPLF_HTTP_DIRECTORY = $defaultLocalRepositoryPath
        } else {
            Write-BuildInfoMessage " [!] no default local repository was found"
        }
    }

    if( [String]::IsNullOrEmpty($UPLF_HTTP_DIRECTORY) -eq $false) {
        if( (Test-Path $UPLF_HTTP_DIRECTORY) -eq $false) {
            $errMessage = "[!] Path does not exist: $UPLF_HTTP_DIRECTORY"

            Write-BuildErrorMessage $errMessage
            throw $errMessage
        }

        $port = Get-RandomUsablePort

        #Write-BuildInfoMessage "Starting local http server"
        #Write-BuildInfoMessage " - dir : $UPLF_HTTP_DIRECTORY"
        #Write-BuildInfoMessage " - port: $port"

        $httpServerJob  = Start-LocalHttpServer $port $UPLF_HTTP_DIRECTORY
    }
    else {
        Write-BuildWarnMessage " [!] UPLF_HTTP_DIRECTORY is null, won't start local http-server, some builds might fail!"
    }

    # check if packer template has any uplift http based resources
    # if so, check $UPLF_HTTP_DIRECTORY and then fail - it must be there

    if($packerTemplate.ToLower().Contains("_resource_name") -eq $True) {

        if([String]::IsNullOrEmpty($UPLF_HTTP_DIRECTORY) -eq $True) {
            $errorMessage = " [!] This packer template specifies one or more HTTP bases resources. Set UPLF_HTTP_DIRECTORY variable to start local http-server"

            Write-BuildErrorMessage $errorMessage
            throw $errorMessage
        }

        if( (Test-Path $UPLF_HTTP_DIRECTORY) -eq $false) {
            $errorMessage = " [!] Path does not exist: $UPLF_HTTP_DIRECTORY"

            Write-BuildErrorMessage $errorMessage
            throw $errorMessage
        }
    }

    return (New-Object PSObject –Property @{
        HttpServerJob = $httpServerJob
        HttpPort = $port
    })
}

function New-PackerBuildContainer {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param(
        $imageName,
        $httpServerSession
    )

    Write-BuildInfoMessage "Creating build container for image: $imageName" 

    $port = $httpServerSession.HttpPort

    $packerFileName = Get-PackerImageFile $imageName
    $packerTemplate = Get-Content $packerFileName -Raw

    $branchName   = Get-GitBranchName $UPLF_GIT_BRANCH
    $branchCommit = Get-GitCommit $UPLF_GIT_COMMIT

    $packerImageName = Get-PackerImageName $imageName
    $packerUniqueImageName = "$packerImageName-$branchName"
    $publishingBoxName = $packerImageName

    Write-BuildInfoMessage "Image: $packerImageName, file: $packerFileName" 
    Write-BuildInfoMessage " - branchName  : $branchName" 
    Write-BuildInfoMessage " - branchCommit: $branchCommit" 

    $containerFolder    = "build-packer-ci-local"
    $packerBuildFolder  = "$containerFolder/$packerUniqueImageName"

    $packerBuildLogFolder = "$packerBuildFolder/logs"

    New-Item -ItemType Directory -Force -Path $packerBuildFolder | Out-Null
    $containerFolder    = Resolve-Path -Path $containerFolder
    $containerFolder    = Resolve-Path -Path $packerBuildFolder

    New-Item -ItemType Directory -Force -Path $packerBuildLogFolder | Out-Null
    $packerBuildLogFolder    = Resolve-Path -Path $packerBuildLogFolder

    $vagrantBoxFile  = "$packerBuildFolder/box/box.box"
    $packerOutputDir = "$packerBuildFolder/output"

    [System.IO.Directory]::CreateDirectory($packerOutputDir) | Out-Null

    $packerBoxSpecBuildFolder = "$packerBuildFolder/box-spec"
    [System.IO.Directory]::CreateDirectory($packerBoxSpecBuildFolder) | Out-Null
   
    $vagrantTestFile = ("packer/$packerImageName/" + "Vagrantfile")
    $vagrantReleaseFile = ("packer/$packerImageName/" + ".release-notes.md")

    $vagrantTestScriptFile    = ("packer/$packerImageName/" + ".vagrant-test.ps1")
    $vagrantCleanupScriptFile = ("packer/$packerImageName/" + ".vagrant-cleanup.ps1")

    $vagrantTestScriptsFolder = ("packer/$packerImageName/vagrant-test-scripts")

    # $scriptPath      = [String](Resolve-Path -Path "packer")
    $scriptPath = "packer"
   
    $packerVariablesHash = @{
        "UPLF_scripts_path"         = $scriptPath
        "UPLF_output_directory"     = $packerOutputDir
        "UPLF_vagrant_box_output"   = $vagrantBoxFile
        "uplf_box_spec_dest_folder" = $packerBoxSpecBuildFolder
    }

    if([String]::IsNullOrEmpty($port) -eq $False) {
        # check that local server is up
        Test-HttpUrl "http://localhost:$port"

        $packerVariablesHash["UPLF_BIN_REPO_HTTP_ADDR"] = "10.0.2.2:$port";
    } 

    New-PackerVariablesFile "$packerBuildFolder/variables.json" $packerVariablesHash

    $vagrantBoxName   = "uplift-local/$packerUniqueImageName"
    $vagrantBoxes = [String]((vagrant box list) |  Out-String)

    $vagrantBoxExists = $vagrantBoxes.Contains("$vagrantBoxName ")

    # pre-setup packer logs
    $ENV:PACKER_LOG = "1"
    $ENV:PACKER_LOG_PATH = "$packerBuildFolder/logs/packer.log"

    # copy packer file
    Copy-Item $packerFileName "$packerBuildFolder/packer.json" -Force

    return New-Object PSObject –Property @{
        PackerFile = "$packerBuildFolder/packer.json"
        PackerBoxSpecFolder = "$packerBoxSpecBuildFolder"
        PackerImageName = $imageName
        VariablesFile = "$packerBuildFolder/variables.json"
        VagrantBoxFile = $vagrantBoxFile
        VagrantBoxFileExists = (Test-Path $vagrantBoxFile)
        PackerOutputDir = $packerOutputDir
        PackerBuildDir = $packerBuildFolder
        PackerBuildReleaseNotesFile = "$packerBuildFolder/.release-notes.md"
        VagrantBoxName = $vagrantBoxName
        VagrantPublishingBoxName = $publishingBoxName
        VagrantBoxExists = $vagrantBoxExists
        VagrantTestFile  = $vagrantTestFile
        VagrantTestScriptFile  = $vagrantTestScriptFile
        VagrantCleanupScriptFile  = $vagrantCleanupScriptFile
        VagrantTestScriptsFolder  = $vagrantTestScriptsFolder
        VagrantReleaseFile  = $vagrantReleaseFile
        LocalHttpServerJobId = $httpServerJob.Id
        LocalHttpServerPort  = $port
        BuildId = [Guid]::NewGuid()
        GitBranchName = $branchName
        GitBranchCommit = $branchCommit
        BuildDateTime = [DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:fffffffK")
        BuildDir = $packerBuildFolder
    }
}

function Get-VariableOrEnvVariable($name, $value, $description) {

    $result = $false

    # value ok?
    if($null -ne $value) {
        return $value
    }

     # it is ENV variable?
    if($null -ne [System.Environment]::GetEnvironmentVariable($name) ) {
        return [System.Environment]::GetEnvironmentVariable($name)
    }

    if($result -ne $True) {
        throw "Variable $name is null: $description"
    }
}

function Confirm-SecterVariableName($name) {
    return $name.ToUpper().Contains("_KEY") -or $name.ToUpper().Contains("_PASSWORD") -or $name.ToUpper().Contains("_TOKEN")
}

function Invoke-PackerBuild($force = $false) {
    if ($container.VagrantBoxExists -eq $false -or $force -eq $true) {
        
        if($container.VagrantBoxExists -eq $true) {
            Write-BuildWarningMessage " [~] box exist, force flag: $force "
        } else {
            Write-BuildWarningMessage " [~] box does not exist, force flag: $force "
        }

        exec {
            Set-PackerEnvVariables

            $packerOnlyValue = $script:PACKER_ONLY

            if($force -eq $True) {
                packer build `
                    -force `
                    -only $packerOnlyValue `
                    -var-file="$($container.VariablesFile)" `
                    "$($container.PackerFile)"
            } else {
                packer build `
                    -only $packerOnlyValue `
                    -var-file="$($container.VariablesFile)" `
                    "$($container.PackerFile)"
            }

            Confirm-ExitCode $LASTEXITCODE "Failed: packer build"
        }
    }
    else {
        Write-BuildInfoMessage " [+] box exists!"
    }
}

function Get-FileSizeInGb($path) {

    if ( (Test-Path $path) -eq $false ) {
        throw "File does not exist: $path"
    }

    $size = (Get-Item $path).Length
    return [string]::Format("{0:0.00} GB", $size / 1GB)
}

function Invoke-VagrantBoxAdd($force = $false) {

    if( (Test-Path $container.VagrantBoxFile) -eq $True) {

        $boxSize = Get-FileSizeInGb($container.VagrantBoxFile)

        if ($container.VagrantBoxExists -eq $false -or $force -eq $True) {
            $boxSize = Get-FileSizeInGb($container.VagrantBoxFile)

            Write-BuildWarningMessage " [~] vagrant box was not added, adding..."

            Write-BuildWarningMessage " - name: $($container.VagrantBoxName)"
            Write-BuildWarningMessage " - size: $boxSize"
            Write-BuildWarningMessage " - src : $($container.VagrantBoxFile)"

            exec {
                Set-VagrantEnvVariables

                vagrant box add `
                    $container.VagrantBoxFile `
                    --name  $container.VagrantBoxName `
                    --force
            }

            Write-BuildWarningMessage " [~] removing box file..."
            Remove-Item $container.VagrantBoxFile -Force
        }
        else {
            $boxSize = Get-FileSizeInGb($container.VagrantBoxFile)

            Write-BuildInfoMessage " [+] vagrant box was already added"
            Write-BuildInfoMessage " - name: $($container.VagrantBoxName)"
            Write-BuildInfoMessage " - size: $boxSize"
            Write-BuildInfoMessage " - src : $($container.VagrantBoxFile)"
        }
    } else {
        Write-BuildInfoMessage " [~] vagrant box file does not exist: $($container.VagrantBoxFile)"
        Write-BuildInfoMessage " [~] most likely, box exists and no-force build is used"
    }
}


function convertto-tableview {
    Param(            
        $inputObject
    )


    return ( $inputObject  |  Format-Table  | Out-String)
}


function Get-VersionString($obj) {
    $revision = $obj.Revision

    if($revision -ne -1) {
        return [String]::Join(".", @(
            $obj.Major
            $obj.Minor
            $obj.Build
            $obj.Revision 
        ))
    }

    return [String]::Join(".", @(
        $obj.Major
        $obj.Minor
        $obj.Build
    ))
}

function Get-DefaultDataItems($dataItems) {
    if($null -eq $dataItems.Count) {
        $dataItems = @( $dataItems )
    }

    return $dataItems
}

function Get-PSModulesMarkdownTable($dataItems) {
    if($null -eq $dataItems) {
        return 'N/A'
    }

    $dataItems = Get-DefaultDataItems $dataItems
    $dataTable = @()
    $result = ""

    foreach($dataItem in  $dataItems | Sort-Object -Property Name) {

        $tableItem = New-Object PSObject -Property @{}
        $versionString = Get-VersionString $dataItem.Version

        $tableItem | Add-Member -Name 'Name' `
            -Type NoteProperty -Force -Value  $dataItem.Name
        
        $tableItem | Add-Member -Name 'Type' `
            -Type NoteProperty -Force -Value  $dataItem.Type

        $tableItem | Add-Member -Name 'Version' `
            -Type NoteProperty -Force -Value  $versionString
    
        $dataTable += $tableItem

        $moduleTypeId = $dataItem.Type[0]

        $result += "* [$moduleTypeId]  $($dataItem.Name),  $versionString"
      
        $result += [Environment]::NewLine
    }

    return (  $result )
}
function Get-GetHotFixMarkdownTable($dataItems) {

    if($null -eq $dataItems) {
        return 'N/A'
    }

    $dataItems = Get-DefaultDataItems $dataItems
    $dataTable = @()
    $result = ""

    foreach($dataItem in  $dataItems | Sort-Object -Property HotFixID) {
        $tableItem = New-Object PSObject -Property @{}
        
        $tableItem | Add-Member -Name 'HotFixID' `
            -Type NoteProperty -Force -Value  $dataItem.HotFixID
        
        $tableItem | Add-Member -Name 'Description' `
            -Type NoteProperty -Force -Value  $dataItem.Description

        $tableItem | Add-Member -Name 'Status' `
            -Type NoteProperty -Force -Value  $dataItem.Status
    
        $dataTable += $tableItem

        if( [String]::IsNullOrEmpty($dataItem.Status) -eq $True) {
            $result += "* $($dataItem.HotFixID), $($dataItem.Description)"
        } else {
            $result += "* $($dataItem.HotFixID), $($dataItem.Description), $($dataItem.Status)"
        }

        $result += [Environment]::NewLine
    }

    return (  $result )
}

function Get-Win32_ProductMarkdownTable($dataItems) {

    if($null -eq $dataItems) {
        return 'N/A'
    }

    $dataItems = Get-DefaultDataItems $dataItems
    $dataTable = @()

    $result = ""

    foreach($dataItem in  $dataItems | Sort-Object -Property Name) {
        $tableItem = New-Object PSObject -Property @{}
        
        $tableItem | Add-Member -Name 'Name' `
            -Type NoteProperty -Force -Value  $dataItem.Name

        $tableItem | Add-Member -Name 'Version' `
            -Type NoteProperty -Force -Value  $dataItem.Version
    
        $tableItem | Add-Member -Name 'Vendor' `
            -Type NoteProperty -Force -Value  $dataItem.Vendor
        
        $tableItem | Add-Member -Name 'IdentifyingNumber' `
            -Type NoteProperty -Force -Value  $dataItem.IdentifyingNumber

        $dataTable += $tableItem
        
        $result += "* $($dataItem.Name), $($dataItem.Version)"
        $result += [Environment]::NewLine
    }

    return ( $result)
}

function Get-Get_WindowsFeatureMarkdownTable($dataItems) {

    if($null -eq $dataItems) {
        return 'N/A'
    }

    $dataItems = Get-DefaultDataItems $dataItems
    $dataTable = @()

    $result = ""

    foreach($dataItem in  $dataItems | Sort-Object -Property Name) {

        if($dataItem.Installed -ne $True) {
            continue;
        }
 
        $tableItem = New-Object PSObject -Property @{}
        
        $tableItem | Add-Member -Name 'Name' `
            -Type NoteProperty -Force -Value  $dataItem.Name

        $tableItem | Add-Member -Name 'DisplayName' `
            -Type NoteProperty -Force -Value  $dataItem.DisplayName
    
        $tableItem | Add-Member -Name 'FeatureType' `
            -Type NoteProperty -Force -Value  $dataItem.FeatureType

        $dataTable += $tableItem

        $featureTypeId = $dataItem.FeatureType[0]

        $result += "* [$featureTypeId] $($dataItem.Name)"
        $result += [Environment]::NewLine
    }

    return (  $result )
}

function Get-Choco_PackagesMarkdownTable($dataItems) {

    if($null -eq $dataItems) {
        return 'N/A'
    }

    $dataItems = Get-DefaultDataItems $dataItems
    $dataTable = @()


    $result = ""

    foreach($dataItem in  $dataItems | Sort-Object -Property Name) {

        $tableItem = New-Object PSObject -Property @{}
        
        $tableItem | Add-Member -Name 'Id' `
            -Type NoteProperty -Force -Value  $dataItem.Id

        $tableItem | Add-Member -Name 'Version' `
            -Type NoteProperty -Force -Value  $dataItem.Version

        $dataTable += $tableItem

        $result += "* $($dataItem.Id), $($dataItem.Version)"
        $result += [Environment]::NewLine
    }

    return ($result )
}


function Delete-LinkedCloneVMs() {
    $vmLines = ( vboxmanage list vms  | % { $_.split( [Environment]::NewLine ) }  )

    foreach($vmLine in $vmLines | Sort-Object ) {
        $vmPair = $vmLine.Split(' ')

        $vmName = $vmPair[0].Trim('"')
        $vmId   = $vmPair[1]

        if( ($vmName -match "uplift-virtualbox-iso-*_*_*") -eq $True) {
            Write-BuildWarningMessage "[!] linked clone vm: $vmName id: $vmId"

            Write-BuildWarningMessage "[!] Deleting linked clone: $vmName"
            vboxmanage unregistervm $vmName --delete
        }  else {
            Write-BuildInfoMessage "[+] regular vm: $vmName"
        }
    }
}

function Confirm-AppveyorTools() {
    
    if($null -ne $env:APPVEYOR) {
        Write-BuildInfoMessage "Installing additional tools under Appveyor"

        # vagrant install gives 3010 asking for reboot
        # we using vagrant only for CI testing here, so no reboot or install checks

        #exec {
            choco install -y packer  --limit-output --acceptlicense --no-progress
            choco install -y vagrant --limit-output --acceptlicense --no-progress
        #}
    }
}

Confirm-PowerShell
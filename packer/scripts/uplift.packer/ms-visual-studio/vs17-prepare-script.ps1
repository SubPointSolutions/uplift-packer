# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing Visual Studio..."
Write-UpliftEnv

$execPath    = Get-UpliftEnvVariable "UPLF_VS_EXECUTABLE_PATH"
Write-UpliftMessage "Using VS install file: $execPath"

$vsPackageIdsValue  = Get-UpliftEnvVariable "UPLF_VS_PACKAGE_IDS"

Write-UpliftMessage "Using product name: $productName "
Write-UpliftMessage "Using package IDs:"
Write-UpliftMessage " - $vsPackageIdsValue"

$expectPackageCount = [int](Get-UpliftEnvVariable "UPLF_VS_PACKAGE_COUNT")

Write-UpliftMessage "Using VS install file: $execPath"
Write-UpliftMessage "Expecting $expectPackageCount packages installed"

$installLogFolder = $env:TEMP
$installLogFilter = "dd_setup*_*_*"
$vs17LogsFilter   = "dd_*"

$enterprisePackageName = "Microsoft.VisualStudio.Product.Enterprise"

Write-UpliftMessage "Cleaning up previous logs, filter: $vs17LogsFilter, path: $installLogFolder"
$logFiles = Get-ChildItem $installLogFolder -Filter $vs17LogsFilter
Write-UpliftMessage "Found $($logFiles.Count) files, will remove them"

$logFiles | ForEach-Object { Remove-Item -Path $_.FullName }

# TODO, move layout and other configs into variables
# --noWeb fails with the following errors so that it is not possible to make fully offline install
# * Package 'Microsoft.VisualStudio.Branding.Enterprise,version=15.6.27413.0,language=en-US' failed to download from
# * Package 'Microsoft.VisualStudio.MinShell.Resources,version=15.7.27703.2018,language=en-US' failed to download from

# https://docs.microsoft.com/en-us/visualstudio/install/create-a-network-installation-of-visual-studio
# https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2017

$splitOptions = [System.StringSplitOptions]::RemoveEmptyEntries
$packageIds   = $vsPackageIdsValue.Split(";", $splitOptions)

$workloadArgument = @()

foreach($packageId in $packageIds) {
    $workloadArgument  += ("--add " + $packageId)
}

$workloadCmd = [string]::Join(" ", $workloadArgument )
Write-UpliftMessage " - workloadCmd: $workloadCmd"

Write-UpliftMessage "Executing install..."
Write-UpliftMessage " - path: $execPath"

$modifyCmd = ""
$installPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise"
if(Test-Path $installPath) {
    Write-UpliftMessage "VS install path exists, adding --modify flag"
    $modifyCmd = "modify --installPath ""$installPath"" "
    Write-UpliftMessage " - cmd: $modifyCmd"
}

$finalCmd = "$modifyCmd $workloadCmd --quiet --wait"
Write-UpliftMessage "Final arg cmd:"
Write-UpliftMessage " - cmd: $finalCmd "

$process = Start-Process -FilePath $execPath `
            -ArgumentList "$finalCmd" `
            -Wait `
            -PassThru

# logs will be at %TEMP% folder
# C:\Users\vagrant\AppData\Local\Temp
# a bunch of
# - dd_bootstrapper
# - dd_client
# - dd_service
# we might need to check these files in order to parse errors
$exitCode = $process.ExitCode;
Write-UpliftMessage "Exit code was: $exitCode"

Write-UpliftMessage "Checking packages installed, filter: $installLogFilter, path: $installLogFolder"
$files = Get-ChildItem $installLogFolder -Filter $installLogFilter
Write-UpliftMessage "Found $($files.Count) files"

foreach($file in $files) {
    Write-UpliftMessage $file.FullName
}

if($files.Count -le $expectPackageCount) {
    Write-UpliftMessage "WARN - less than $expectPackageCount packages, we might have VS2017 installed wrong or it could be install on top"
} else {
    Write-UpliftMessage "INFO - more than $expectPackageCount packages, we might have VS2017 installed right"
}

$mainPackage = Get-ChildItem $installLogFolder -Filter "dd_setup_*_*_$enterprisePackageName*"

if($mainPackage.Count -le 0) {
    Write-UpliftMessage "WARN - can't find package $enterprisePackageName, we might have VS2017 installed wrong"
} else {
    Write-UpliftMessage "INGO - CAN find package $enterprisePackageName, we might have VS2017 installed right"
}

# printing error file
$errorFilePath = "$installLogFolder\dd_setup_**_errors.log"

Write-UpliftMessage "Checking error log: $errorFilePath"
if (Test-Path $errorFilePath ) {
    $realErrorFilePath = Resolve-Path $errorFilePath
    Write-UpliftMessage "Reading error file: $realErrorFilePath"

    $errorContent = Get-Content $realErrorFilePath
    if ($errorContent.Count -eq 0) {
        Write-UpliftMessage "No error are found, all looks promising!"
    } else {
        Write-UpliftMessage "Errors output:"
        Write-UpliftMessage $errorContent

        exit -1
    }
} else {
    Write-UpliftMessage "Can't find errors file: $errorFilePath"
}

if ($exitCode -ne 0 -and $exitCode -ne 3010) {
    Write-UpliftMessage "Failed to install VS2017, exit code: $exitCode";
    exit $exitCode;
}

exit 0
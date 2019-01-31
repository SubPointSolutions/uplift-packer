# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage 'Installing package...'
Write-UpliftEnv

$packageName        = Get-UpliftEnvVariable 'UPLF_APP_PACKAGE_NAME';
$packageFilePath    = Get-UpliftEnvVariable 'UPLF_APP_PACKAGE_FILE_PATH';
$silentArgs         = Get-UpliftEnvVariable 'UPLF_APP_PACKAGE_SILENT_ARGS';
$exitCodes          = Get-UpliftEnvVariable 'UPLF_APP_PACKAGE_EXIT_CODES';
$fileType           = Get-UpliftEnvVariable 'UPLF_APP_PACKAGE_FILE_TYPE' 'default value' 'msu';

$exitCodes = $exitCodes.split(',');

$result = Install-UpliftInstallPackage -filePath $packageFilePath `
                                     -packageName $packageName `
                                     -silentArgs $silentArgs `
                                     -validExitCodes $exitCodes `
                                     -fileType $fileType;
exit $result
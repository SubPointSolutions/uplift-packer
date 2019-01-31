
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Setting uplift metadata global variables"
Write-UpliftEnv

function Set-UpMetadataVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(

    )

    $upliftVariables = Get-ChildItem Env: `
        | Where-Object {  $_.Name.ToUpper().StartsWith("UPLF_BOX_METADATA_") -eq $True }

    Write-UpliftMessage "Found UPLF_BOX_METADATA_ variables: $($upliftVariable.Count)"

    foreach ($variable in $upliftVariables) {
        $name = $variable.Name
        $value = $variable.Value

        Write-UpliftMessage "Updating global ENV var: $name : $value"
        [Environment]::SetEnvironmentVariable($name, $value , "Machine")
    }
}

Set-UpMetadataVariables

Write-UpliftMessage "Showing ENV variables again"
Write-UpliftEnv
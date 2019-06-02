$ErrorActionPreference = "Stop"

function Confirm-PowerShell($version = "6.0.0") {
    if($PSVersionTable.PSVersion -lt [Version]$version) {
        throw "Detected PowerShell $($PSVersionTable.PSVersion). At least $version is required - https://github.com/PowerShell/PowerShell"
    }
}

Confirm-PowerShell

function Merge-Objects() {

    $result = $null

    foreach($arg in $args) {
        if($null -eq $arg) {
            throw "null reference in passed arguments"
        }

        if($null -eq $result) {
            $result = $arg
        } else {
            foreach($prop in $arg.psobject.Properties) {
                $name  = $prop.Name
                $value = $prop.Value

                $result | Add-Member -Name $name -Type NoteProperty -Value $value -Force
            }
        }
    }

    return $result
}

function Merge-ObjectsAsArray {
    $result = $null

    foreach($arg in $args) {
        if($null -eq $arg) {
            throw "null reference in passed arguments"
        }

        if($null -eq $result) {
            $result = $arg
        } else {
            $result = $result + $arg
        }
    }

    return $result
}

function Get-JSON($file) {
    Get-Content -Raw -Path $file | ConvertFrom-Json
}

function Save-JSON {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]

    param (
        $template, 
        $file, 
        $validate = $true
    )

    Write-Host "Packer version:"
    packer version

    Write-Host "Saving template: $file"

    # none of these must be null
    if($null -eq $template.builders) {
        throw "[builders] section is null!"
    }

    if($null -eq $template.builders) {
        throw "[provisioners] section is null!"
    }

    if($null -eq $template.'post-processors') {
        throw "[post-processors] section is null!"
    }

    # seems that original hash object does not always retain property names
    # it produces random JSON file every none and then
    # hence, rebuilding with the right order

    # $template | ConvertTo-Json -Depth 100 | Out-File $file -Force
    $orderedTemplate = [pscustomobject]@{
        variables         = $template.variables
        builders          = $template.builders
        provisioners      = $template.provisioners
        "post-processors" = $template.'post-processors'
    }

    $orderedTemplate | ConvertTo-Json -Depth 10 | Out-File $file -Force

    if($validate -eq $true) {
        Confirm-Packer $file
    }
}

function Confirm-Packer {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]

    param(
        $file
    )

    Write-Host "Packer version:"
    packer version

    Write-Host "Validating template: packer validate $file"
    packer validate $file
    if ($LASTEXITCODE -ne 0) { throw "Failed: packer validate $file"}
}

function Get-PackerTemplateName($path) {
    # $folderName =  Split-Path (Split-Path $path -Parent) -Leaf 

    return "packer-template.generated.json"
}
$ErrorActionPreference = "Stop"

$dirPath    = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = [string](Resolve-Path $MyInvocation.MyCommand.Name)
$packerTemplatesPath = "./../packer_templates"

. "$dirPath/../.build-helpers.ps1"

$templateFileName  = Get-PackerTemplateName($scriptPath)

$coreVaiables      = Get-JSON "$packerTemplatesPath/common/variables.json"
$coreBuilder       = Get-JSON "$packerTemplatesPath/common/builders-win-2019-iso.json"
$coreUplift        = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-core.json"

$corePostProcessor = Get-JSON "$packerTemplatesPath/common/post-processors-win-2016-vagrant.json"

$specExtractor     = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"
$bareVariables     = Get-JSON "$packerTemplatesPath/win-2019-datacenter-bare/variables.json"

$coreVirtualboxAddition  = Get-JSON "$packerTemplatesPath/common/provisioners-core-virtualbox-additions.json"

$template = @{
    "builders"        = $coreBuilder.builders

    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $bareVariables.variables 

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $coreVirtualboxAddition.provisioners `
                            $coreUplift.provisioners `
                            $specExtractor.provisioners 

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
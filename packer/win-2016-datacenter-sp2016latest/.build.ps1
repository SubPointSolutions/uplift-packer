$ErrorActionPreference = "Stop"

$dirPath    = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = $MyInvocation.MyCommand.Name
$packerTemplatesPath = "./../packer_templates"

. "$dirPath/../.build-helpers.ps1"

$templateFileName  = Get-PackerTemplateName($scriptPath)

$coreVaiables      = Get-JSON "$packerTemplatesPath/common/variables.json"
$coreBuilder       = Get-JSON "$packerTemplatesPath/common/builders-win-2016-vagrant.json"
# $coreUplift        = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-core.json"
$corePostProcessor = Get-JSON "$packerTemplatesPath/common/post-processors-win-2016-vagrant.json"

$sp16BinVariables     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016bin/variables.json"
$sp16BinProvisioners  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016bin/provisioners.json"

$specExtractor     = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"

$sp16LatestVariables  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016latest/variables.json"

$template = @{
    "builders"        = $coreBuilder.builders

    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $sp16BinVariables.variables `
                            $sp16LatestVariables.variables

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $sp16BinProvisioners.provisioners `
                            $specExtractor.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
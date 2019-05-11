$ErrorActionPreference = "Stop"

$dirPath    = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = $MyInvocation.MyCommand.Name
$packerTemplatesPath = "./../packer_templates"

. "$dirPath/../.build-helpers.ps1"

$templateFileName  = Get-PackerTemplateName($scriptPath)

$coreVaiables      = Get-JSON "$packerTemplatesPath/common/variables.json"
$coreBuilder       = Get-JSON "$packerTemplatesPath/common/builders-win-2016-vagrant.json"
$coreUplift        = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-core.json"
$corePostProcessor = Get-JSON "$packerTemplatesPath/common/post-processors-win-2016-vagrant.json"

$sp16BinVariables     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016bin/variables.json"
$sp16BinProvisioners  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016bin/provisioners.json"

$specExtractor     = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"

$sp16LatestVariables  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016latest/variables.json"

$vs17Variables       = Get-JSON "$packerTemplatesPath/win-2016-datacenter-vs17/variables.json"
$vs17Provisioners    = Get-JSON "$packerTemplatesPath/win-2016-datacenter-vs17/provisioners.json"

$optimizeUplift    = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-optimize.json"

$template = @{
    "builders"        = $coreBuilder.builders
    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $sp16BinVariables.variables `
                            $sp16LatestVariables.variables `
                            $vs17Variables.variables

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $coreUplift.provisioners `
                            $sp16BinProvisioners.provisioners `
                            $vs17Provisioners.provisioners `
                            $specExtractor.provisioners `
                            $optimizeUplift.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
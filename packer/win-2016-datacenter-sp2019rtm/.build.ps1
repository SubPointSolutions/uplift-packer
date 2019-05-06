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

# use 2016 provision with 2019 parameters
$sp19BinVariables     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2019bin/variables.json"
$sp19BinProvisioners  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2016bin/provisioners.json"

$specExtractor     = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"

$sp19RtmVariables  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sp2019rtm/variables.json"

$template = @{
    "builders"        = $coreBuilder.builders

    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $sp19BinVariables.variables `
                            $sp19RtmVariables.variables

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $sp19BinProvisioners.provisioners `
                            $specExtractor.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
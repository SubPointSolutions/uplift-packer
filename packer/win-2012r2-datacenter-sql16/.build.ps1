$ErrorActionPreference = "Stop"

$dirPath    = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = $MyInvocation.MyCommand.Name
$packerTemplatesPath = "./../packer_templates"

. "$dirPath/../.build-helpers.ps1"

$templateFileName  = Get-PackerTemplateName($scriptPath)

$coreVaiables      = Get-JSON "$packerTemplatesPath/common/variables.json"
$coreBuilder       = Get-JSON "$packerTemplatesPath/common/builders-win-2012r2-vagrant.json"
$coreUplift        = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-core.json"
$corePostProcessor = Get-JSON "$packerTemplatesPath/common/post-processors-win-2016-vagrant.json"

$specExtractor        = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"

$sql16Variables       = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16/variables.json"
$sql16Provisioners    = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16/provisioners.json"

$sqlSsmsVariables     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-ssms/variables.json"
$sqlSsmsProvisioners  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-ssms/provisioners.json"

$sqlBoxVariables      = Get-JSON "$packerTemplatesPath/win-2012r2-datacenter-sql16/variables.json"

$optimizeUplift      = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-optimize.json"

$template = @{
    "builders"        = $coreBuilder.builders
    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $sql16Variables.variables `
                            $sqlSsmsVariables.variables `
                            $sqlBoxVariables.variables

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $coreUplift.provisioners `
                            $sql16Provisioners.provisioners `
                            $sqlSsmsProvisioners.provisioners `
                            $specExtractor.provisioners `
                            $optimizeUplift.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
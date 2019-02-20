
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

$appVariables      = Get-JSON "$packerTemplatesPath/win-2016-datacenter-app/variables.json"
$appProvision      = Get-JSON "$packerTemplatesPath/win-2016-datacenter-app/provisioners.json"

$specExtractor     = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"

$sql16Variables       = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16/variables.json"
$sql16Provisioners    = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16/provisioners.json"

$sql16SP2Variables  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16-sp2/variables.json"

$sql16SCUVariables    = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16-cu2/variables.json"
$sql16SCUProvisioners = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16-cu/provisioners.json"

$sqlSsmsVariables     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-ssms/variables.json"
$sqlSsmsProvisioners  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-ssms/provisioners.json"

$optimizeUplift    = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-optimize.json"

$template = @{
    "builders"        = $coreBuilder.builders

    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $appVariables.variables `
                            $sql16Variables.variables `
                            $sql16SP2Variables.variables `
                            $sql16SCUVariables.variables `
                            $sqlSsmsVariables.variables

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $coreUplift.provisioners `
                            $appProvision.provisioners `
                            $sql16Provisioners.provisioners `
                            $sql16SCUProvisioners.provisioners `
                            $sqlSsmsProvisioners.provisioners `
                            $specExtractor.provisioners `
                            $optimizeUplift.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
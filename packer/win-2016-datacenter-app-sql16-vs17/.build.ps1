﻿
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

$soeVariables            = Get-JSON "$packerTemplatesPath/win-2016-datacenter-soe/variables.json"
$soeUpliftProvisioners   = Get-JSON "$packerTemplatesPath/win-2016-datacenter-soe/provisioners.json"

$specExtractor     = Get-JSON "$packerTemplatesPath/common/provisioners-uplift-box-spec-extractor.json"

$sql16Variables       = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16/variables.json"
$sql16Provisioners    = Get-JSON "$packerTemplatesPath/win-2016-datacenter-sql16/provisioners.json"

$sqlSsmsVariables     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-ssms/variables.json"
$sqlSsmsProvisioners  = Get-JSON "$packerTemplatesPath/win-2016-datacenter-ssms/provisioners.json"

$vs17Variables        = Get-JSON "$packerTemplatesPath/win-2016-datacenter-vs17/variables.json"
$vs17Provisioners     = Get-JSON "$packerTemplatesPath/win-2016-datacenter-vs17/provisioners.json"

$template = @{
    "builders"        = $coreBuilder.builders

    "variables"       = Merge-Objects `
                            $coreVaiables.variables `
                            $soeVariables.variables `
                            $appVariables.variables `
                            $sql16Variables.variables `
                            $sqlSsmsVariables.variables `
                            $vs17Variables.variables `

    "provisioners"    = Merge-ObjectsAsArray `
                            $coreBuilder.provisioners `
                            $coreUplift.provisioners `
                            $soeUpliftProvisioners.provisioners `
                            $appProvision.provisioners `
                            $sql16Provisioners.provisioners `
                            $sqlSsmsProvisioners.provisioners `
                            $vs17Provisioners.provisioners `
                            $specExtractor.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
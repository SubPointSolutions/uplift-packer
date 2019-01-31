
$ErrorActionPreference = "Stop"

$dirPath    = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = $MyInvocation.MyCommand.Name
$packerTemplatesPath = "./../packer_templates"

. "$dirPath/../.build-helpers.ps1"

$templateFileName  = Get-PackerTemplateName($scriptPath)

$coreVaiables      = Get-JSON "$packerTemplatesPath/ubuntu-trusty64/variables.json"
$coreBuilder       = Get-JSON "$packerTemplatesPath/common-linux/builders-vagrant.json"
$corePostProcessor = Get-JSON "$packerTemplatesPath/common-linux/post-processors-vagrant.json"

$template = @{
    "builders"        = $coreBuilder.builders

    "variables"       = Merge-Objects `
                            $coreVaiables.variables

    # "provisioners"    = Merge-ObjectsAsArray `
    #                         $coreBuilder.provisioners

    "post-processors" = $corePostProcessor.'post-processors'
}

Save-JSON $template $templateFileName
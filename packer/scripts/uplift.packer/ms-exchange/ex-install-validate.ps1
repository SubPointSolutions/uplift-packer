# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Validating Exchange install"
Write-UpliftEnv

$vagrantPass = ConvertTo-SecureString "vagrant" -AsPlainText -Force
$vagrantCreds = New-Object System.Management.Automation.PSCredential( 
    "uplift\vagrant", 
    $vagrantPass 
)

$testScriptBlock = {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue
    $server = Get-ExchangeServer

    $server | format-table -AutoSize

    if($null -ne $server) {
        exit 0
    }

    exit -1
}

Invoke-Command -ScriptBlock $testScriptBlock `
                -ComputerName $env:COMPUTERNAME `
                -Credential $vagrantCreds  `
                -Authentication CredSSP `

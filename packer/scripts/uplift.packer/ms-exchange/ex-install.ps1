# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing Exchange"
Write-UpliftEnv

$resourceName = Get-UpliftEnvVariable "UPLF_EXCHANGE_RESOURCE_NAME" "" "ms-exchange2016-update-2019.02.12-kb4471392-cu12"
$uplifLocalRepository =  Get-UpliftEnvVariable "UPLF_LOCAL_REPOSITORY_PATH" "" "c:/_uplift_resources"

Configuration InstallExchange
{
    Import-DscResource -Module xExchange -ModuleVersion "1.27.0.0"

    Node localhost
    {
        $vagrantPass = ConvertTo-SecureString "vagrant" -AsPlainText -Force
        $ExchangeAdminCredential = New-Object System.Management.Automation.PSCredential( 
            "uplift\vagrant", 
            $vagrantPass 
        )

        xExchInstall InstallExchange
        {
            Path       = ($uplifLocalRepository + "/" + $resourceName + "/latest/Setup.exe")
            Arguments  = '/mode:Install /role:Mailbox /OrganizationName:uplift /Iacceptexchangeserverlicenseterms'
            Credential = $ExchangeAdminCredential
        }
    }
}

$config = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true

            RetryCount = 10
            RetryIntervalSec = 30
        }
    )
}

$configuration = Get-Command InstallExchange
Start-UpliftDSCConfiguration $configuration $config $True 

exit 0
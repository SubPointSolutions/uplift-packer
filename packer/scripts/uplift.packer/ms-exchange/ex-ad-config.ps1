# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Configring Active Directory"
Write-UpliftEnv

Configuration ConfigureExAD
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xActiveDirectory' -ModuleVersion "2.25.0.0"
    
    Node localhost
    {
        $DomainController  = "uplift"

        $vagrantPass = ConvertTo-SecureString "vagrant" -AsPlainText -Force
        $vagrantCredential = New-Object System.Management.Automation.PSCredential( 
            "uplift\vagrant", 
            $vagrantPass 
        )

        xADGroup EnterpriseAdminsGroup
        {
            DomainController           = $DomainController 
            GroupName           = "Enterprise Admins"
            MembersToInclude    = @(
                "vagrant"
            )
            Credential = $vagrantCredential
        }

        xADGroup DomainAdminsGroup
        {
            DomainController           = $DomainController 
            GroupName           = "Domain Admins"
            MembersToInclude    = @(
                "vagrant"
            )
            Credential = $vagrantCredential
        }

        xADGroup OrganizationManagementGroup
        {
            DomainController           = $DomainController 
            GroupName           = "Organization Management"
            MembersToInclude    = @(
                "vagrant"
            )
            Credential = $vagrantCredential
        }

        xADGroup SchemaAdmins
        {
            DomainController           = $DomainController 
            GroupName           = "Schema Admins"
            MembersToInclude    = @(
                "vagrant"
            )
            Credential = $vagrantCredential
        }
        
    }
}

$config = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
            RetryCount = 10
            RetryIntervalSec = 30
        }
    )
}

$configuration = Get-Command ConfigureExAD
Start-UpliftDSCConfiguration $configuration $config $True -verbose
# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftInfoMessage "Processing run-sysprep-nounattend..."
Write-UpliftEnv

for ([byte]$c = [char]'A'; $c -le [char]'Z'; $c++)
{
	$variablePath = [char]$c + ':\variables.ps1'

	if (test-path $variablePath) {
		. $variablePath
		break
	}
}

@('c:\unattend.xml', 'c:\windows\panther\unattend\unattend.xml', 'c:\windows\panther\unattend.xml', 'c:\windows\system32\sysprep\unattend.xml') | ForEach-Object{
	if (test-path $_){
		Write-UpliftInfoMessage "Removing $($_)"
		remove-item $_ > $null
	}
}

if (!(test-path 'c:\windows\panther\unattend')) {
	Write-UpliftInfoMessage "Creating directory $($_)"
    New-Item -path 'c:\windows\panther\unattend' -type directory > $null
}

if (Test-Path 'a:\Autounattend_sysprep.xml'){
	Write-UpliftInfoMessage "Copying a:\Autounattend_sysprep.xml to c:\windows\panther\unattend\unattend.xml"
	Copy-Item 'a:\Autounattend_sysprep.xml' 'c:\windows\panther\unattend\unattend.xml' > $null
} elseif (Test-Path 'c:\Autounattend_sysprep.xml'){
	Write-UpliftInfoMessage "Copying c:\Autounattend_sysprep.xml to c:\windows\panther\unattend\unattend.xml"
	Copy-Item 'c:\Autounattend_sysprep.xml' 'c:\windows\panther\unattend\unattend.xml' > $null
} elseif (Test-Path 'e:\Autounattend_sysprep.xml'){
	Write-UpliftInfoMessage "Copying e:\Autounattend_sysprep.xml to c:\windows\panther\unattend\unattend.xml"
	Copy-Item 'e:\Autounattend_sysprep.xml' 'c:\windows\panther\unattend\unattend.xml' > $null
} else {
	Write-UpliftInfoMessage "Copying f:\Autounattend_sysprep.xml to c:\windows\panther\unattend\unattend.xml"
	Copy-Item 'f:\Autounattend_sysprep.xml' 'c:\windows\panther\unattend\unattend.xml'> $null
}

&c:\windows\system32\sysprep\sysprep.exe /generalize /oobe /mode:vm /quiet /quit /unattend:c:\windows\panther\unattend\unattend.xml

Write-UpliftInfoMessage "sysprep exit code was $LASTEXITCODE"

Write-UpliftInfoMessage "Running shutdown"
&shutdown -s
Write-UpliftInfoMessage "shutdown exit code was $LASTEXITCODE"

Write-UpliftInfoMessage "Return exit 0"
exit 0
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

&c:\windows\system32\sysprep\sysprep.exe /generalize /oobe /mode:vm /quiet /quit

Write-UpliftInfoMessage "sysprep exit code was $LASTEXITCODE"

Write-UpliftInfoMessage "Running shutdown"
&shutdown -s
Write-UpliftInfoMessage "shutdown exit code was $LASTEXITCODE"

Write-UpliftInfoMessage "Return exit 0"
exit 0
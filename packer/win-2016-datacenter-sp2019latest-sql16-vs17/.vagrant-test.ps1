Write-Host "vagrant testing: vagrant up"
vagrant up 
if ($LASTEXITCODE -ne 0 ) { throw "Fail!" }

Write-Host "vagrant testing: vagrant reload --provision"
vagrant reload sp19latest-s16v17 --provision
if ($LASTEXITCODE -ne 0 ) { throw "Fail!" }
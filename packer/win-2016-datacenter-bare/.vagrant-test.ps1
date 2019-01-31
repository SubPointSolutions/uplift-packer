
Write-Host "vagrant testing: vagrant up client"
vagrant up client
if ($LASTEXITCODE -ne 0) { throw "vagrant testing: vagrant up client" }

Write-Host "vagrant testing: vagrant up client --provision"
vagrant up client --provision
if ($LASTEXITCODE -ne 0) { throw "vagrant testing: vagrant up client --provision" }

Write-Host "vagrant testing: vagrant reload client --provision"
vagrant reload client --provision
if ($LASTEXITCODE -ne 0) { throw "vagrant testing: vagrant reload client --provision" }

exit 0
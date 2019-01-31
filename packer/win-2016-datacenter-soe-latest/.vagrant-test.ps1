Write-Host "vagrant testing: vagrant up dc-shared"
vagrant up dc-shared

Write-Host "vagrant testing: vagrant up client"
vagrant up client

Write-Host "vagrant testing: vagrant up client --provision"
vagrant up client --provision

Write-Host "vagrant testing: vagrant reload client --provision"
vagrant reload client --provision
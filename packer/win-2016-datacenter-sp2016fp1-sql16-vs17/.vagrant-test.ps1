Write-Host "vagrant testing: vagrant up dc-shared"
vagrant up dc-shared

Write-Host "vagrant testing: vagrant up client"
vagrant up sp16-dev

Write-Host "vagrant testing: vagrant up client --provision"
vagrant up sp16-dev --provision

Write-Host "vagrant testing: vagrant reload client --provision"
vagrant reload sp16-dev --provision
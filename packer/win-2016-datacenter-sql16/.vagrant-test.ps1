Write-Host "vagrant testing: vagrant up dc-shared"
vagrant up dc-shared

Write-Host "vagrant testing: vagrant up client"
vagrant up s16-single

Write-Host "vagrant testing: vagrant up client --provision"
vagrant up s16-single --provision

Write-Host "vagrant testing: vagrant reload client --provision"
vagrant reload s16-single --provision
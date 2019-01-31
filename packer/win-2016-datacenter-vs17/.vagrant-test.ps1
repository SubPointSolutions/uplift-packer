Write-Host "vagrant testing: vagrant up dc-shared"
vagrant up dc-shared

Write-Host "vagrant testing: vagrant up client"
vagrant up vs17-single

Write-Host "vagrant testing: vagrant up client --provision"
vagrant up vs17-single --provision

Write-Host "vagrant testing: vagrant reload client --provision"
vagrant reload vs17-single --provision
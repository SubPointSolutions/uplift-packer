# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Optimizing image"
Write-UpliftEnv

# optimizing image
# the script is based on various resources out there

# https://communities.vmware.com/thread/528234

# https://github.com/ops-resource/ops-tools-baseimage
# https://github.com/ops-resource/ops-tools-baseimage/blob/83e17f2ec6a82d593e6f7d9d71dedcd48db56453/src/windows/scripts/Invoke-NGen.ps1

function Optimize-UpliftNetAssemblies() {

    Write-UpliftMessage "  [~] Re-compiling .NET assemblies"

    if ((Get-WmiObject -Class Win32_OperatingSystem -ComputerName $env:COMPUTERNAME -ea 0).OSArchitecture -eq '64-bit')
    {
        &"$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe" update /force /queue
        &"$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe" executequeueditems
    }
    else
    {
        &"$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe" update /force /queue
        &"$env:windir\microsoft.net\framework64\v4.0.30319\ngen.exe" update /force /queue
        &"$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe" executequeueditems
        &"$env:windir\microsoft.net\framework64\v4.0.30319\ngen.exe" executequeueditems
    }

    Write-UpliftMessage "  [+] Re-compiling .NET assemblies completed"
}

function Optimize-UpliftSystemVolume() {
    Write-UpliftMessage "  [~] Optimize-Volume: system drive"

    Optimize-Volume -DriveLetter $($env:SystemDrive)[0] -Verbose

    Write-UpliftMessage "  [+] Optimize-Volume: system drive completed"
}   

function Optimize-UpliftServices() {

    # TODO
    # current implementation breaks start menu tiles
    # needs more investigation, disabled via ENV variables for the time being

    # https://github.com/ops-resource/ops-tools-baseimage/blob/83e17f2ec6a82d593e6f7d9d71dedcd48db56453/src/windows/scripts/Disable-Services.ps1

    Write-UpliftMessage "  [~] Optimizing windows services"

    $servicesToDisable = @(
        'AppReadiness',
        'AppXSvc',
        'Diagtrack',
        'DmwApPushService',
        'OneSyncSvc',
        'tiledatamodelsvc',
        'ualsvc',
        'XblAuthManager',
        'XblGameSave'
    )

    foreach($serviceName in $servicesToDisable)
    {
        Write-UpliftMessage "Stopping and disabling service: $serviceName"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        if($null -ne $service) {
            stop-service $service
            Write-UpliftMessage " [+] stopped and disabled: $serviceName"

             # Apparently setting the service state in powershell doesn't always stick, so ...
            $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"
            if (Test-Path $path)
            {
                Set-ItemProperty -Path $path -Name Start -Value 4 -Force
            }
        } else {
            Write-UpliftMessage " [!] cannot find service by name: $serviceName"
        }
    }

    Write-UpliftMessage "  [~] Optimizing windows services completed"
} 

function Optimize-UpliftPowerConfig() {

    Write-UpliftMessage "  [~] Optimizing powercfg"

    # High Performance	
    # https://docs.microsoft.com/en-us/windows/desktop/power/power-policy-settings
    &powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Monitor timeout
    &powercfg -Change -monitor-timeout-ac 0
    &powercfg -Change -monitor-timeout-dc 0
    &powercfg -hibernate OFF

    Write-UpliftMessage "  [+] Optimizing powercfg completed"
}

function Optimize-UpliftWindowsTemp() {
    Write-UpliftMessage "  [~] Optimizing windows temp folder"

    Remove-Item 'C:/windows/temp/*' -Recurse -Force -ErrorAction SilentlyContinue

    Write-UpliftMessage "  [+] Optimizing windows temp folder completed"
}

function Optimize-UpliftZeroSpace() {
    # https://github.com/mwrock/packer-templates/blob/master/scripts/cleanup.ps1

    Write-UpliftMessage "  [~] Wiping empty space on disk"

    $FilePath="c:\zero.tmp"
    $Volume = Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'"
    $ArraySize= 64kb
    $SpaceToLeave= $Volume.Size * 0.05
    $FileSize= $Volume.FreeSpace - $SpacetoLeave
    $ZeroArray= new-object byte[]($ArraySize)
    
    $Stream= [io.File]::OpenWrite($FilePath)
    
    try {
        $CurFileSize = 0
        $lastProgress = 0

        while($CurFileSize -lt $FileSize) {

            $progress = [math]::Round($CurFileSize / $FileSize * 100);

            if( $progress % 5 -eq 0 -and $lastProgress -ne  $progress) {
                Write-UpliftMessage "  [~] progress: $progress%"
                $lastProgress =  $progress
            }

            $Stream.Write($ZeroArray,0, $ZeroArray.Length)
            $CurFileSize += $ZeroArray.Length
        }
    }
    finally {
        if($Stream) {
            $Stream.Close()
        }

        Remove-Item $FilePath -Force
    }
    
    Write-UpliftMessage "  [+] Wiping empty space on disk completed"
}

# by default, run all of them
$optimizers = @(
    "Optimize-UpliftNetAssemblies"
    "Optimize-UpliftServices"
    "Optimize-UpliftPowerConfig"
    "Optimize-UpliftWindowsTemp"
    "Optimize-UpliftSystemVolume"
    "Optimize-UpliftZeroSpace"
)

if( ([String]::IsNullOrEmpty($env:UPLF_IMAGE_OPTIMIZE_FUNCTIONS)) -eq $False) {
    Write-UpliftMessage "[!] using CUSTOM optimizers"
    $optimizers = ($env:UPLF_IMAGE_OPTIMIZE_FUNCTIONS).Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
} else {
    Write-UpliftMessage "[!] using default optimizers, all of them"
}

Write-UpliftMessage ([Environment]::NewLine + [String]::Join([Environment]::NewLine , $optimizers))

$optimizersCount = $optimizers.Count
$index = 1

foreach($optimizer in $optimizers) {
    Write-UpliftMessage "[$index/$optimizersCount] running optimization"

    $cmd = Get-Command $optimizer
    & $cmd

    $index = $index + 1
}

Write-UpliftMessage "Optimizing image completed!" 
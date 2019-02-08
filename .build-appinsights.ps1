function Write-UpliftAppInsighsMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

    param(
        $message
    )

    $logCmdNames = @(
        "Write-BuildDebugMessage"
        "Write-UpliftDebugMessage"
        "Write-Host"
    )

    foreach ($logCmdNames in $logCmdNames) {
        $logCmmd = Get-Command $logCmdNames -ErrorAction SilentlyContinue

        if($null -ne $logCmmd) {
            & $logCmmd.Name $message
            break;
        }
    }
}

function Confirm-UpliftUpliftAppInsightClient {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(

    )

    if(Test-UpliftNoAppInsight -eq $True) {
        Write-UpliftAppInsighsMessage "[+] Skipping AppInsight setup"
        return
    }

    # https://vnextengineer.azurewebsites.net/powershell-application-insights/

    try {
        if($null -ne $script:UpliftAppInsightClient) {
            return;
        }

        $hereFolder = $PSScriptRoot

        $packageVersion = $env:UPLF_APPINSIGHTS_PACKAGE_VERSION;
        if( [String]::IsNullOrEmpty($packageVersion) -eq $True ) { $packageVersion = '2.9.0' }

        Write-UpliftAppInsighsMessage "Ensuring AppInsight setup: v$packageVersion"

        $appInsightPackageUrl = "https://www.nuget.org/api/v2/package/Microsoft.ApplicationInsights/$packageVersion"

        $appInsightFolderPath = Join-Path $hereFolder "build-utils"
        [System.IO.Directory]::CreateDirectory($appInsightFolderPath) | Out-Null

        $appInsightPackageFolderPath = Join-Path $hereFolder "build-utils/microsoft.applicationinsights"
        [System.IO.Directory]::CreateDirectory($appInsightPackageFolderPath) | Out-Null

        $appInsightFilePath = Join-Path $appInsightFolderPath "microsoft.applicationinsights.zip"

        # download package
        if( (Test-Path $appInsightFilePath) -eq $False) {
            Write-UpliftAppInsighsMessage "[~] downloading AppInsight package for the first time"
            Write-UpliftAppInsighsMessage " - src: $appInsightPackageUrl"

            Invoke-WebRequest -Uri $appInsightPackageUrl `
                        -OutFile $appInsightFilePath `
                        -MaximumRedirection 10 `
                        -UseBasicParsing
        } else {
            Write-UpliftAppInsighsMessage "[+] AppInsight package exists"
        }

        # unpack package
        if( (Get-ChildItem $appInsightPackageFolderPath | Measure-Object).count -eq 0) {
            Write-UpliftAppInsighsMessage "[+] Extracting AppInsight package"
            Expand-Archive -Path $appInsightFilePath `
                -DestinationPath $appInsightPackageFolderPath `
                -Force `
                | Out-Null
        } else {
            Write-UpliftAppInsighsMessage "[+] AppInsight package is unpacked"
        }

        # load package
        $appInsightAssemblyPath = "$appInsightPackageFolderPath\lib\netstandard1.3\Microsoft.ApplicationInsights.dll"
        [Reflection.Assembly]::LoadFile($appInsightAssemblyPath) | Out-Null

        $key = $env:UPLF_APPINSIGHTS_KEY
        if([String]::IsNullOrEmpty($value) -eq $True) { $key = 'c297a2cc-8194-46ac-bf6b-46edd4c7d2c9' }

        $client = New-Object "Microsoft.ApplicationInsights.TelemetryClient"
        $client.InstrumentationKey = $key

        $script:UpliftAppInsightClient = $client
    } catch {
        Write-UpliftAppInsighsMessage "[!] Failed to prepare ApplicationInsights client"
        Write-UpliftAppInsighsMessage "[!] $_"
    }
}

function Test-UpliftNoAppInsight()
{
    return ($null -ne $env:UPLF_NO_APPINSIGHT)
}

function New-UpliftTrackEvent {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $eventName,
        $properties = $null,
        $metrics = $null
    )

    try {
        if( Test-UpliftNoAppInsight -eq $True) {
            Write-UpliftAppInsighsMessage "[+] Skipping AppInsight event: $eventName"
            return;
        }

        Confirm-UpliftUpliftAppInsightClient

        if($null -ne $UpliftAppInsightClient) {
            Write-UpliftAppInsighsMessage "[+] AppInsight event: $eventName"

            $eventProps   =  New-UpliftAppInsighsProperties $properties
            $eventMetrics =  New-UpliftAppInsighsMetrics $metrics

            $UpliftAppInsightClient.TrackEvent($eventName, $eventProps, $eventMetrics)
            $UpliftAppInsightClient.Flush()
        }
    } catch {
        Write-UpliftAppInsighsMessage "[!] Failed to track ApplicationInsights event"
        Write-UpliftAppInsighsMessage "[!] $_"
    }
}

function New-UpliftTrackException {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $exception,
        $properties = $null,
        $metrics = $null
    )

    try {
        if( Test-UpliftNoAppInsight -eq $True) {
            Write-UpliftAppInsighsMessage "[+] Skipping AppInsight event: $eventName"
            return;
        }

        Confirm-UpliftUpliftAppInsightClient

        if($null -ne $UpliftAppInsightClient) {
            Write-UpliftAppInsighsMessage "[+] AppInsight exception: $exception"

            $eventProps   =  New-UpliftAppInsighsProperties $properties
            $eventMetrics =  New-UpliftAppInsighsMetrics $metrics

            $UpliftAppInsightClient.TrackException($exception, $eventProps, $eventMetrics)
            $UpliftAppInsightClient.Flush()
        }
    } catch {
        Write-UpliftAppInsighsMessage "[!] Failed to track ApplicationInsights exception"
        Write-UpliftAppInsighsMessage "[!] $_"
    }
}

function New-UpliftAppInsighsProperties {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $hash = @{}
    )

    $result = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    if($null -eq $hash) {
        
        # empty dictionary
        $result = $result;

    } elseif ($hash -is [System.Collections.Hashtable]) {
        
        # convert incoming powershell hash into dictionary
        foreach ($entry in $hash.GetEnumerator()) {
            $result.Add($entry.Key, $entry.Value);
        }

    } elseif ($hash -is [System.Collections.Generic.Dictionary[[String],[String]]]) {
        
        # that's the right type already
        $result = $hash

    } else {
        throw "Cannont convert type into Dictionary<string,string>, type was: $($hash.GetType())"
    }

    return $result
}

function New-UpliftAppInsighsMetrics {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $hash = @{}
    )

    $result = New-Object "System.Collections.Generic.Dictionary[[String],[Double]]"

    if($null -eq $hash) {
        
        # empty dictionary
        $result = $result;

    } elseif($hash -is [System.Collections.Hashtable]) {
        
        # convert incoming powershell hash into dictionary
        foreach ($entry in $hash.GetEnumerator()) {
            $result.Add($entry.Key, $entry.Value);
        }

    } elseif ($hash -is [System.Collections.Generic.Dictionary[[String],[Double]]]) {
        
        # that's the right type already
        $result = $hash

    } else {
        throw "Cannont convert type into Dictionary<string,double>, type was: $($hash.GetType())"
    }

    return $result
}
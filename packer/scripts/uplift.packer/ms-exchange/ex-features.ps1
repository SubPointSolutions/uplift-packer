# fail on errors and include uplift helpers
$ErrorActionPreference = "Stop"

Import-Module Uplift.Core

Write-UpliftMessage "Installing Exchange features"
Write-UpliftEnv

Install-WindowsFeature `
    NET-Framework-45-Features, `
    RPC-over-HTTP-proxy, `
    RSAT-Clustering, `
    RSAT-Clustering-CmdInterface, `
    RSAT-Clustering-Mgmt, `
    RSAT-Clustering-PowerShell, `
    Web-Mgmt-Console, `
    WAS-Process-Model, `
    Web-Asp-Net45, `
    Web-Basic-Auth, `
    Web-Client-Auth, `
    Web-Digest-Auth, `
    Web-Dir-Browsing, `
    Web-Dyn-Compression, `
    Web-Http-Errors, `
    Web-Http-Logging, `
    Web-Http-Redirect, `
    Web-Http-Tracing, `
    Web-ISAPI-Ext, `
    Web-ISAPI-Filter, `
    Web-Lgcy-Mgmt-Console, `
    Web-Metabase, `
    Web-Mgmt-Console, `
    Web-Mgmt-Service, `
    Web-Net-Ext45, `
    Web-Request-Monitor, `
    Web-Server, `
    Web-Stat-Compression, `
    Web-Static-Content, `
    Web-Windows-Auth, `
    Web-WMI, `
    Windows-Identity-Foundation, `
    RSAT-ADDS
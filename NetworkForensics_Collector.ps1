
<#
.SYNOPSIS
    Network Forensics Collection Script - Step 6
.DESCRIPTION
    Collects various network-related artifacts to support forensic investigations.
    Artifacts include netstat connections, DNS cache, ARP table, hosts file, firewall rules, WiFi profiles, and more.
.NOTES
    Author: AnalystGPT
    Date: 2025-05-21
#>

# Run this line selection first:
Set-ExecutionPolicy RemoteSigned -Scope Process

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputDir = "C:\NetworkForensics_$timestamp"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Collect network connections
netstat -ano | Out-File "$outputDir\netstat_connections.txt"
Get-NetTCPConnection | Sort-Object State, LocalAddress | Out-File "$outputDir\nettcp_connections.txt"
Get-NetUDPEndpoint | Out-File "$outputDir\netudp_endpoints.txt"

# DNS cache
ipconfig /displaydns | Out-File "$outputDir\dns_cache.txt"

# ARP table
arp -a | Out-File "$outputDir\arp_table.txt"

# Hosts file
Copy-Item -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Destination "$outputDir\hosts_file.txt" -Force

# Firewall rules
Get-NetFirewallRule | Select DisplayName, Direction, Action, Enabled | Out-File "$outputDir\firewall_rules.txt"

# Listening ports
netstat -an | Select-String "LISTENING" | Out-File "$outputDir\listening_ports.txt"

# WiFi profiles
netsh wlan show profiles | Out-File "$outputDir\wifi_profiles.txt"
$wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
    ($_ -split ":")[1].Trim()
}
foreach ($profile in $wifiProfiles) {
    netsh wlan show profile name="$profile" key=clear | Out-File "$outputDir\wifi_profile_$($profile).txt"
}

# Network interfaces
Get-NetIPConfiguration | Out-File "$outputDir\net_ipconfig.txt"

# Proxy settings
netsh winhttp show proxy | Out-File "$outputDir\proxy_settings.txt"

# Zip the collected data
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
$zipFile = "$outputDir.zip"
[System.IO.Compression.ZipFile]::CreateFromDirectory($outputDir, $zipFile)

Write-Output "✅ Network forensics artifacts collected and saved to: $zipFile"

# NetworkAudit.ps1
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "C:\Temp\Forensics\NetworkAudit_$timestamp"
$zipFile = "C:\Temp\Forensics\NetworkAudit_$timestamp.zip"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# Active network connections
netstat -ano | Out-File "$outputDir\netstat.txt"
Get-NetTCPConnection | Sort-Object -Property State | Out-File "$outputDir\Get-NetTCPConnection.txt"

# IP configuration
ipconfig /all | Out-File "$outputDir\ipconfig.txt"
Get-NetIPConfiguration | Out-File "$outputDir\Get-NetIPConfiguration.txt"

# DNS Cache
ipconfig /displaydns | Out-File "$outputDir\dns_cache.txt"

# ARP Table
arp -a | Out-File "$outputDir\arp_table.txt"

# Routing Table
route print | Out-File "$outputDir\routing_table.txt"

# Wireless Networks
netsh wlan show profiles | Out-File "$outputDir\wlan_profiles.txt"
netsh wlan show networks mode=bssid | Out-File "$outputDir\wlan_networks.txt"

# 🔐 Firewall Rules
Get-NetFirewallRule | Sort-Object DisplayName | Out-File "$outputDir\firewall_rules.txt"

# 🔐 VPN Connections
Get-VpnConnection | Out-File "$outputDir\vpn_connections.txt"

# 📊 Adapter Stats
Get-NetAdapterStatistics | Out-File "$outputDir\net_adapter_statistics.txt"

# Export folder to ZIP
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($outputDir, $zipFile)

# Done
Write-Output "📡 Network audit complete."
Write-Output "📁 Report folder: $outputDir"
Write-Output "🗜️  Zipped report: $zipFile"

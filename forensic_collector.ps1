# === Setup ===

# Run this line selection first:
Set-ExecutionPolicy RemoteSigned -Scope Process

$logDir = "C:\Temp\ForensicLogs"
$zipPath = "C:\Temp\ForensicLogs.zip"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

# === 1. System Information ===
$sysInfo = Get-CimInstance Win32_OperatingSystem
$compInfo = Get-CimInstance Win32_ComputerSystem
$biosInfo = Get-CimInstance Win32_BIOS
$cpuInfo = Get-CimInstance Win32_Processor
$memInfo = Get-CimInstance Win32_PhysicalMemory

$sysReport = @"
===== SYSTEM INFO =====
OS Name:         $($sysInfo.Caption)
OS Version:      $($sysInfo.Version)
Build Number:    $($sysInfo.BuildNumber)
Install Date:    $([Management.ManagementDateTimeConverter]::ToDateTime($sysInfo.InstallDate))
Last Boot Time:  $([Management.ManagementDateTimeConverter]::ToDateTime($sysInfo.LastBootUpTime))
Architecture:    $($sysInfo.OSArchitecture)
System Drive:    $($sysInfo.SystemDrive)

===== COMPUTER INFO =====
Computer Name:   $($compInfo.Name)
Manufacturer:    $($compInfo.Manufacturer)
Model:           $($compInfo.Model)
Total RAM:       $("{0:N2}" -f ($compInfo.TotalPhysicalMemory / 1GB)) GB

===== BIOS INFO =====
BIOS Version:    $($biosInfo.SMBIOSBIOSVersion)
BIOS Date:       $($biosInfo.ReleaseDate)

===== CPU INFO =====
CPU Name:        $($cpuInfo.Name)
Cores:           $($cpuInfo.NumberOfCores)
Logical CPUs:    $($cpuInfo.NumberOfLogicalProcessors)
Max Clock Speed: $($cpuInfo.MaxClockSpeed) MHz

===== MEMORY MODULES =====
$($memInfo | ForEach-Object {
    "Manufacturer: $($_.Manufacturer), Capacity: $("{0:N2}" -f ($_.Capacity / 1GB)) GB, Speed: $($_.Speed) MHz"
} | Out-String)

"@

$sysReport | Out-File "$logDir\sysinfo.txt" -Encoding UTF8

# === 2. Installed Programs ===
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
Sort-Object DisplayName |
Out-File "$logDir\installed_programs.txt"

# === 3. Running Tasks and Services ===
tasklist /v > "$logDir\tasklist.txt"
Get-Service | Sort-Object Status | Out-File "$logDir\services.txt"

# === 4. Scheduled Tasks ===
schtasks /query /fo LIST /v > "$logDir\schtasks.txt"

# === 5. Drivers ===
driverquery /v /fo list > "$logDir\drivers.txt"

# === 6. Network Configuration ===
ipconfig /all > "$logDir\netconfig.txt"
arp -a >> "$logDir\netconfig.txt"
netstat -ano >> "$logDir\netconfig.txt"

# === 7. Firewall Rules ===
netsh advfirewall firewall show rule name=all > "$logDir\firewall_rules.txt"

# === 8. Startup Items ===
Get-CimInstance Win32_StartupCommand |
Select-Object Name, Command, Location |
Out-File "$logDir\startup_programs.txt"

# === 9. User Accounts & Groups ===
net user > "$logDir\local_users.txt"
net localgroup > "$logDir\local_groups.txt"

# === 10. Optional: Event Logs (Last 100 from System and Application) ===
Get-WinEvent -LogName System -MaxEvents 100 | Format-Table -AutoSize > "$logDir\system_events.txt"
Get-WinEvent -LogName Application -MaxEvents 100 | Format-Table -AutoSize > "$logDir\application_events.txt"

# === 11. ZIP Archive ===
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Compress-Archive -Path "$logDir\*" -DestinationPath $zipPath

Write-Host "Logs collected at $logDir"
Write-Host "Logs zipped into: $zipPath"

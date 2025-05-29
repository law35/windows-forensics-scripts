# UserActivityAudit.ps1

# Run this line selection first:
Set-ExecutionPolicy RemoteSigned -Scope Process

# Requires admin privileges
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "C:\Temp\UserActivity_$timestamp"
$null = New-Item -Path $outputDir -ItemType Directory -Force

# --- 1. Logon / Logoff History ---
$logonEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624, 4634} -MaxEvents 500 |
    Select-Object TimeCreated, Id, @{N="User";E={$_.Properties[5].Value}}, Message
$logonEvents | Export-Csv -Path "$outputDir\logon_history.csv" -NoTypeInformation

# --- 2. User Accounts and Groups ---
net user > "$outputDir\net_user.txt"
net localgroup > "$outputDir\local_groups.txt"
Get-LocalGroupMember -Group "Administrators" | Out-File "$outputDir\admin_group_members.txt"

# --- 3. Scheduled Tasks ---
schtasks /query /fo LIST /v > "$outputDir\scheduled_tasks.txt"

# --- 4. Startup / Autoruns ---
$startupPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($path in $startupPaths) {
    if (Test-Path $path) {
        Get-ItemProperty $path | Out-File "$outputDir\autoruns_$(($path -replace '[\\:\*?<>|]', '_')).txt"
    }
}
$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($folder in $startupFolders) {
    if (Test-Path $folder) {
        Get-ChildItem $folder | Out-File "$outputDir\startup_folder_$(Split-Path $folder -Leaf).txt"
    }
}

# --- 5. USB Device History ---
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*" -ErrorAction SilentlyContinue |
    Select-Object FriendlyName, PSChildName |
    Export-Csv "$outputDir\usb_devices.csv" -NoTypeInformation

# --- Optional Shellbags (Disabled by default) ---
<# 
Requires forensic tools like ShellBagsExplorer or deep registry parsing.
Can be added later if needed.
#>

# --- Zip the report ---
$zipFile = "$outputDir.zip"
Compress-Archive -Path $outputDir -DestinationPath $zipFile -Force

Write-Host "âœ… User activity forensic data saved to: $zipFile"

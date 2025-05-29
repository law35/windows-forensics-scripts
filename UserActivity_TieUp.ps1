# Filename: UserActivity_TieUp.ps1
# Purpose: Completes Step 5 of the forensic process by gathering logon/logoff history, recent files, jump lists, scheduled tasks, and autorun items.

# Run this line selection first:
Set-ExecutionPolicy RemoteSigned -Scope Process

# ----------------------------
# Configuration
# ----------------------------
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputDir = "D:\ForensicReports\UserActivity_$timestamp"
$zipFile = "$outputDir.zip"

# Create output directory
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# ----------------------------
# 1. Logon/Logoff Events
# ----------------------------
$logonEvents = @(4624, 4647, 4634)
$outputLog = "$outputDir\logon_logoff_events.txt"

foreach ($eventID in $logonEvents) {
    Get-WinEvent -FilterHashtable @{LogName='Security'; Id=$eventID} -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, Message |
        Out-File -Append -FilePath $outputLog
}

# ----------------------------
# 2. Recent Files per user
# ----------------------------
$recentDir = "$outputDir\recent_files"
New-Item -ItemType Directory -Force -Path $recentDir | Out-Null

Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    $userRecent = Join-Path $_.FullName "AppData\Roaming\Microsoft\Windows\Recent"
    if (Test-Path $userRecent) {
        Copy-Item -Path "$userRecent\*" -Destination "$recentDir\$($_.Name)_recent" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ----------------------------
# 3. Jump Lists
# ----------------------------
$jumpListDir = "$outputDir\jumplists"
New-Item -ItemType Directory -Force -Path $jumpListDir | Out-Null

Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    $automaticDest = Join-Path $_.FullName "AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations"
    $customDest = Join-Path $_.FullName "AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations"

    if (Test-Path $automaticDest) {
        Copy-Item "$automaticDest\*" -Destination "$jumpListDir\$($_.Name)_auto" -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $customDest) {
        Copy-Item "$customDest\*" -Destination "$jumpListDir\$($_.Name)_custom" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ----------------------------
# 4. Scheduled Tasks
# ----------------------------
Get-ScheduledTask | Select-Object TaskName, TaskPath, State, Actions, Triggers | Out-File "$outputDir\scheduled_tasks.txt"

# ----------------------------
# 5. Autorun Items (Registry-based)
# ----------------------------
$outputAutoruns = "$outputDir\autorun_items.txt"

"HKCU\Software\Microsoft\Windows\CurrentVersion\Run:" | Out-File $outputAutoruns -Append
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | Out-String | Out-File $outputAutoruns -Append

"HKLM\Software\Microsoft\Windows\CurrentVersion\Run:" | Out-File $outputAutoruns -Append
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" | Out-String | Out-File $outputAutoruns -Append

"HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run:" | Out-File $outputAutoruns -Append
Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" | Out-String | Out-File $outputAutoruns -Append

# ----------------------------
# Zip Results
# ----------------------------
Compress-Archive -Path $outputDir\* -DestinationPath $zipFile -Force
Write-Host “‚ Final user activity data saved to: $zipFile"

# SecureBoot_TPM_Audit.ps1
# Audits TPM, Secure Boot, BitLocker, Defender Events, Startup Items, Scheduled Tasks
# Outputs are zipped for collection

# Output folder setup
$outputDir = "C:\Temp\SecureAudit"
$zipFile = "C:\Temp\SecureAudit.zip"
if (!(Test-Path $outputDir)) { New-Item -Path $outputDir -ItemType Directory | Out-Null }

function Log {
    param ([string]$message)
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $message"
}

function Save-Result {
    param ([string]$data, [string]$filename)
    $filePath = Join-Path $outputDir $filename
    $data | Out-File -FilePath $filePath -Encoding UTF8
}

# 1. TPM Status
Write-Progress -Activity "Gathering Data" -Status "1/6: TPM Info"
Log "Getting TPM status..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm
$tpm | Format-List | Out-File "$outputDir\TPM.txt"
$sw.Stop(); Log "TPM data collected in $($sw.Elapsed.Seconds)s"

# 2. Secure Boot Status
Write-Progress -Activity "Gathering Data" -Status "2/6: Secure Boot"
Log "Checking Secure Boot..."
$sw.Restart()
try {
    $secureBoot = Confirm-SecureBootUEFI
} catch {
    $secureBoot = "Secure Boot status cannot be determined on this system."
}
Save-Result -data "Secure Boot Enabled: $secureBoot" -filename "SecureBoot.txt"
$sw.Stop(); Log "Secure Boot check completed in $($sw.Elapsed.Seconds)s"

# 3. BitLocker Status
Write-Progress -Activity "Gathering Data" -Status "3/6: BitLocker"
Log "Retrieving BitLocker info..."
$sw.Restart()
$bitlocker = Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod
$bitlocker | Out-File "$outputDir\BitLocker.txt"
$sw.Stop(); Log "BitLocker status retrieved in $($sw.Elapsed.Seconds)s"

# 4. Startup Items
Write-Progress -Activity "Gathering Data" -Status "4/6: Startup Items"
Log "Listing startup items..."
$sw.Restart()
Get-CimInstance -ClassName Win32_StartupCommand |
    Select-Object Name, Command, Location |
    Out-File "$outputDir\StartupItems.txt"
$sw.Stop(); Log "Startup items exported in $($sw.Elapsed.Seconds)s"

# 5. Scheduled Tasks
Write-Progress -Activity "Gathering Data" -Status "5/6: Scheduled Tasks"
Log "Extracting non-Microsoft scheduled tasks..."
$sw.Restart()
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -notlike '\Microsoft*' }
$tasks | Format-List | Out-File "$outputDir\ScheduledTasks.txt"
$sw.Stop(); Log "Scheduled tasks recorded in $($sw.Elapsed.Seconds)s"

# 6. Defender Events
Write-Progress -Activity "Gathering Data" -Status "6/6: Windows Defender Logs"
Log "Exporting recent Windows Defender events..."
$sw.Restart()
$defenderEvents = Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 100 |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-7) }
$defenderEvents | Format-List | Out-File "$outputDir\DefenderEvents.txt"
$sw.Stop(); Log "Defender events saved in $($sw.Elapsed.Seconds)s"

# Finish: Zip Results
Write-Progress -Activity "Finalizing" -Status "Compressing Report..."
Log "Zipping collected files..."
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::CreateFromDirectory($outputDir, $zipFile)
Log "✅ Zipped report: $zipFile"

Write-Progress -Activity "Secure Audit Complete" -Completed
Log "All tasks complete."

# ProcessServiceAudit.ps1
# Description: Gathers running process and service information for forensic analysis.

# Define paths
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputDir = "C:\Temp\Forensics\ProcessServiceAudit_$timestamp"
$zipFile = "C:\Temp\Forensics\ProcessServiceAudit_$timestamp.zip"

# Create directory
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Output files
$processesFile = Join-Path $outputDir "Running_Processes.txt"
$servicesFile = Join-Path $outputDir "Running_Services.txt"

Write-Host "🛠️ Collecting running processes..."
Get-Process | Sort-Object ProcessName | Out-File -Encoding UTF8 $processesFile

Write-Host "🛠️ Collecting running services..."
Get-Service | Where-Object {$_.Status -eq 'Running'} | Sort-Object DisplayName | Out-File -Encoding UTF8 $servicesFile

# Optional: WMI-based remote query section (commented out by default)
<#
# Uncomment below to enable remote system process & service gathering
$remoteComputers = @("RemotePC1", "RemotePC2")
foreach ($computer in $remoteComputers) {
    $remoteProcFile = Join-Path $outputDir "$computer`_Processes.txt"
    $remoteSvcFile = Join-Path $outputDir "$computer`_Services.txt"

    try {
        Get-WmiObject Win32_Process -ComputerName $computer | Out-File -Encoding UTF8 $remoteProcFile
        Get-WmiObject Win32_Service -ComputerName $computer | Where-Object { $_.State -eq 'Running' } | Out-File -Encoding UTF8 $remoteSvcFile
    }
    catch {
        Write-Warning "Failed to query $computer: $_"
    }
}
#>

# Compress output
Write-Host "📦 Zipping the output..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($outputDir, $zipFile)

Write-Output "📦 Output saved to: $zipFile"

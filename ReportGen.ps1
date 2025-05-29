# Final Report Generator with Hash Check and Integrity Verification

```powershell
# Requires: PowerShell 5+, Posh-ACME, WindowsCompatibility module for PDF conversion if needed
# Note: Run as Administrator

# Configuration
$outputDir = "D:\ForensicReports"
$timelineCsv = "$outputDir\InvestigationTimeline.csv"
$pdfReport = "$outputDir\ForensicSummaryReport.pdf"
$zipArchive = "$outputDir\ForensicCollection.zip"
$hashesFile = "$outputDir\CollectedFileHashes.txt"
$baselineHashFile = "$outputDir\BaselineHashes.txt"
$integrityReport = "$outputDir\HashIntegrityCheck.txt"

# Create output directory if it doesn't exist
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Function to compute hashes for all files in directory
function Get-FileHashes {
    param (
        [string]$TargetDir,
        [string]$OutputFile
    )
    Get-ChildItem -Recurse -File -Path $TargetDir | ForEach-Object {
        $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
        "${($hash.Path)} | $($hash.Hash)"
    } | Set-Content -Path $OutputFile
    Write-Host "✅ Hashes computed and saved to: $OutputFile"
}

# Function to compare current hashes against a baseline
function Compare-Hashes {
    param (
        [string]$BaselineFile,
        [string]$CurrentFile,
        [string]$ReportFile
    )
    $baseline = Get-Content $BaselineFile | ConvertFrom-String -PropertyNames Path,Hash -Delimiter "|"
    $current = Get-Content $CurrentFile | ConvertFrom-String -PropertyNames Path,Hash -Delimiter "|"
    $comparison = foreach ($item in $current) {
        $match = $baseline | Where-Object { $_.Path.Trim() -eq $item.Path.Trim() }
        if ($match -and $match.Hash.Trim() -eq $item.Hash.Trim()) {
            "$($item.Path.Trim()) - OK"
        } else {
            "$($item.Path.Trim()) - MISMATCH or NEW FILE"
        }
    }
    $comparison | Set-Content -Path $ReportFile
    Write-Host "🔍 Hash integrity check completed. See: $ReportFile"
}

# Function to auto-flag suspicious entries (very basic example)
function Analyze-Timeline {
    param([string]$TimelineFile)
    $suspiciousTerms = @("mimikatz", "powershell.exe", "rundll32", "encodedcommand", "invoke", "Empire")
    Import-Csv -Path $TimelineFile | ForEach-Object {
        $entry = $_
        $flagged = $false
        foreach ($term in $suspiciousTerms) {
            if ($entry.Activity -match $term) {
                $entry | Add-Member -MemberType NoteProperty -Name "Flagged" -Value "⚠️ $term matched" -Force
                $flagged = $true
                break
            }
        }
        if (-not $flagged) {
            $entry | Add-Member -MemberType NoteProperty -Name "Flagged" -Value ""
        }
        $entry
    } | Export-Csv -Path $TimelineFile -NoTypeInformation
    Write-Host "🚩 Timeline analyzed and flags added where needed."
}

# Example: Dummy timeline creation
$dummyTimeline = @(
    @{ Timestamp = Get-Date; Activity = "powershell.exe -EncodedCommand xyz"; Source = "Process" },
    @{ Timestamp = Get-Date.AddMinutes(-15); Activity = "User logon"; Source = "Security" },
    @{ Timestamp = Get-Date.AddMinutes(-30); Activity = "File copied to USB"; Source = "Explorer" }
)
$dummyTimeline | Export-Csv -Path $timelineCsv -NoTypeInformation

# Analyze timeline
Analyze-Timeline -TimelineFile $timelineCsv

# Convert summary text to PDF (simple method)
$summaryText = @"
Forensic Summary Report
=======================
Date: $(Get-Date)

Collected Data:
- Timeline: $timelineCsv
- Hashes: $hashesFile
- Archive: $zipArchive

Suspicious Indicators:
- Auto-flagged terms found in timeline.

Please review all contents and validate integrity.
"@

$txtPath = "$outputDir\summary.txt"
$summaryText | Out-File -FilePath $txtPath

# Convert to PDF using Word COM automation (Windows only)
$word = New-Object -ComObject Word.Application
$doc = $word.Documents.Open($txtPath)
$doc.SaveAs([ref]$pdfReport, [ref]17)  # 17 = wdFormatPDF
$doc.Close()
$word.Quit()
Write-Host "📄 PDF report generated at: $pdfReport"

# Compress everything
Compress-Archive -Path "$outputDir\*" -DestinationPath $zipArchive -Force
Write-Host "📦 All data archived to: $zipArchive"

# Compute and verify hashes
Get-FileHashes -TargetDir $outputDir -OutputFile $hashesFile
if (Test-Path $baselineHashFile) {
    Compare-Hashes -BaselineFile $baselineHashFile -CurrentFile $hashesFile -ReportFile $integrityReport
} else {
    Write-Host "⚠️ No baseline hash file found at $baselineHashFile. Skipping integrity comparison."
}

Write-Host "✅ Final report process complete. Review your evidence."
```

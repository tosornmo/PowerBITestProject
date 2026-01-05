<#
Ingest and normalize raw job exports into the FactJobRun CSV used by Power BI.
This is a reference script for demos: it reads exports/ CSVs, maps process names to ProcessID using PowerBI/data/dim_process.csv, computes DurationSeconds and IsSLACompliant, and outputs PowerBI/data/fact_jobrun_normalized.csv
#>

$exportsDir = "exports"
$processLookup = Import-Csv -Path "PowerBI/data/dim_process.csv"
$outFile = "PowerBI/data/fact_jobrun_normalized.csv"

$rows = @()
Get-ChildItem -Path $exportsDir -Filter "*.csv" -File | ForEach-Object {
    $file = $_.FullName
    Write-Output "Reading $file"
    $data = Import-Csv -Path $file
    foreach ($r in $data) {
        # Attempt to map ProcessName -> ProcessID
        $mapping = $processLookup | Where-Object { $_.ProcessName -eq $r.ProcessName }
        $pid = if ($mapping) { [int]$mapping.ProcessID } else { $null }
        $sla = if ($mapping) { [int]$mapping.SLA_Seconds } else { 0 }

        $start = if ($r.StartTime) { [datetime]$r.StartTime } else { $null }
        $end = if ($r.EndTime) { [datetime]$r.EndTime } else { $null }
        $duration = if ($start -and $end) { ([datetime]$end - [datetime]$start).TotalSeconds } else { $null }
        $isSLA = if ($duration -and $sla -gt 0) { $duration -le $sla } else { $null }

        $rows += [pscustomobject]@{
            JobRunID = $r.JobRunID
            ProcessID = $pid
            SystemID = $r.SystemID
            ConsumerID = $r.ConsumerID
            StartTime = $r.StartTime
            EndTime = $r.EndTime
            DurationSeconds = $duration
            JobStatus = $r.JobStatus
            IsSLACompliant = $isSLA
            LoadDate = (Get-Date).ToString("o")
        }
    }
}

# write header + rows
New-Item -ItemType Directory -Force -Path (Split-Path $outFile) | Out-Null
$rows | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
Write-Output "Wrote normalized dataset to $outFile with $($rows.Count) rows"
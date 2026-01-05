<#
Template: Export job runs from UIPath Orchestrator as CSV.
Set environment variables or replace placeholders below before running.
Requires PowerShell Core (pwsh) and Invoke-RestMethod.
#>

param(
    [string]$BaseUrl = $env:UIPATH_BASEURL,
    [string]$TenantName = $env:UIPATH_TENANT,
    [string]$ApiKey = $env:UIPATH_APIKEY,
    [string]$From = "2026-01-01T00:00:00Z",
    [string]$To = (Get-Date).ToString("o"),
    [string]$OutputCsv = "exports/uipath_jobs.csv"
)

if (-not $BaseUrl) { Write-Error "Set UIPATH_BASEURL environment variable or provide -BaseUrl"; exit 1 }

# Example: call Orchestrator API to get jobs between dates.
# This is a template—adjust endpoints and auth per your Orchestrator version.
$uri = "${BaseUrl}/odata/Jobs?`$filter=StartTime ge ${From} and EndTime le ${To}&`$top=1000"

Write-Output "Querying UIPath Orchestrator: $uri"

# Example token-based call (replace with your auth flow)
$headers = @{
    "Authorization" = "Bearer $ApiKey"
}

try {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
} catch {
    Write-Error "Failed to call Orchestrator: $_"
    exit 1
}

# Transform results to normalized CSV
$rows = @()
foreach ($j in $resp.value) {
    $row = [pscustomobject]@{
        JobRunID = $j.Id
        ProcessName = $j.ReleaseName
        ProcessIdSource = $j.ReleaseId
        StartTime = $j.StartTime
        EndTime = $j.EndTime
        DurationSeconds = if ($j.EndTime -and $j.StartTime) { ([datetime]$j.EndTime - [datetime]$j.StartTime).TotalSeconds } else { $null }
        JobStatus = $j.State
    }
    $rows += $row
}

# Ensure output directory
New-Item -ItemType Directory -Force -Path (Split-Path $OutputCsv) | Out-Null
$rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Output "Exported $($rows.Count) rows to $OutputCsv"
<#
Template: Export Flow run history for Power Automate (Flow) as CSV.
Requires Azure AD app or service principal with appropriate permissions.
Replace placeholders and provide tenant/client/secret via env vars.
#>

param(
    [string]$TenantId = $env:AZURE_TENANT_ID,
    [string]$ClientId = $env:AZURE_CLIENT_ID,
    [string]$ClientSecret = $env:AZURE_CLIENT_SECRET,
    [string]$EnvironmentName = $env:PA_ENVIRONMENT,
    [string]$FlowName = "",
    [string]$From = "2026-01-01T00:00:00Z",
    [string]$To = (Get-Date).ToString("o"),
    [string]$OutputCsv = "exports/powerautomate_runs.csv"
)

if (-not $ClientId -or -not $ClientSecret) { Write-Error "Set AZURE_CLIENT_ID and AZURE_CLIENT_SECRET"; exit 1 }

# Acquire token (MSAL / client credentials)
$tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$body = @{ grant_type = "client_credentials"; client_id = $ClientId; client_secret = $ClientSecret; scope = "https://management.azure.com/.default" }
$tokenResp = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $body
$accessToken = $tokenResp.access_token

# Example management endpoint (adjust path per your tenant/flow)
$uri = "https://management.azure.com/providers/Microsoft.ProcessSimple/environments/$EnvironmentName/flows/$FlowName/runs?api-version=2016-11-01&`$filter=properties/startTime ge '$From' and properties/endTime le '$To'"

$headers = @{ Authorization = "Bearer $accessToken" }
$resp = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

$rows = @()
foreach ($r in $resp.value) {
    $p = $r.properties
    $rows += [pscustomobject]@{
        JobRunID = $r.name
        ProcessName = $FlowName
        StartTime = $p.startTime
        EndTime = $p.endTime
        DurationSeconds = if ($p.endTime -and $p.startTime) { ([datetime]$p.endTime - [datetime]$p.startTime).TotalSeconds } else { $null }
        JobStatus = $p.status
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path $OutputCsv) | Out-Null
$rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Output "Exported $($rows.Count) rows to $OutputCsv"
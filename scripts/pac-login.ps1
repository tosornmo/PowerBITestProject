<#
Power Platform CLI login helper (template).
Set the following environment variables in your CI or local shell before running:
- $env:PP_URL
- $env:PP_CLIENTID
- $env:PP_CLIENTSECRET
- $env:PP_TENANTID
#>

param()

if (-not $env:PP_URL) {
    Write-Error "PP_URL environment variable is not set."
    exit 1
}

Write-Output "Creating PAC authentication profile (interactive values must be set as env vars)."

# Example command (replace with the recommended auth method for your environment)
# pac auth create --url $env:PP_URL --name "github" --clientId $env:PP_CLIENTID --clientSecret $env:PP_CLIENTSECRET --tenant $env:PP_TENANTID

Write-Output "Template complete. Fill in the auth command appropriate for your setup."

# Prerequisites

Before using this repository, ensure you have the following installed and configured on your machine or CI environment:

- Power Platform CLI (`pac`) — used to manage and deploy solutions
- PowerShell 7 — commonly used for automation scripts
- Power BI Desktop — for authoring `.pbix` and `.pbit` files
- An Azure/Power Platform environment with sufficient permissions to import solutions and publish datasets
- GitHub or another remote Git provider for CI/CD workflows

Notes:
- Store service credentials and secrets in your CI provider's secret store (do NOT commit them).
- This repo contains helper scripts under `scripts/` with placeholders describing required secrets and usage.

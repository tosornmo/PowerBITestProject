# PowerBITestProject

A minimal scaffold for working with Microsoft Power Platform artifacts: Power BI, Power Automate, and Power Pages.

## Purpose
Store and manage solutions, flows, datasets, and deployment scripts for automated CI/CD and collaboration.

## Structure
- `PowerBI/` - place `.pbix` or `.pbit` files and dataset artifacts
- `PowerAutomate/` - exported flows (JSON/ZIP) and templates
- `PowerPages/` - site assets and solution artifacts
- `docs/` - notes on prerequisites and deployment steps
- `scripts/` - helper scripts (PowerShell/Bash) for pac CLI and deployment

## Getting started
1. Install Power Platform CLI (pac), PowerShell 7, and Power BI Desktop.
2. Place your exported artifacts into the appropriate folders.
3. Use the scripts in `scripts/` to authenticate and import solutions.

See `docs/PREREQUISITES.md` for more details.

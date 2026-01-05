# ETL & Data Sources — PowerBITestProject

Purpose: guidance and templates to extract run-history data from UIPath and Power Automate, normalize it into the `FactJobRun` schema, and perform incremental loads suitable for Power BI.

## Sources

- UIPath (Orchestrator API)
  - Endpoint (example): `https://{account}.uipath.com/odata/Jobs`
  - Important fields: `Id` (job id), `StartTime`, `EndTime`, `ReleaseId` (process id), `State` (status)
  - Auth: OAuth2 or account-specific keys (see UIPath Orchestrator docs)

- Power Automate (Flow run history via Management API / Graph)
  - Endpoint (example): `https://management.azure.com/providers/Microsoft.ProcessSimple/environments/{env}/flows/{flowName}/workflows/{workflowId}/runs?api-version=2016-11-01`
  - Important fields: `name` (run id), `startTime`, `endTime`, `status`
  - Auth: Azure AD App / service principal with appropriate permissions

## Field mapping → FactJobRun

- JobRunID: source job/run id
- ProcessID: map source process/flow id or name → `DimProcess.ProcessID`
- SystemID: set to UIPath=1, PowerAutomate=2 (or use `DimSystem` lookup)
- ConsumerID: derive from process metadata or mapping table
- StartTime/EndTime: convert to UTC
- DurationSeconds: computed (EndTime-StartTime) in seconds
- JobStatus: normalized to `Passed`, `Failed`, `Waiting`, `Running`
- IsSLACompliant: computed by comparing `DurationSeconds` to `DimProcess[SLA_Seconds]`

## Incremental loads

- Keep track of `LoadDate` or `Max(EndTime)` and fetch only runs where `EndTime > last_load_endtime`.
- If source supports incremental tokens (bookmarks), use them to avoid gaps.
- Schedule loads frequently enough to meet near-real-time needs (e.g., every 15 min, 1 hr, daily depending on scale).

## Normalizing statuses

- Map source job states to canonical statuses:
  - UIPath `Successful`/`SuccessfulWithWarnings` → `Passed`
  - UIPath `Faulted`/`Stopped`/`Failed` → `Failed`
  - Power Automate `Succeeded` → `Passed`; `Failed` → `Failed`
  - Running / Queued → `Running`/`Waiting`

## SLA handling

- Primary rule: `IsSLACompliant = DurationSeconds <= DimProcess[SLA_Seconds]`
- Optional: apply a tolerance window (e.g., 5% grace) or compute business-hours durations only

## PowerShell extraction template (UIPath & Power Automate)
- See `scripts/uipath-export.ps1` and `scripts/powerautomate-export.ps1` for templates.

## Ingestion / normalization example
- Use `scripts/ingest-merge.ps1` to normalize raw exports, compute DurationSeconds and IsSLACompliant, and append to a centralized `PowerBI/data/fact_jobrun_normalized.csv`.
- Alternatively, use Power Query in Power BI to pull source APIs directly and handle transformations there for smaller datasets.

## Power Query (M) snippet (compute duration & SLA)

```m
// convert iso timestamps to datetime and compute duration (sec)
let
    Source = Csv.Document(File.Contents("fact_jobrun_export.csv"),[Delimiter=",", Columns=10, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    AddStart = Table.TransformColumns(Promoted, {"StartTime", each DateTimeZone.FromText(_), type datetimezone}),
    AddEnd = Table.TransformColumns(AddStart, {"EndTime", each DateTimeZone.FromText(_), type datetimezone}),
    AddDuration = Table.AddColumn(AddEnd, "DurationSeconds", each Duration.TotalSeconds([EndTime] - [StartTime]), type number)
in
    AddDuration
```

## Notes & security
- Never commit credentials; use environment variables or secret stores in CI.
- For scale, push raw exports into blob storage and run batch ingestion into a database (Azure SQL, Dataverse, etc.).

---

If you want, I can add an Azure Data Factory/Logic App template or create a working PowerShell example that runs against a test UIPath/Power Automate tenant you provide credentials for.
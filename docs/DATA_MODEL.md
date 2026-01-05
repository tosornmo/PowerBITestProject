# Data Model — PowerBITestProject

Purpose: normalized schema to support monitoring UIPath and Power Automate processes, measure SLA compliance, and provide trend/health analysis.

## Core entities

- DimSystem
  - SystemID (int, PK)
  - SystemName (text) — e.g., `UIPath`, `PowerAutomate`

- DimConsumer
  - ConsumerID (int, PK)
  - ConsumerName (text) — e.g., `Finance`, `Team Digitalization`

- DimProcess
  - ProcessID (int, PK)
  - ProcessName (text)
  - ConsumerID (int, FK → DimConsumer)
  - SystemID (int, FK → DimSystem)
  - SLA_Seconds (int) — agreed SLA duration for the process
  - Owner (text)

- FactJobRun
  - JobRunID (int, PK)
  - ProcessID (int, FK → DimProcess)
  - SystemID (int, FK → DimSystem)
  - ConsumerID (int, FK → DimConsumer)
  - StartTime (datetime)
  - EndTime (datetime)
  - DurationSeconds (decimal)
  - JobStatus (text) — e.g., `Passed`, `Failed`, `Waiting`
  - IsSLACompliant (boolean)
  - LoadDate (datetime)

## Relationships
- DimProcess.ProcessID → FactJobRun.ProcessID
- DimConsumer.ConsumerID → DimProcess.ConsumerID and FactJobRun.ConsumerID
- DimSystem.SystemID → DimProcess.SystemID and FactJobRun.SystemID

## SLA logic
- IsSLACompliant = DurationSeconds <= DimProcess.SLA_Seconds
- Optionally add tolerance percentage or business-hours calculation

## Sample DAX measures (Power BI)
- Total Runs = COUNTROWS(FactJobRun)

- Successful Runs = CALCULATE( COUNTROWS(FactJobRun), FactJobRun[JobStatus] = "Passed" )

- Avg Duration (sec) = AVERAGE(FactJobRun[DurationSeconds])

- SLA Compliance % = DIVIDE( COUNTROWS( FILTER(FactJobRun, FactJobRun[DurationSeconds] <= RELATED(DimProcess[SLA_Seconds]) ) ), COUNTROWS(FactJobRun) )

- 7-day Avg Duration = AVERAGEX( DATESINPERIOD(DimDate[Date], LASTDATE(DimDate[Date]), -7, DAY), [Avg Duration (sec)] )

- SLA Breaches = COUNTROWS( FILTER(FactJobRun, FactJobRun[DurationSeconds] > RELATED(DimProcess[SLA_Seconds]) ) )

## Notes
- Keep `DimProcess` as source-of-truth for SLA values and mapping to consumers/systems.
- Ingest incremental job runs (by `LoadDate`) and compute `DurationSeconds` and `IsSLACompliant` during ETL.

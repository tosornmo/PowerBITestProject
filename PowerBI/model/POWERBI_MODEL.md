# Power BI Model — Setup & Measures

This document contains steps to create the Power BI model using the mock CSVs and the DAX measures to add after importing tables.

## Import steps
1. Open Power BI Desktop → Get Data → Blank Query → Advanced Editor.
2. Paste the queries from `PowerBI/model/queries.pq` (or use the `PowerBI/dataflow/power_platform_dataflow.m` if you have a hosted CSV URL).
3. Load the following tables: `FactJobRun`, `DimProcess`, `DimConsumer`, `DimSystem`, `DimDate`.

## Relationships
- `DimProcess[ProcessID]` 1→* `FactJobRun[ProcessID]`
- `DimConsumer[ConsumerID]` 1→* `DimProcess[ConsumerID]`
- `DimSystem[SystemID]` 1→* `FactJobRun[SystemID]`
- `DimDate[Date]` 1→* `FactJobRun[StartDate]` (create `StartDate` as Date only from `StartTime`)

## Recommended column preparations
- Add computed columns if needed:
  - `FactJobRun[StartDate] = Date.From([StartTime])`
  - `FactJobRun[EndDate] = Date.From([EndTime])`

## Core DAX measures
- Total Runs = COUNTROWS('FactJobRun')

- Successful Runs = CALCULATE( COUNTROWS('FactJobRun'), 'FactJobRun'[JobStatus] = "Passed" )

- Failed Runs = CALCULATE( COUNTROWS('FactJobRun'), 'FactJobRun'[JobStatus] = "Failed" )

- Avg Duration (sec) = AVERAGE('FactJobRun'[DurationSeconds])

- SLA Compliance % = DIVIDE(
    COUNTROWS( FILTER( 'FactJobRun', 'FactJobRun'[DurationSeconds] <= RELATED('DimProcess'[SLA_Seconds]) ) ),
    COUNTROWS('FactJobRun')
)

- 7-day Avg Duration = CALCULATE( [Avg Duration (sec)], DATESINPERIOD( 'DimDate'[Date], LASTDATE('DimDate'[Date]), -7, DAY ) )

- SLA Breaches = COUNTROWS( FILTER( 'FactJobRun', 'FactJobRun'[DurationSeconds] > RELATED('DimProcess'[SLA_Seconds]) ) )

## Health indicator (Improving/Degrading/Stable)
- Define Baseline window (e.g., prior 90 days) and Recent window (last 14 days).
- Compare SLA Compliance % and/or Avg Duration between windows and classify with thresholds.

## Exporting for Power Platform
- Once model is created, you can publish dataset to Power BI Service and then expose it to Power Platform (Power Apps / Power Automate) via Power BI connector or by creating a Dataverse table by exporting/transforming the dataset.


If you want, I can create a sample `.pbix` skeleton with visuals using Power BI Desktop (requires local editing) and provide it for you to open and tweak.
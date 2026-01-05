# Page Blueprints — Visual-by-visual instructions

## Page 1 — Overview (Executive)
- KPI Cards
  - Total Runs → `Total Runs` measure
  - SLA Compliance % → `SLA Compliance %` measure (format as percentage)
  - Failed Runs → `Failed Runs` measure
  - Avg Duration (sec) → `Avg Duration (sec)` measure
- Line chart: `DimDate[Date]` on x-axis, `SLA Compliance %` on y-axis (apply 7-day moving average measure)
- Line chart: `DimDate[Date]` on x-axis, `Avg Duration (sec)` on y-axis (7-day moving avg)
- Matrix: Rows = `DimConsumer[ConsumerName]`, Columns = `DimSystem[SystemName]`, Value = `SLA Compliance %` (use conditional formatting color scale)

## Page 2 — Consumer dashboard
- Slicer: `DimConsumer[ConsumerName]` (single select), `DimSystem[SystemName]` (multi), Date range relative
- Table: `DimProcess[ProcessName]`, `LastRunStatus` (calculated column using last run), `LastRunTime`, `AvgDuration`, `SLAFlag` (badge)
- Sparkline (small multiple) showing duration trend for processes

## Page 3 — Process detail
- Filter: Drill-through parameter `ProcessID`
- Chart: Scatter (x = `StartTime`, y = `DurationSeconds`) colored by `JobStatus` (Passed/Failed/Waiting)
- Table: Recent runs detail (JobRunID, StartTime, EndTime, Duration, Status, IsSLACompliant)

## Page 4 — SLA Violations
- Table: `ProcessName`, `SLABreachCount`, `FirstBreachDate`, `LastBreachDate`, `Owner`
- Bar chart: Top 10 processes by `SLABreachCount`

## Page 5 — Trends & Health
- Calculated measure per process: `Status = IF(DeltaSLA <= -2%, "Improving", IF(DeltaSLA >= 2%, "Degrading", "Stable"))`
- Visual: Donut chart showing counts of processes by `Status`
- Table: Trend history with baseline vs recent comparisons

---

## Calculated/Helper columns suggestions
- `LastRunTime` = CALCULATE(MAX(FactJobRun[StartTime]), FILTER(FactJobRun, FactJobRun[ProcessID]=EARLIER(DimProcess[ProcessID])))
- `LastRunStatus` = LOOKUPVALUE(FactJobRun[JobStatus], FactJobRun[JobRunID], LastRunID) // or use MAXX trick


If you want, I can create the precise DAX expressions for `LastRunTime`, `LastRunStatus`, `SLABreachCount`, and the `Status` classification for Trends.
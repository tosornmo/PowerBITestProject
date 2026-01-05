# Power BI Report Guide — PowerBITestProject

This guide helps you build the local Power BI report using the provided mock data and validated measures.

## Quick start (local)
1. Open Power BI Desktop.
2. Get Data → Blank Query → Advanced Editor → paste the queries from `PowerBI/model/queries.pq` (or use Get Data → CSV and point to `PowerBI/data/fact_jobrun_large.csv` and the dim CSVs).
3. Load tables: `FactJobRun`, `DimProcess`, `DimConsumer`, `DimSystem`, `DimDate`.
4. Create relationships:
   - `DimProcess[ProcessID]` 1→* `FactJobRun[ProcessID]`
   - `DimConsumer[ConsumerID]` 1→* `DimProcess[ConsumerID]`
   - `DimSystem[SystemID]` 1→* `FactJobRun[SystemID]`
   - `DimDate[Date]` 1→* `FactJobRun[StartDate]` (create `StartDate = Date.From([StartTime])`)
5. Add the DAX measures from `docs/POWERBI_MEASURES.md`.

---

## Page list (blueprint summary)
1. Overview (Executive) ✅
   - KPI cards: Total Runs, SLA Compliance %, Failed Runs, Avg Duration
   - Line charts: SLA Compliance % (time), Avg Duration (time) — show 7-day moving averages
   - Consumer x System heatmap or matrix for quick SLA view
   - Top N processes by SLA breaches

2. Consumer dashboard (filter by Consumer) ✅
   - Slicer: Consumer, System, Date range
   - Table: Process, LastRunStatus, LastRunTime, AvgDuration, SLAFlag
   - Sparkline: Avg Duration trend per process

3. Process detail (drill-through from table)
   - Run history: duration per run (bar or scatter), colored by status
   - Timeline of statuses (small multiples per process)
   - Table of recent runs with details and link to raw logs (if available)

4. SLA Violations & Alerts
   - Table of SLA breaches with counts, first/last breach time, owner contact
   - Bar chart: breaches by process

5. Trends & Health
   - Process-level trend classification (Improving/Stable/Degrading)
   - Visuals: % change in SLA compliance (recent vs baseline), Avg duration change

---

## Visual & UX details
- Slicers: Date range (relative), System, Consumer, Process
- Color coding: Green (within SLA), Orange (close to SLA), Red (breach)
- Tooltips: create a tooltip page showing last 5 runs and quick stats for hovering over a process
- Drill-through: enable Process detail via ProcessID
- Conditional formatting: use `SLACompliance%` and `AvgDuration` to color KPI cards and matrices

---

## Performance & best practices
- Use star schema and remove unused columns from `FactJobRun`.
- Disable query load on intermediate or staging queries.
- Use aggregation tables or incremental refresh if dataset becomes large (50k+ rows is fine for testing; for production use incremental refresh and premium or DW storage).
- Prefer computing `IsSLACompliant` and `DurationSeconds` in ETL (scripts provided) rather than heavy DAX.

---

## Export & publish (short)
- Save `.pbix` locally and publish to a Power BI workspace (app.powerbi.com).
- Configure dataset credentials and scheduled refresh (or use gateway if data isn't in cloud storage).
- Share report or pin visuals to dashboards; use Power Automate triggers or Power BI alerts for SLA breaches.


If you'd like, I can now create the step-by-step instructions for each page (fields, chart type, formatting), export sample .pbix layout notes, or build a minimal `.pbix` skeleton file (note: I can provide instructions to create the `.pbix` locally—creating binary PBIX here isn't possible).
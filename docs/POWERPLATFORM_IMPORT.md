# Importing the mock data into Power Platform / Dataflows

This page explains how to import the generated mock CSV into Power Platform Dataflows (Dataverse/Power Query) or directly into Power BI.

## Option A — Power Platform Dataflow (recommended for re-use)
1. Push `PowerBI/data/fact_jobrun_large.csv` and dimension CSVs to a location accessible from the Power Platform (GitHub raw URL, Azure Blob, or public file share). Example raw URL: `https://raw.githubusercontent.com/<your-repo>/<branch>/PowerBI/data/fact_jobrun_large.csv`.
2. In Power Platform (Power Apps) → Data → Dataflows, create a new dataflow and choose `Add new tables` → `Power Query` (Blank Query).
3. Open Advanced Editor and paste the Power Query script at `PowerBI/dataflow/power_platform_dataflow.m` (replace the source URL with your raw CSV URL if needed).
4. Map your columns and save the dataflow. Set refresh schedule as required.

## Option B — Dataverse import (small datasets)
- Use the Dataverse `Import Data` wizard to upload the CSV and map columns to a custom table. Ensure column names match Dataverse field names and use the `JobRunID` as a primary key for dedup/upsert.

## Option C — Power BI Desktop
- In Power BI Desktop, Get Data → CSV, and point to `PowerBI/data/fact_jobrun_large.csv` locally (or use the raw GitHub URL). Use the queries in `PowerBI/model/queries.pq` to build tables and DimDate.

## Notes
- For production, prefer regular ingestion into a database (Azure SQL, Data Lake) and create scheduled pipelines (ADF/Logic Apps) to keep data fresh.
- Keep credentials and endpoints in secure storage—not in repository.

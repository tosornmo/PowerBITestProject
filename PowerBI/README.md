# PowerBI folder

Add your Power BI Desktop files (`.pbix`) or Power BI Template files (`.pbit`) here.

Recommendations:
- Avoid committing large `.pbix` binaries if they contain sensitive data; keep them in an artifact store or use Git LFS.
- Keep sample datasets in `PowerBI/data/` or reference external data sources. Sample model CSVs are provided for quick testing:

  - `PowerBI/data/dim_system.csv`
  - `PowerBI/data/dim_consumer.csv`
  - `PowerBI/data/dim_process.csv`
  - `PowerBI/data/fact_jobrun.csv`
  - `PowerBI/data/fact_jobrun_sample.csv` (expanded mock dataset for demos)

You can also run the example extraction scripts under `scripts/` and then `scripts/ingest-merge.ps1` to create `PowerBI/data/fact_jobrun_normalized.csv` for direct import into Power BI.

- Use the Power BI service to publish reports and datasets; track deployment steps in `docs/`.

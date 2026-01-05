# PowerBI folder

Add your Power BI Desktop files (`.pbix`) or Power BI Template files (`.pbit`) here.

Recommendations:
- Avoid committing large `.pbix` binaries if they contain sensitive data; keep them in an artifact store or use Git LFS.
- Keep sample datasets in `PowerBI/data/` or reference external data sources.
- Use the Power BI service to publish reports and datasets; track deployment steps in `docs/`.

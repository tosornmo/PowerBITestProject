#!/usr/bin/env python3
"""
Validate Power BI measures against mock CSVs and produce KPI summaries for demo.
Produces outputs/kpi_overview.csv and outputs/process_trends.csv
"""
import pandas as pd
from datetime import datetime, timedelta
import os

BASE = os.path.dirname(os.path.dirname(__file__))
FACT_CSV = os.path.join(BASE, 'PowerBI', 'data', 'fact_jobrun_large.csv')
PROC_CSV = os.path.join(BASE, 'PowerBI', 'data', 'dim_process.csv')
CONSUMER_CSV = os.path.join(BASE, 'PowerBI', 'data', 'dim_consumer.csv')
SYSTEM_CSV = os.path.join(BASE, 'PowerBI', 'data', 'dim_system.csv')
OUT_DIR = os.path.join(BASE, 'outputs')

os.makedirs(OUT_DIR, exist_ok=True)

print('Loading data...')
fact = pd.read_csv(FACT_CSV, parse_dates=['StartTime','EndTime','LoadDate'])
proc = pd.read_csv(PROC_CSV)
cons = pd.read_csv(CONSUMER_CSV)
sys = pd.read_csv(SYSTEM_CSV)

# Merge SLA and other dims into fact
df = fact.merge(proc[['ProcessID','ProcessName','SLA_Seconds','ConsumerID','SystemID']], on='ProcessID', how='left')
# Normalize column names in case of suffixes from merges (e.g., ConsumerID_x)
for col in ['ConsumerID','SystemID']:
    if col not in df.columns:
        for candidate in df.columns:
            if candidate.lower().startswith(col.lower()):
                df[col] = df[candidate]
                break
# ensure types
df['DurationSeconds'] = pd.to_numeric(df['DurationSeconds'], errors='coerce')

# Overall KPIs
total_runs = len(df)
successful_runs = len(df[df['JobStatus']=='Passed'])
failed_runs = len(df[df['JobStatus']=='Failed'])
avg_duration = df['DurationSeconds'].mean()

# SLA compliance: compare DurationSeconds to SLA_Seconds (where SLA > 0)
df['IsSLA'] = df['DurationSeconds'] <= df['SLA_Seconds']
sla_compliance_pct = df[df['SLA_Seconds']>0]['IsSLA'].mean() * 100
sla_breaches = len(df[(df['SLA_Seconds']>0) & (~df['IsSLA'])])

overview = pd.DataFrame([{ 
    'TotalRuns': total_runs,
    'SuccessfulRuns': successful_runs,
    'FailedRuns': failed_runs,
    'AvgDurationSec': round(avg_duration,2),
    'SLACompliancePct': round(sla_compliance_pct,2),
    'SLABreaches': sla_breaches
}])
overview.to_csv(os.path.join(OUT_DIR,'kpi_overview.csv'), index=False)
print('Wrote outputs/kpi_overview.csv')

# KPIs by Consumer and System
by_consumer = df.groupby('ConsumerID').agg(
    TotalRuns=('JobRunID','count'),
    Successful=('JobStatus', lambda x: (x=='Passed').sum()),
    Failed=('JobStatus', lambda x: (x=='Failed').sum()),
    AvgDuration=('DurationSeconds','mean'),
    SLACompliancePct=('IsSLA', lambda x: x.mean()*100)
).reset_index().merge(cons, on='ConsumerID')
by_consumer.to_csv(os.path.join(OUT_DIR,'kpi_by_consumer.csv'), index=False)
print('Wrote outputs/kpi_by_consumer.csv')

# KPIs by Process
by_process = df.groupby(['ProcessID','ProcessName']).agg(
    TotalRuns=('JobRunID','count'),
    Successful=('JobStatus', lambda x: (x=='Passed').sum()),
    Failed=('JobStatus', lambda x: (x=='Failed').sum()),
    AvgDuration=('DurationSeconds','mean'),
    SLACompliancePct=('IsSLA', lambda x: x.mean()*100)
).reset_index()
by_process.to_csv(os.path.join(OUT_DIR,'kpi_by_process.csv'), index=False)
print('Wrote outputs/kpi_by_process.csv')

# Trend analysis: for each process, compute baseline (90 days) and recent (14 days)
# Ensure we have a date column
df['StartDate'] = df['StartTime'].dt.date

latest_date = df['StartDate'].max()
baseline_start = latest_date - timedelta(days=90)
recent_start = latest_date - timedelta(days=14)

trend_rows = []
for pid, chunk in df.groupby('ProcessID'):
    baseline = chunk[(chunk['StartDate'] >= baseline_start) & (chunk['StartDate'] < recent_start)]
    recent = chunk[chunk['StartDate'] >= recent_start]
    baseline_sla = baseline['IsSLA'].mean() if not baseline.empty else None
    recent_sla = recent['IsSLA'].mean() if not recent.empty else None
    baseline_avgdur = baseline['DurationSeconds'].mean() if not baseline.empty else None
    recent_avgdur = recent['DurationSeconds'].mean() if not recent.empty else None

    # classify
    status = 'Insufficient Data'
    if baseline_sla is None or recent_sla is None:
        status = 'Insufficient Data'
    else:
        # compare SLA compliance
        delta_pct = (recent_sla - baseline_sla) * 100
        if delta_pct <= -2:
            status = 'Improving'
        elif delta_pct >= 2:
            status = 'Degrading'
        else:
            status = 'Stable'

    trend_rows.append({
        'ProcessID': pid,
        'ProcessName': chunk['ProcessName'].iloc[0],
        'BaselineSLA%': round(baseline_sla*100,2) if baseline_sla is not None else None,
        'RecentSLA%': round(recent_sla*100,2) if recent_sla is not None else None,
        'BaselineAvgDur': round(baseline_avgdur,2) if baseline_avgdur is not None else None,
        'RecentAvgDur': round(recent_avgdur,2) if recent_avgdur is not None else None,
        'Status': status
    })

pd.DataFrame(trend_rows).to_csv(os.path.join(OUT_DIR,'process_trends.csv'), index=False)
print('Wrote outputs/process_trends.csv')

print('Validation complete.')

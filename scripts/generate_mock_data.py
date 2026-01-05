#!/usr/bin/env python3
"""
Generate large synthetic FactJobRun CSV for Power BI demos.
Usage: python3 scripts/generate_mock_data.py --rows 50000 --out PowerBI/data/fact_jobrun_large.csv
"""
import csv
import random
import argparse
from datetime import datetime, timedelta
import os

import math

# read processes
def read_processes(path):
    procs = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            procs.append({
                'ProcessID': int(r['ProcessID']),
                'ProcessName': r['ProcessName'],
                'ConsumerID': int(r['ConsumerID']),
                'SystemID': int(r['SystemID']),
                'SLA_Seconds': int(r['SLA_Seconds']) if r['SLA_Seconds'] else 0
            })
    return procs


def generate_rows(procs, start_date, end_date, target_rows):
    delta = end_date - start_date
    days = delta.days + 1
    rows = []
    jobid = 100000

    # assign behavior per process: stable/improving/degrading
    behaviors = {}
    for p in procs:
        behaviors[p['ProcessID']] = random.choices(['stable','degrading','improving'], weights=[0.7,0.2,0.1])[0]

    # base rate per process (runs per day average) - increase to ensure large output
    base_rates = {p['ProcessID']: random.uniform(1.0, 6.0) for p in procs}

    for day_offset in range(days):
        cur_date = start_date + timedelta(days=day_offset)
        days_from_start = day_offset
        for p in procs:
            pid = p['ProcessID']
            # number of runs today: sample from Poisson-like distribution using expovariate fallback
            lam = base_rates[pid]
            if hasattr(random, 'poisson'):
                runs = max(0, int(random.poisson(lam)))
            else:
                # approximate Poisson by drawing from a Poisson-like process
                mean = lam
                # use a simple discretized approach: draw from normal around mean or small integer
                runs = max(0, int(random.gauss(mean, max(1.0, mean * 0.5))))

            if runs == 0:
                runs = random.choices([0,1,2,3], weights=[0.2,0.4,0.3,0.1])[0]

            for r in range(runs):
                jobid += 1
                # pick start time during the day
                start_sec = random.randint(0, 86399)
                start_time = datetime.combine(cur_date, datetime.min.time()) + timedelta(seconds=start_sec)

                # compute duration influenced by SLA and behavior
                sla = max(60, p['SLA_Seconds'])
                behavior = behaviors[pid]
                # baseline mean duration is around sla * factor
                if behavior == 'stable':
                    mean_factor = random.uniform(0.6, 1.1)
                elif behavior == 'degrading':
                    # increasing with time: mean factor grows slowly
                    mean_factor = 1.0 + (days_from_start / max(1, (days/5))) * random.uniform(0.01,0.05)
                else: # improving
                    mean_factor = 1.0 - (days_from_start / max(1, (days/5))) * random.uniform(0.01,0.05)
                # cap mean_factor to reasonable range
                mean_factor = max(0.2, min(mean_factor, 5.0))
                mean_duration = sla * mean_factor
                # sample actual duration from log-normal to avoid negatives and skew
                sigma = 0.6
                mu = math.log(max(1, mean_duration)) - 0.5 * sigma * sigma
                duration = int(random.lognormvariate(mu, sigma))
                if duration < 1:
                    duration = 1

                end_time = start_time + timedelta(seconds=duration)

                # status: failed probability increases if duration >> sla
                fail_prob = 0.02
                if duration > sla:
                    # base added probability of failure when exceeding SLA
                    fail_prob += min(0.5, (duration - sla) / sla * 0.5)
                # small base failure
                status = 'Passed' if random.random() > fail_prob else 'Failed'
                # introduce a few 'Waiting' or 'Running' incomplete statuses randomly (small percent)
                if random.random() < 0.01:
                    status = random.choice(['Waiting','Running'])

                rows.append({
                    'JobRunID': jobid,
                    'ProcessID': pid,
                    'SystemID': p['SystemID'],
                    'ConsumerID': p['ConsumerID'],
                    'StartTime': start_time.isoformat() + 'Z',
                    'EndTime': end_time.isoformat() + 'Z',
                    'DurationSeconds': duration,
                    'JobStatus': status,
                    'IsSLACompliant': 'TRUE' if duration <= p['SLA_Seconds'] else 'FALSE',
                    'LoadDate': datetime.utcnow().isoformat() + 'Z'
                })
                if len(rows) >= target_rows:
                    return rows

    # if not enough rows generated in single pass, add random extra runs across processes/dates until target met
    while len(rows) < target_rows:
        p = random.choice(procs)
        pid = p['ProcessID']
        random_day_offset = random.randint(0, days-1)
        cur_date = start_date + timedelta(days=random_day_offset)
        start_sec = random.randint(0, 86399)
        start_time = datetime.combine(cur_date, datetime.min.time()) + timedelta(seconds=start_sec)
        # behavior-influenced duration
        sla = max(60, p['SLA_Seconds'])
        behavior = behaviors[pid]
        if behavior == 'stable':
            mean_factor = random.uniform(0.6, 1.1)
        elif behavior == 'degrading':
            mean_factor = 1.0 + (random_day_offset / max(1, (days/5))) * random.uniform(0.01,0.05)
        else:
            mean_factor = 1.0 - (random_day_offset / max(1, (days/5))) * random.uniform(0.01,0.05)
        mean_factor = max(0.2, min(mean_factor, 5.0))
        mean_duration = sla * mean_factor
        sigma = 0.6
        mu = math.log(max(1, mean_duration)) - 0.5 * sigma * sigma
        duration = int(random.lognormvariate(mu, sigma))
        if duration < 1:
            duration = 1
        end_time = start_time + timedelta(seconds=duration)
        fail_prob = 0.02
        if duration > sla:
            fail_prob += min(0.5, (duration - sla) / sla * 0.5)
        status = 'Passed' if random.random() > fail_prob else 'Failed'
        if random.random() < 0.01:
            status = random.choice(['Waiting','Running'])
        jobid += 1
        rows.append({
            'JobRunID': jobid,
            'ProcessID': pid,
            'SystemID': p['SystemID'],
            'ConsumerID': p['ConsumerID'],
            'StartTime': start_time.isoformat() + 'Z',
            'EndTime': end_time.isoformat() + 'Z',
            'DurationSeconds': duration,
            'JobStatus': status,
            'IsSLACompliant': 'TRUE' if duration <= p['SLA_Seconds'] else 'FALSE',
            'LoadDate': datetime.utcnow().isoformat() + 'Z'
        })
    return rows


def write_csv(rows, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['JobRunID','ProcessID','SystemID','ConsumerID','StartTime','EndTime','DurationSeconds','JobStatus','IsSLACompliant','LoadDate'])
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rows', type=int, default=50000)
    parser.add_argument('--out', type=str, default='PowerBI/data/fact_jobrun_large.csv')
    parser.add_argument('--from', dest='from_date', type=str, default='2025-07-01')
    parser.add_argument('--to', dest='to_date', type=str, default='2026-01-05')
    args = parser.parse_args()

    procs = read_processes('PowerBI/data/dim_process.csv')
    start_date = datetime.fromisoformat(args.from_date)
    end_date = datetime.fromisoformat(args.to_date)
    rows = generate_rows(procs, start_date, end_date, args.rows)
    write_csv(rows, args.out)
    print(f"Wrote {len(rows)} rows to {args.out}")

if __name__ == '__main__':
    main()

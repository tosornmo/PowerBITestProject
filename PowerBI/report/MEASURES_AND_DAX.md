# DAX Measures & Helper Expressions

Core measures (re-iterated for convenience):

Total Runs =
COUNTROWS('FactJobRun')

Successful Runs =
CALCULATE( COUNTROWS('FactJobRun'), 'FactJobRun'[JobStatus] = "Passed" )

Failed Runs =
CALCULATE( COUNTROWS('FactJobRun'), 'FactJobRun'[JobStatus] = "Failed" )

Avg Duration (sec) =
AVERAGE('FactJobRun'[DurationSeconds])

SLA Compliance % =
DIVIDE(
    COUNTROWS( FILTER( 'FactJobRun', 'FactJobRun'[DurationSeconds] <= RELATED('DimProcess'[SLA_Seconds]) ) ),
    COUNTROWS('FactJobRun')
)

7-day Avg Duration =
CALCULATE( [Avg Duration (sec)], DATESINPERIOD( 'DimDate'[Date], LASTDATE('DimDate'[Date]), -7, DAY ) )

SLA Breaches =
COUNTROWS( FILTER( 'FactJobRun', 'FactJobRun'[DurationSeconds] > RELATED('DimProcess'[SLA_Seconds]) ) )

-- SLA breach count per process
SLABreachCount =
CALCULATE( [SLA Breaches], ALLEXCEPT(DimProcess, DimProcess[ProcessID]) )

-- Last run for process (time)
LastRunTime =
CALCULATE( MAX('FactJobRun'[StartTime]), FILTER('FactJobRun', 'FactJobRun'[ProcessID] = SELECTEDVALUE(DimProcess[ProcessID])) )

-- Status classification (Improving/Stable/Degrading) example (assumes measures RecentSLA and BaselineSLA)
Status =
VAR delta = [RecentSLA] - [BaselineSLA]
RETURN
SWITCH(TRUE(),
    ISBLANK(delta), "Insufficient Data",
    delta <= -0.02, "Improving",
    delta >= 0.02, "Degrading",
    "Stable"
)

If you want, I can add full DAX for `RecentSLA`, `BaselineSLA` (using date windows), and computed columns like `LastRunStatus`.
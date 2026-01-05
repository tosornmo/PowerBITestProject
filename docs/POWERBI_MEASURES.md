# Power BI DAX Measures — Monitoring

Below are core DAX measures to implement in the Power BI model:

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

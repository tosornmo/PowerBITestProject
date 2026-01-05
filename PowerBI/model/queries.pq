// Power Query script to import local CSVs into Power BI Desktop
let
    FactPath = "PowerBI/data/fact_jobrun_large.csv",
    FactCSV = Csv.Document(File.Contents(FactPath),[Delimiter=",", Columns=10, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    FactPromoted = Table.PromoteHeaders(FactCSV, [PromoteAllScalars=true]),
    FactTypes = Table.TransformColumnTypes(FactPromoted,{{"JobRunID", Int64.Type},{"ProcessID", Int64.Type},{"SystemID", Int64.Type},{"ConsumerID", Int64.Type},{"StartTime", type datetime},{"EndTime", type datetime},{"DurationSeconds", Int64.Type},{"JobStatus", type text},{"IsSLACompliant", type logical},{"LoadDate", type datetime}}),

    DimProcess = Csv.Document(File.Contents("PowerBI/data/dim_process.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]) |> Table.PromoteHeaders(_, [PromoteAllScalars=true]) |> Table.TransformColumnTypes(_,{{"ProcessID", Int64.Type},{"ProcessName", type text},{"ConsumerID", Int64.Type},{"SystemID", Int64.Type},{"SLA_Seconds", Int64.Type}}),
    DimConsumer = Csv.Document(File.Contents("PowerBI/data/dim_consumer.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]) |> Table.PromoteHeaders(_, [PromoteAllScalars=true]) |> Table.TransformColumnTypes(_,{{"ConsumerID", Int64.Type},{"ConsumerName", type text}}),
    DimSystem = Csv.Document(File.Contents("PowerBI/data/dim_system.csv"),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]) |> Table.PromoteHeaders(_, [PromoteAllScalars=true]) |> Table.TransformColumnTypes(_,{{"SystemID", Int64.Type},{"SystemName", type text}}),

    // Create DimDate from StartTime
    Dates = Table.TransformColumns(FactTypes, {"StartTime", each DateTime.Date(_), type date}),
    DimDate = Table.Distinct(Table.SelectColumns(Dates,{"StartTime"})),
    DimDateRenamed = Table.RenameColumns(DimDate,{{"StartTime","Date"}}),
    DimDateComplete = Table.AddColumn(DimDateRenamed, "Year", each Date.Year([Date]), Int64.Type)
in
    [FactJobRun = FactTypes, DimProcess = DimProcess, DimConsumer = DimConsumer, DimSystem = DimSystem, DimDate = DimDateComplete]
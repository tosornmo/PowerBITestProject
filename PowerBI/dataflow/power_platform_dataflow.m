// Power Query template to import fact and dimensions from CSV URLs
let
    // Replace the URLs below with the CSV file locations accessible to Power Platform (GitHub raw, Azure Blob etc.)
    FactUrl = "https://raw.githubusercontent.com/<your-repo>/<branch>/PowerBI/data/fact_jobrun_large.csv",
    DimProcessUrl = "https://raw.githubusercontent.com/<your-repo>/<branch>/PowerBI/data/dim_process.csv",
    DimConsumerUrl = "https://raw.githubusercontent.com/<your-repo>/<branch>/PowerBI/data/dim_consumer.csv",
    DimSystemUrl = "https://raw.githubusercontent.com/<your-repo>/<branch>/PowerBI/data/dim_system.csv",

    // Load Fact
    FactCSV = Csv.Document(Web.Contents(FactUrl),[Delimiter=",", Columns=10, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    FactPromoted = Table.PromoteHeaders(FactCSV, [PromoteAllScalars=true]),
    FactTypes = Table.TransformColumnTypes(FactPromoted,{{"JobRunID", Int64.Type},{"ProcessID", Int64.Type},{"SystemID", Int64.Type},{"ConsumerID", Int64.Type},{"StartTime", type datetime},{"EndTime", type datetime},{"DurationSeconds", Int64.Type},{"JobStatus", type text},{"IsSLACompliant", type logical},{"LoadDate", type datetime}}),

    // Load Dimensions
    PCSV = Csv.Document(Web.Contents(DimProcessUrl),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Process = Table.PromoteHeaders(PCSV, [PromoteAllScalars=true]),
    ProcessTypes = Table.TransformColumnTypes(Process,{{"ProcessID", Int64.Type},{"ProcessName", type text},{"ConsumerID", Int64.Type},{"SystemID", Int64.Type},{"SLA_Seconds", Int64.Type}}),

    CCSV = Csv.Document(Web.Contents(DimConsumerUrl),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Consumer = Table.PromoteHeaders(CCSV, [PromoteAllScalars=true]),
    ConsumerTypes = Table.TransformColumnTypes(Consumer,{{"ConsumerID", Int64.Type},{"ConsumerName", type text}}),

    SCSV = Csv.Document(Web.Contents(DimSystemUrl),[Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),
    System = Table.PromoteHeaders(SCSV, [PromoteAllScalars=true]),
    SystemTypes = Table.TransformColumnTypes(System,{{"SystemID", Int64.Type},{"SystemName", type text}}),

    // Create DimDate from Fact StartTime
    Dates = Table.TransformColumns(FactTypes, {"StartTime", each DateTime.Date(_), type date}),
    DimDate = Table.Distinct(Table.SelectColumns(Dates,{"StartTime"})),
    DimDateRenamed = Table.RenameColumns(DimDate,{{"StartTime","Date"}}),
    DimDateExpanded = Table.TransformColumns(DimDateRenamed, {"Date", each _, type date}),
    DimDateComplete = Table.AddColumn(DimDateExpanded, "Year", each Date.Year([Date]), Int64.Type),
    DimDateComplete2 = Table.AddColumn(DimDateComplete, "Month", each Date.Month([Date]), Int64.Type),
    DimDateComplete3 = Table.AddColumn(DimDateComplete2, "Day", each Date.Day([Date]), Int64.Type)
in
    [Fact = FactTypes, DimProcess = ProcessTypes, DimConsumer = ConsumerTypes, DimSystem = SystemTypes, DimDate = DimDateComplete3]
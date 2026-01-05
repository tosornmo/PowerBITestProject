-- Schema for PowerBITestProject monitoring model

CREATE TABLE DimSystem (
  SystemID INTEGER PRIMARY KEY,
  SystemName TEXT NOT NULL
);

CREATE TABLE DimConsumer (
  ConsumerID INTEGER PRIMARY KEY,
  ConsumerName TEXT NOT NULL
);

CREATE TABLE DimProcess (
  ProcessID INTEGER PRIMARY KEY,
  ProcessName TEXT NOT NULL,
  ConsumerID INTEGER NOT NULL REFERENCES DimConsumer(ConsumerID),
  SystemID INTEGER NOT NULL REFERENCES DimSystem(SystemID),
  SLA_Seconds INTEGER DEFAULT 0,
  Owner TEXT
);

CREATE TABLE FactJobRun (
  JobRunID INTEGER PRIMARY KEY,
  ProcessID INTEGER NOT NULL REFERENCES DimProcess(ProcessID),
  SystemID INTEGER NOT NULL REFERENCES DimSystem(SystemID),
  ConsumerID INTEGER NOT NULL REFERENCES DimConsumer(ConsumerID),
  StartTime DATETIME,
  EndTime DATETIME,
  DurationSeconds REAL,
  JobStatus TEXT,
  IsSLACompliant BOOLEAN,
  LoadDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_factjobrun_process ON FactJobRun(ProcessID);
CREATE INDEX idx_factjobrun_starttime ON FactJobRun(StartTime);
CREATE INDEX idx_factjobrun_status ON FactJobRun(JobStatus);

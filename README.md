# CDC DEMO:
The purpose of this demo is to capture changes in source database (MS SQL) and stream the CDC data to target destination (Kinesis a.k.a KDS) using AWS DMS. KDS can further deliver the data to targets like S3 or custom end point using Kinesis Data Firehose. In the demo, we have selected S3. Note that DMS could have directly sent to S3 as well. 

To read ongoing changes from the source database, AWS DMS uses engine-specific API actions to read changes from the source engine's transaction logs

You can use AWS DMS in your data integration pipelines to replicate data in near-real time directly into Kinesis Data Streams. With this approach, you can build a decoupled and eventually consistent view of your database without having to build applications on top of a database, which is expensive.

![image](https://user-images.githubusercontent.com/11863956/229216015-15a3db8a-99f2-44a3-9c79-94058dd78f3e.png)

# STEPS:
1.Ensure following variables are updated in variables.tf:
accessKey, secretKey, password (DB Password)

2.Create  Database- Login to sql server and create DB

*USE master;
CREATE DATABASE cdc_demo; 
GO 
USE cdc_demo; 
CREATE TABLE Carriers ( [Id]  INT NOT NULL, 
    [Name] NVARCHAR (MAX), 
    [Type] NVARCHAR (MAX), 
    CONSTRAINT [PK_Carriers] PRIMARY KEY CLUSTERED ([Id] ASC) 
);*

3.Enable CDC for DB

*exec msdb.dbo.rds_cdc_enable_db 'cdc_demo'*

4.Enable CDC on tables

*exec sys.sp_cdc_enable_table @source_schema = N'dbo' ,  
@source_name = N'Carriers' ,  
@role_name = N'admin'*

5.Update polling (Required to be over 300sec for CDC to work)

*use cdc_demo
EXEC sys.sp_cdc_change_job @job_type = 'capture' ,@pollinginterval = 360*

6.Insert sample records

*INSERT INTO Carriers VALUES('1','Branch','Auto')
INSERT INTO Carriers VALUES('2','Safeco','Travel')*

#TO DO:
S3 creation and DB scripts are manually performed. Future versions will have these automated in tf scripts.

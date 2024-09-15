/*********************************************************************************************************************************
*
* File Name     : Script.SetupCDC.sql
*               
* Description   : Setup Change Data Capture (CDC) for tables tbl_Parts, tbl_PartsLoc, and tbl_Localisation
*
* Notes         : This script sets up a CDC job for table tbl_Parts, tbl_PartsLoc, and tbl_Localisation 
*                 for the fields indicated.
*
*                 Before CDC can work the database must be enabled for change tracking.
*
*                 The tables being tracked must also be enabled for CDC. 
*
*                 In Sql Server CDC works by creating a table that stores changes. The 
*                 stored procedure sys.sp_cdc_enable_table creates this table, defines which 
*                 fields will be tracked, and enables the tracking for the source table. 
*
*                 The CDC table is created as a system table with a default name of cdc.dbo_<tracked table name>_CT.
*
*                 In our case the Change Data Capture tracking tables are named:
*                     cdc.dbo_tbl_Parts_CT 
*                     cdc.dbo_tbl_PartsLoc_CT 
*                     cdc.dbo_Localisation_CT
*
*                 Once CDC is enabled for the datbase and the tables the tracking CDC tables 
*                 can be queried to see what changes have been made.
*
*                 The CDC table's operation fields tracks the type of chnage:
*                    - <cdc table>.__$operation = 1 DELETE one record showing all field vales tracked before the delete.
*                    - <cdc table>.__$operation = 2 INSERT one record showing all field vales tracked after the insert.
*                    - <cdc table>.__$operation = 3 UPDATE showing the before update values of the tracked fields.
*                    - <cdc table>.__$operation = 4 UPDATE showing the after update values of the tracked fields.
*
*                 Note that you can determine exactly which field was updated in each trasaction by looking at 
*                 the <cdc table>.__$update_mask field which has a bit set to 1 for each field that has been changed. 
*                 In this implementation I'm not bothering with the identifying the changed fields. 
* 
*                 See query GetPartsCDC.sql for how the CDC table is queried to see a list of which tbl_Parts records 
*                 have been updated.
*
* Other Notes   : Here are some helpful CDC related stored procedures and queries:
*
*                    EXEC sp_cdc_disable_table                                      -- Stop tracking for tbl_Parts 
*                        @source_schema        = N'dbo',
*                        @source_name          = N'tbl_Parts',
*                        @capture_instance     = N'dbo_tbl_Parts';                  -- The default instace name is "dbo_<table being tracted>"
* 
*                    EXEC sp_cdc_disable_db;                                        -- Disable tracking for the entire database.
*
*                    EXEC sys.sp_cdc_start_job                                      -- Start the tracking agent. 
*                    EXEC sys.sp_cdc_stop_job                                       -- Stop the tracking agent.  
*                    EXEC sys.sp_cdc_help_jobs                                      -- List tracking jobs.  
*                    EXEC sys.sp_cdc_help_change_data_capture                       -- List capture instances.
* 
*                    SELECT name, is_cdc_enabled FROM sys.databases;                -- See list of database that have CDC enabled.
*                    
*                    SELECT name, is_tracked_by_cdc                                 -- See list of tables that have CDC enabled.
*                    from sys.tables
*                    order by name;
*                    
*                    SELECT *                                                       -- See if there are any CDC related errors. 
*                    from sys.dm_cdc_errors 
*
*                    SELECT ([retention])/((60*24)) AS Default_Retention_days ,*    -- See the rention duration.
*                    FROM msdb.dbo.cdc_jobs
*
*                    exec sp_cdc_change_job @job_type='cleanup', @retention=10080   -- Change the retention time of tracked 
*                                                                                      changes (in minutes 10080=7days).
*
* Modifications : 2024/09/07 JPE Created
*
*************************************************************************************************************************************/
 
/* Enable tracking for the database */
EXEC sp_changedbowner 'sa';
EXEC sp_cdc_enable_db;

/* set up a tracking incident for tbl_parts for the captured columns listed */
EXEC sp_cdc_enable_table
    @source_schema        = 'dbo',
    @source_name          = 'tbl_Parts',
    @role_name            = 'public',
    @captured_column_list = N'id, pieceNo, description, descriptionService, unitstock, cost, msrp, originCountry, codeHS, rev, qtyMin, partstatus_id';

/* set up a tracking incident for tbl_PartsLoc for the captured columns listed */
EXEC sp_cdc_enable_table
    @source_schema        = 'dbo',
    @source_name          = 'tbl_PartsLoc',
    @role_name            = 'public',
    @captured_column_list = N'id, part_id, loc_id';

/* set up a tracking incident for tbl_Localisation for the captured columns listed */
EXEC sp_cdc_enable_table
    @source_schema        = 'dbo',
    @source_name          = 'tbl_Localisation',
    @role_name            = 'public',
    @captured_column_list = N'id, station, classeur';

/* set the retention time to (10080/60)/24 = 7 days */
EXEC sp_cdc_change_job @job_type='cleanup', @retention=10080;

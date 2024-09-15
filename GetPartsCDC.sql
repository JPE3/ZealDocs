/******************************************************************************************************
* File Name     : GetPartsCDC.sql
*              
* Description   : Use SQL Server's Change Data Capture (CDC) to track which fields in the parts and 
*                 bin location tables. 
*
* Notes         : See Script.SetupCDC.sql and the Zeal API specs for an introduction to how CDC works 
*                 and how it has been for Zeal. 
*                 
*                 The common table expression select statement in this file returns a list of all
*                 tbl_Parts' part ids where there has been a change in specific fields in the parts
*                 table (tbl_Parts), the location that the part is stored at (tbl_PartsLoc), or the 
*                 labe of the bin location (tbl_Localisation).
*
*                 This select statement queries the CDC tables for the source of where the change 
*                 occurred (Parts, Part Locations, or Bin Labels table), what type of change 
*                 it was (UPDATE, INSERT, or DELETE), and when the change occured. 
*
*                 It works by selecting the records for each CDC tracking table for each table being 
*                 tracked (dbo_tbl_Parts_CT, dbo_tbl_PartsLoc_CT, and dbo_Localisation_CT). Each of 
*                 those are one instance of a change. 
*
*                 The query then merges (UNION) all of those records together, selecting the most recent 
*                 update record. 
*
*                 The query returns a list of which parts have changed since after a timestamp. The list 
*                 is sorted by part number and then that change timestamp. 
*                 
*                 There may be duplicate part numbers in the list because:
*                 
*                       1. A part could be inserted, then updated, and then, maybe deleted. The list 
*                          shows each type of change as a separate record. 
*                 
*                       2. The part may have it's main field values changed, then it's moved to a 
*                          different bin location, and then the bin location label is changed. The 
*                          list shows the source of each change as a separate record.         
*              
*                 The CDC system has been configured to retain changes data for seven days. 
*
* Modifications : 2024/09/08 JPE Created
*
*******************************************************************************************************/

with 

/* Subquery showing which records of the tbl_Localisation (bin labels) table have changed and when. 
   Joining the tbl_PartsLoc (a part's location) is required to determine which part needs to have it's 
   bin label changed.
   System table cdc.lsn_time_mapping stores the time stamp for each change tracked */
   tCDCBin as (
      select 
        'tbl_Localisation'                                 as cdc_Source
        ,tPARTS_LOC.part_id                                as cdc_PartId
        ,iif(tCDC_TABLE.__$operation = 1, 'DELETE',        
         iif(tCDC_TABLE.__$operation = 2, 'INSERT',        
         iif(tCDC_TABLE.__$operation = 3, 'UPDATE before', 
         iif(tCDC_TABLE.__$operation = 4, 'UPDATE',        
             'Unknown'))))                                 as cdc_ChangeType
        ,tCDC_TIMING.tran_end_time                         as cdc_TimeStamp
      from 
         cdc.dbo_tbl_Localisation_CT tCDC_TABLE
         join cdc.lsn_time_mapping   tCDC_TIMING on tCDC_TIMING.start_lsn = tCDC_TABLE.__$start_lsn
         join tbl_PartsLoc           tPARTS_LOC  on tPARTS_LOC.loc_id     = tCDC_TABLE.id
    ),
    

/* Subquery showing which part records have changed location.  
   System table cdc.lsn_time_mapping stores the time stamp for each change tracked */
   tCDCPartsLoc as (
      select 
        'tbl_PartsLoc'                                     as cdc_Source
        ,tCDC_TABLE.part_id                                as cdc_PartId
        ,iif(tCDC_TABLE.__$operation = 1, 'DELETE',        
         iif(tCDC_TABLE.__$operation = 2, 'INSERT',        
         iif(tCDC_TABLE.__$operation = 3, 'UPDATE before', 
         iif(tCDC_TABLE.__$operation = 4, 'UPDATE',        
             'Unknown'))))                                 as cdc_ChangeType
        ,tCDC_TIMING.tran_end_time                         as cdc_TimeStamp
      from 
         cdc.dbo_tbl_PartsLoc_CT     tCDC_TABLE
         join cdc.lsn_time_mapping   tCDC_TIMING on tCDC_TIMING.start_lsn = tCDC_TABLE.__$start_lsn
    ),
    

/* Subquery showing which part records have had field values changed that are being tracked by CDC.  
   System table cdc.lsn_time_mapping stores the time stamp for each change tracked */
   tCDCParts as (
      select 
        'tbl_Parts'                                        as cdc_Source
        ,tCDC_TABLE.id                                     as cdc_PartId
        ,iif(tCDC_TABLE.__$operation = 1, 'DELETE',        
         iif(tCDC_TABLE.__$operation = 2, 'INSERT',        
         iif(tCDC_TABLE.__$operation = 3, 'UPDATE before', 
         iif(tCDC_TABLE.__$operation = 4, 'UPDATE',        
             'Unknown'))))                                 as cdc_ChangeType
        ,tCDC_TIMING.tran_end_time                         as cdc_TimeStamp
      from 
         cdc.dbo_tbl_Parts_CT      tCDC_TABLE
         join cdc.lsn_time_mapping tCDC_TIMING on tCDC_TIMING.start_lsn = tCDC_TABLE.__$start_lsn
    ),


/* All these change records coming from our three different sources are merged together 
   and then only the most recent parts table update record is kept. The rsult is sorted 
   by part number and then change time stampe */
   tUnion as (    
    select cdc_Source, cdc_TimeStamp, cdc_PartId, cdc_ChangeType from tCDCBin      union
    select cdc_Source, cdc_TimeStamp, cdc_PartId, cdc_ChangeType from tCDCPartsLoc union
    select cdc_Source, cdc_TimeStamp, cdc_PartId, cdc_ChangeType from tCDCParts 
   )
   
   select 
      cdc_Source 
     ,Max(cdc_TimeStamp) as MostRecentChange
     ,cdc_PartId 
     ,cdc_ChangeType 
   from 
     tUnion
   where
     cdc_ChangeType <> 'UPDATE before'     
   group by
      cdc_Source 
     ,cdc_PartId 
     ,cdc_ChangeType
   having 
      Max(cdc_TimeStamp) > ?
   order by
      cdc_PartId 
     ,2
    
for json path;        
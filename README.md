# Zeal-Zoho API 

Introduction
------------
Zeal Motors wants to use Zoho Inventory and Zoho CRM to manage sales orders, returns, and warranty claims so that their sales and service staff can benefit from Zoho’s user interface.

They currently have an in-house Material Resource Planning (MRP) system that stores their vehicle sales and parts inventory in a SQL Server database.

Parts are added and updated in SQL Server by the MRP software. The software also tracks vehicle sales.

These updates and sales need to be reflected in Zoho Invetory’s **Item** module and a Zoho CRM custom module called **Vehicles** respectively. Zoho needs a complete and accurate 
list of parts available, including their inventory quantities. The Zoho vehicle data must also be kept up to date so that staff can create sales orders in Zoho for parts related 
to a vehicle sale. When parts are included in a Zoho Inventory Sales Order the SQL Server inventory quantities for those parts must be adjusted.

Zoho will not be used for vehicle sales at this time.

This set of API endpoints can be used to get information from the MRP’s SQL Server Database and update inventory quantities in that same database. At this time Zoho is the 
only client for this API set.

Most of these instructions are for Zeal to explain to them how to setup and install the API. These instructions are also helpful to the Zoho developer that will be using this 
API in their Zoho code. 

-Jonathan Elkins 2024/09/15


How To Setup and Run The API Server
-----------------------------------
#### A. Setting Up The Environment To Host the API
1. Python may alread be installed on your on the designated API server. To check enter the following command from the command prompt: `python --version`
2. If it's not installed download and install it from the [Python web site](https://www.python.org/downloads/).  This app was developped with version 3.12.2. 
   **During the install ensure that you let the installer update your environment variables**.[^1]
3. Run `pip install pyodbc`  Microsoft's preferred SQL Server library.
4. Run `pip install fastapi` Simple to use API framework.
5. Run `pip install uvicorn` The web server that the API will be running on.
6. To support HTTPS you need to install a security certificate on the server. [^2]
7. Ensure that port `1433` is open to local traffic on the SQL Server server's firewal. If your installation of SQL Server is not using the standard port substitute `1433` for the 
   port that you are using.  
8. If you host the API itself on a different server than where your SQL Server database is installed:
   1. Ensure that the server's firewall opens the SQL Server port.[^3]
   2. Ensure that the all routers on the server's subnet are forwarding traffic for the port that SQL Server is using. [^3]
9. Ensure that the port that the API is using is open on the API server's firewal. [^3] [^4] 
10. Ensure that the all routers on the API server's subnet are forwarding traffic for port the API port. [^3]


#### B. Installing the API Server Code. 
1. Create a folder on the API server. Give it any name you want. For these instructions I'll assume that the the folder you created is called `Zeal.API` and it's located under the root of your `C:\` drive.
2. Get the API code files from Aether Automation. Contact Jonathan Elkins at jonathan.elkins@gmail.com or production@aetherautomation.com.
3. Copy the code files to the folder. 

#### C. Configuring the API Server Settings and the SQL Server database
1. For security reasons the initially supplied API code files may not contain the settings required to log into the database or the required API key.
2. If there is no `C:\Zeal.API\(settings)\settings.ini` in the API code files, Get the file from Aether or create it as described below. 
   Note that the name of the settings folder is surrounded with parentheses. The name and path of the folder must be: 
   ```
   <API path on your machine>\(settings)\settings.ini
   ```
3. The contents of the `settings.ini` file looks like this:
```
[DATABSE]
database_driver_name   = SQL Server
database_server        = <sql server host address>
database_name          = zMRP 
database_username      = <the SQL Server user connecting to the the API>          
database_password      = <password>

[API]
api_key                = ThisIsMyApIKeyvalue1234567890MAryHadALittleLambBlalabla
``` 
4. Replace the `database_server`, `database_name`, `database_username`, and `database_password` values as required. Leave the `database_driver_name` and `api_key` 
   values as shown. The Zoho Deluge code expects this key value. 
5. Set `database_server` to 127.0.0.1 if the SQL Server will be local to the API. Otherwise set `database_server` to the address of your SQL Server. 
5. Run SQL Server script `C:\Zeal.API\SQL\Script.SetupCDC.sql` to set up Change Data Capture (CDC) for tables `tbl_Parts`, `tbl_PartsLoc`, and `tbl_Localisation`.
   ==**Important**: Have a conversation with Jonathan before doing this step.==

#### D. Running The API Server. 
1. Open a command line window.
2. From the command line type in `C:` and then press enter.
3. From the command line type in `CD \Zeal.API\API` and then press enter.
4. From the command line type in `python -m uvicorn Zeal_API:app --reload --host 0.0.0.0 --port <host port> ` and then press enter. [^5][^6]
5. As long as the command line is running the uvicorn process the API server will be available. [^7]
6. If ANSI escape characters are not correctly displaying colors when launching the API server in the previous step, add the folllowing Windows Registry key to your API server machine:
```
[HKEY_CURRENT_USER\Console]
"VirtualTerminalLevel"=dword:00000001
```

   
API Specification Docs
----------------------
- To see a workflow diagram of how this API and Zoho are related [see this LucidChart](https://lucid.app/lucidchart/9a5eb720-7802-42d9-b21c-f15754faf382/edit?viewport_loc=-597%2C-3199%2C5637%2C2421%2CzJ-_WMjNL.gc&invitationId=inv_c1d1d086-0768-409a-aa47-b2222b984802).
- Detailed API specifications can be found [here](https://docs.google.com/spreadsheets/d/1j97nVWJLwiN8HdlcScTAOASkk532TB8mAmaI4VD9320/edit?usp=sharing).
- The links that follow is documentation generated by the FastAPI framework: [^4]
```
   http://<host address>:<host port>/docs  
   http://<host address>:<host port>/redoc 
```
- For details on how to set up SQL Server to use its Change Data Capture (CDC) system to track changes, see the 
[SQL Server configuration script](https://github.com/JPE3/ZealAPI/blob/main/SQL/Script.SetupCDC.sql). 
- For details on how the CDC tables are used to retrieve a record of changes see the comments in [the query that gets that data](https://github.com/JPE3/ZealDocs/blob/main/Script.SetupCDC.sql).

Sample API Calls 
----------------
See the footnote on HTTPS and IP address. [^4]

```
  1.  GET  http://<host address>:<host port>/api/hello?name=jonathan   
  2.  GET  http://<host address>:<host port>/api/testquery
  3.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/Customer/32
  4.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/Product/322
  5.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/VehicleSales/list?after_id=99
  6.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/VehicleSale/100
  7.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/PartsQty/list?after_id=15736
  8.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/Parts/list?after_id=7000
  9.  GET  http://<host address>:<host port>/api/SQL-to-Zoho/Part/7001
  10. GET  http://<host address>:<host port>/api/SQL-to-Zoho/PartBins/list?part_id=7001
  11. GET  http://<host address>:<host port>/api/SQL-to-Zoho/PartsCDC/list?after_timestamp=2024-09-07T23:59:59.999
  12. POST http://<host address>:<host port>/api/Zoho-to-SQL/PartQty/ 
           Here is a sample body to use with this POST API
               {
                   "delta"               : 10,
                   "qtyaction_id"        : 6,
                   "ZohoOrderNumber"     : "Test #333-3 from API",
                   "PartId"              : 7001,
                   "ZohoSalesPersonName" : "David Lord"
               }
           And here are some assumptions   : 1. At least one tbl_PartsQtySTK record already 
                                                exists in the table.
                                             2. If the ZohoSalesPersonName is not found 
                                                the user_id will be set to 0.
```

[^1]: This repository contains, in folder `(setup)`, an install copy of python version 3.12.5.
[^2]: Instructions to follow. 
[^3]: For added security, when opening firewall and router ports for the SQL Server and API hosts, determine what the IP address calling these services will be. Set the source to be that address only. 
[^4]: As of 2024/09/15 a test version of the API is available on the Azure test host. Get the `<host address>` and `<host port>` from Jonathan. The test API is connected to a test copy of Zeal's SQL 
      Server database. Aether's Zoho developer will use this host during Zoho development. 
      Note that the API still has no authentication security nor is HTTPS. 
[^5]: For dev work and testing use `uvicorn`. For production use `gunicorn`. Instructions for `gunicorn` to follow. 
[^6]: Host = 0.0.0.0 means listen for requests from any ip4 address. For added security determine what the IP address calling these services will be. Set the host to be that address only. 
[^7]: You will probably want to configure your API server to start the API automatically at startup.

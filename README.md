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

-Updated by Jonathan Elkins on 2024/09/15


How To Setup and Run The API Server
-----------------------------------
### A. Environment Setup - Installing Python and Configuring Ports
1. Python may alread be installed on your on the designated API server. To check enter the following command from the command prompt: `python --version`
2. If it's not installed download and install it from the [Python web site](https://www.python.org/downloads/).  This app was developped with version 3.12.2. 
   **During the install ensure that you let the installer update your environment variables**.[^1]
3. Run `pip install pyodbc`  Microsoft's preferred SQL Server library.
4. Run `pip install fastapi` Simple to use API framework.
5. Run `pip install uvicorn` The web server that the API will be running on.
6. Ensure that port `1433` is open to local traffic on the SQL Server server's firewal. If your installation of SQL Server is not using the standard port substitute `1433` for the 
   port that you are using.  
7. If you host the API itself on a different server than where your SQL Server database is installed:
   1. Ensure that the server's firewall opens the SQL Server port.[^2]
   2. Ensure that the all routers on the server's subnet are forwarding traffic for the port that SQL Server is using. [^2]
8. Ensure that the port that the API is using is open on the API server's firewal. [^2] [^3] 
9. Ensure that the all routers on the API server's subnet are forwarding traffic for port the API port. [^2]

### B. Environment Setup - HTTPS With Self Signed Certificate 
***Appropriate for testing HTTPS during development but not for production. Browsers will not trust self signed certificates.***

1. Open Command line window:
   - `Run Windows CLI`
2. Goto drive where certificate will be generated:
   - `C:`                                                                                     
3. CD to folder where you want to store the generated files:
   - `CD C:\Zeal.API\(settings)\https_cert_self_signed`                                                              
4. Generate a private key:
   - `openssl genrsa -out self_signed_server.key 2048`
5. Remove encryption from the key:
   - `openssl rsa -in self_signed_server.key -out self_signed_server.key`                                             
6. Generate a Certificate Signing Request (CSR):
   - `openssl req -sha256 -new -key self_signed_server.key -out self_signed_server.csr -subj '//CN=localhost'`        
7. Generate a self-signed SSL certificate for the API server:
   - `openssl x509 -req -sha256 -days 365 -in self_signed_server.csr -signkey self_signed_server.key -out self_signed_server.crt` 


### C. Environment Setup - HTTPS With CA Certificate 
***Appropriate for the target production server and currrently implemented on the Azure Zoho development server***
 
The Azure server now (2024/09/22) uses HTTPS and has been assigned a domain.
The following instructions are how an SSL certificate was created for the Azure server and 
could be created for Zeal's production server.

1. Acquire a domain name and set DNS to point at Azure Zoho development server. 
2. Set the DNS "A" record on the name server for the domain to point at the API server. 
3. Create an SSL certificate for the domain. Jonathan used  [Let's Encript](https://letsencrypt.org/)
   which offers free SSl certificates created and installed using [Certbot](https://certbot.eff.org/). 
   See the `..\(settings)\https_cert_azure\README.md` for details about `certbot`.
4. Once a certificate and private key are generated the python API server startup must 
   have parameters set to use the certificate and private key. See Section **F. Running The API Server** for details.

### D. Environment Setup - Installing the API Server Code. 
1. Create a folder on the API server. Give it any name you want. For these instructions I'll assume that the the folder you created is called `Zeal.API` and it's located under the root of your `C:\` drive.
2. Get the API code files from Aether Automation. Contact Jonathan Elkins at jonathan.elkins@gmail.com or production@aetherautomation.com.
3. Copy the code files to the folder. 

### E. Environment Setup - Configuring the API Server Settings and the SQL Server Database
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
api_key_header         = X-API-Key
api_key                = Get API Key value from Jonathan. 
``` 
4. Replace the `database_server`, `database_name`, `database_username`, and `database_password` values as required. Leave the `database_driver_name` and `api_key` 
   values as shown. The Zoho Deluge code expects this key value. 
5. Set `database_server` to 127.0.0.1 if the SQL Server will be local to the API. Otherwise set `database_server` to the address of your SQL Server. 
5. Run SQL Server script `C:\Zeal.API\SQL\Script.SetupCDC.sql` to set up Change Data Capture (CDC) for tables `tbl_Parts`, `tbl_PartsLoc`, and `tbl_Localisation`.
   ==**Important**: Have a conversation with Jonathan before doing this step.==

### F. Running The API Server. 
1. Open a command line window.
2. `C:`
3. `CD \Zeal.API\API`
4. For **HTTPS** : `python -m uvicorn Zeal_API:app --reload --host 0.0.0.0 --port <host port> --ssl-certfile <cert file> --ssl-keyfile <private key file>` [^4][^5]
5. For **HTTP**  : `python -m uvicorn Zeal_API:APP --reload --host 0.0.0.0 --port <host port>` [^4][^5]
6. As long as the command line window is open and is running the uvicorn process the API server will be available. [^6]
#### Notes
- There is also a batch file (`Zeal.API\StartZealAPI.bat`) that will do steps 1. to 4. automatically. 
- If ANSI escape characters are not correctly displaying colors when launching the API server, add the folllowing Windows Registry key to your API server machine:
```
[HKEY_CURRENT_USER\Console]
"VirtualTerminalLevel"=dword:00000001
```

   
API Specification Docs
----------------------
- To see a workflow diagram of how this API and Zoho are related [see this LucidChart](https://lucid.app/lucidchart/9a5eb720-7802-42d9-b21c-f15754faf382/edit?viewport_loc=-597%2C-3199%2C5637%2C2421%2CzJ-_WMjNL.gc&invitationId=inv_c1d1d086-0768-409a-aa47-b2222b984802).
- Detailed API specifications can be found [here](https://docs.google.com/spreadsheets/d/1j97nVWJLwiN8HdlcScTAOASkk532TB8mAmaI4VD9320/edit?usp=sharing).
- The links that follow are documentation generated by the FastAPI framework: [^3]
```
   https://<host address>:<host port>/docs  
   https://<host address>:<host port>/redoc 
```
- For details on how to set up SQL Server to use its Change Data Capture (CDC) system to track changes, see the 
[SQL Server configuration script](https://github.com/JPE3/ZealDocs/blob/main/Script.SetupCDC.sql). 
- For details on how the CDC tables are used to retrieve a record of changes see the comments in [the query that gets that data](https://github.com/JPE3/ZealDocs/blob/main/GetPartsCDC.sql).

Sample API Calls 
----------------
See the footnote on HTTPS and IP address. [^3]

Because API keys have been implemented for all endpoints you need to use a tool like [Postman](https://www.postman.com/) or [curl](https://curl.se/docs/manpage.html) to add the api key header to all GETs and POSTs listed below.

Here is a sample `curl` command for the `testquery` end point:
```
   curl --header "X-API-Key: type the api key here" https://127.1.1.1:8000/api/testquery
```
All API End Points currently implemented:
```
  1.  GET  https://<host address>:<host port>/api/hello?name=jonathan   
  2.  GET  https://<host address>:<host port>/api/testquery
  3.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/Customer/32
  4.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/Product/322
  5.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/VehicleSales/list?after_id=99
  6.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/VehicleSale/100
  7.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/PartsQty/list?after_id=15736
  8.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/Parts/list?after_id=7000
  9.  GET  https://<host address>:<host port>/api/SQL-to-Zoho/Part/7001
  10. GET  https://<host address>:<host port>/api/SQL-to-Zoho/PartBins/list?part_id=7001
  11. GET  https://<host address>:<host port>/api/SQL-to-Zoho/PartsCDC/list?after_timestamp=2024-09-07T23:59:59.999
  12. POST https://<host address>:<host port>/api/Zoho-to-SQL/PartQty/ 
           Here is a sample body to use with this POST API. Use curl or Postman to add this body to the call:
               {
                   "delta"               : 10,
                   "qtyaction_id"        : 6,
                   "ZohoOrderNumber"     : "Test #333-3 from API",
                   "PartId"              : 7001,
                   "ZohoSalesPersonName" : "David Lord"
               }
           And here are some assumptions   : 1. At least one tbl_PartsQtySTK record already exists in the table.
                                             2. If the ZohoSalesPersonName is not found the user_id will be set to 0.
```

[^1]: This repository contains, in folder `(setup)`, an install copy of python version 3.12.5.
[^2]: For added security, when opening firewall and router ports for the SQL Server and API hosts, determine what the IP address calling these services will be. Set the source to be that address only. 
[^3]: As of 2024/09/22 a test version of the API is available on the Azure test host. Get the `<host address>`, `<host port>`, and API key from Jonathan. The test API is connected to a test copy of Zeal's SQL 
      Server database. Aether's Zoho developer will use this host during Zoho development. 
      Note that the API is now using an API key as authentication and has been implemented as HTTPS. 
[^4]: For dev work and testing use `uvicorn`. For production use `gunicorn`. Instructions for `gunicorn` to follow. 
[^5]: Host = 0.0.0.0 means listen for requests from any ip4 address. For added security determine what the IP address calling these services will be. Set the host to listen on that address only. 
[^6]: You will probably want to configure your API server to start the API automatically at startup. I have created a batch file that I schedule to run at startup using Task Scheduler.

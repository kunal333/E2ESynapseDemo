## Script Explained

**Following are the steps the script performs to create Azure Resources and downloads data from cms.gov and loads data into Synapse Tables:**
1. Prompts User for Resource Group Name and Password
2. Presets various variables like SQL Server Name, Azure Data Factory Name, Storage Name, etc. using Resource Group Name provided in Step 1.
3. Creates SQL Server
4. Creates Synaspe (SQL Pool)
5. Gets your Public IP so it can configured in the Synapse Firewall
6. Sets the Firewall Rules for Synaspe (SQL Pool)
7. Creates Azure Data Factory
8. Creates Azure Data Lake Storage Account
9. Creates Storage Containers for the CMS data
10. Creates parameters file for the Azure Data Factory ARM Template
11. Deploys Azure Data Factory ARM Template that contains,pipelines, datasets and dataflows
12. Gets Storage Access Key
13. Gets Connection String for the Synaspe (SQL Pool)
14. Creates Tables and Views in Synapse using script synapseCMSddls.sql
15. Downloads CMS PartD data from website https://www.cms.gov/ and saves into the Storage
16. Executes Azure Data Factory pipelines that reads CMS Data from Storage and loads into Synaspe (SQL Pool)


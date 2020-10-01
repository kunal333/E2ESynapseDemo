# CMS Demo using Azure Synapse, Azure Data Factory and PowerBI

The purpose of the script is to automate the deployment process for spinning up the demo environment.  The script takes care of deploying Resources in Azure like Synapse, Azure Data Factory and ADLS Storage.  It also downloads Healthcare based CMS data and loads into Synapse database.  This CMS data is then used for reporting using PowerBI.

Below are the pre-requisite for the script:
1. Powershell version 7.0.3 or later
2. Install Powershell Module SQLServer
3. Access to the Azure Portal to be able to create resources

The script workes in following steps:
1. Prompts User for Resource Group Name and SQL Pool Password
2. Presets various variables like SQL Server Name, Azure Data Factory Name, Storage Name, etc. using Resource Group Name provided in Step 1.
3. Creates SQL Server
4. Creates Synaspe (SQL Pool)
5. Gets your Public IP so we can set in the Synapse Firewall
6. Sets the Firewall Rules for Synapse
7. Creates Azure Data Factory
8. Creates Storage Account
9. Creates Storage Containersfor the CMS data
10. Creates parameters file for the ADF ARM Template
11. Deploys ADF ARM Template with the parameters file created in previous step
12. Gets Storage Access Key
13. Gets Connection String for the Synapse Pool
14. Creates Tables and Views in Synapse using script synapseCMSddls.sql
15. Downloads CMS data from website cms.gov and saves into the Storage
16. Executes ADF pipelines that loads the CMS Data from Storage into Synapse

Next step is to get the PowerBI tempate and connect to the Synapse instance.

Things to note:
1. In order to connect to Synapse instance, make sure to add your IP address to the Firewall
2. You might have to also enable flag in SQLPool Firewall settings to be able to allow Polybase "Allow Azure services and resources to access this server"
3. You might have to regenerate Master Key Password in Synapse "ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = '<Password>'".  Although synapseCMSddls.sql does reset the Master Key.



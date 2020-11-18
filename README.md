## CMS Demo using Azure Synapse, Azure Data Factory and Power BI

The purpose of the script is to automate the deployment process for spinning up demo environment to host CMS data in Synapse Analytics. The script takes care of deploying Resources in Azure like Synapse Analytics, Azure Data Factory and Azure Data Lake Storage. It also downloads Healthcare based CMS data and loads into Synapse database.  This CMS data is then used for reporting using Power BI.

**The Main script works in following steps:**
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
17. Next step is to get the Power BI tempate and connect to the Synapse instance. A tutorial of deploying the parameterized Power BI Template file is here: https://youtu.be/_mslQZM7NrU 

![Image of Dashboard](https://github.com/kunal333/E2ESynapseDemo/blob/master/Dashboard%20Image.png)


![Source to Target](https://github.com/kunal333/E2ESynapseDemo/blob/master/Source%20to%20Target.png)

## Pre-requisites:
1. Install Powershell version 7.0.3 or later (Reference Link: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)
2. Install Powershell Module SQLServer (Reference Link: https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module?view=sql-server-ver15)
3. Access to the Azure Portal to be able to create resources

## How to use the script:
1. Clone Git repository local
2. Open Powershell and navigate to the git folder
3. Execute the script deploySynapseStorageADF.ps1 from Powershell, example `./deploySynapseStorageADF.ps1`

## Things to note:
1. If you're on a VPN, you might have to add your IP address to the SQLPool Firewall settings in Azure Portal manually in order to connect to Synapse instance.
2. You might have to also enable flag in SQLPool Firewall settings to be able to allow Polybase "Allow Azure services and resources to access this server"
3. SQL Script synapseCMSddls.sql does reset the Master Key but you can overwrite Master Key Password in Synapse `ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = '<Password>'"`.

## Contributing
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com)
with any additional questions or comments.

## License
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT License. This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.

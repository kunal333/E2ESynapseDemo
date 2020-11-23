Below are the steps to execute PowerShell script from your Local machine:

1. Install **Powershell** version 7.1 or newer (Reference Link: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)

`$PSVersionTable`

2. Once installed, open PowerShell (pwsh) as Adminstrator (in Windows) and Install PowerShell Module **Azure** version 4.7.0 or later (Reference Link: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.7.0)

`Install-Module -Name Az -RequiredVersion 4.7.0`

3. Install PowerShell Module **Azure Storage** Module

`Install-Module -Name Az.Storage -RequiredVersion 2.0.0 -AllowClobber`

4. Install Powershell Module **SQLServer** (Reference Link: https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module?view=sql-server-ver15)

`Install-Module -Name SqlServer -Force -Confirm`

5. Connect to Azure Account using commands below:

`Connect-AzAccount`

6. Follow rest of the steps 2 through 4 from section '4 Easy Steps to Deployment' at <a href="https://github.com/kunal333/E2ESynapseDemo/blob/master/README.md#4-easy-steps-to-deployment" title="README">READ ME</a>.


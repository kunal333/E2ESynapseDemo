Below are the steps to execute PowerShell script from your Desktop:

1. Install Powershell version 5.1 or newer (Reference Link: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7)

`$PSVersionTable`

2. Install Powershell Module SQLServer (Reference Link: https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module?view=sql-server-ver15)

`Install-Module -Name SqlServer -Force -Confirm`

3. Connect to Azure Account using commands below:

`Connect-AzAccount`

4. Follow rest of the steps 2 through 4 from section '4 Easy Steps to Deployment' at <a href="https://github.com/kunal333/E2ESynapseDemo/blob/master/README.md#4-easy-steps-to-deployment" title="README">READ ME</a>.


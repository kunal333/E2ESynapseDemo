#Connect-AzAccount
#Get-AzSubscription
#Set-AzContext -SubscriptionName "Adam's sub"

#Get Urer Input
$resourceGroupName = Read-Host "Enter Resource Group Name"
$servername = Read-Host "Enter Server Name"
$database = Read-Host "Enter Database Name"


#Default variables
$location = "westus2"
$adminlogin = $servername+"admin"
$password = "NewPassword0~"
# The ip address range that you want to allow to access your server - change as appropriate


Write-Host "Server Username: $adminlogin"

Function Get-resourceGroupName {

    $rgInstance = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($rgInstance)
    {
        Write-Host "Resource Group Name already exists"
        $script:resourceGroupName = Read-Host "Enter Resource Group Name"
        Get-resourceGroupName
    }
    else 
    {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
}

Function Get-sqlServerName {
    
    $serverInstance = Get-AzSqlServer -ServerName $servername -ErrorAction SilentlyContinue
    if ($serverInstance)
    {
        Write-Host "Server Name already exists"
        $script:servername = Read-Host "Enter Server Name"
        Get-sqlServerName
    }
    else 
    {
        New-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $servername -Location $location -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
    }
}

Function Get-DatabaseName {
     
     $dbInstance = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $servername -DatabaseName $database -ErrorAction SilentlyContinue
    if ($dbInstance)
    {
        Write-Host "Server Name already exists"
        $script:database = Read-Host "Enter Database Name"
        Get-DatabaseName
    }
    else {
        New-AzSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $database  -Edition "DataWarehouse" -RequestedServiceObjectiveName "DW100c" -CollationName "SQL_Latin1_General_CP1_CI_AS" -MaxSizeBytes 10995116277760
    }
}

function Get-yourPublicIP {
    $script:ipaddr = (Invoke-WebRequest -uri "https://api.ipify.org/").Content
}

Function Set-FirewallRule {
    $clientIPRuleName = "ClientIP-"+$ipaddr
#    Write-Host "Client Ip addre rule name: $clientIPRuleName"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName $clientIPRuleName -StartIpAddress $ipaddr -EndIpAddress $ipaddr
}

#Prompt for details
Get-resourceGroupName
Get-sqlServerName
Get-yourPublicIP
Set-FirewallRule
Get-DatabaseName

write-host "RG: $resourceGroupName, Server : $servername, DB : $database, ServerUserName: $adminlogin, IP address: $ipaddr" 


<#

New-AzResourceGroup -Name $resourceGroupName -Location $location

#>


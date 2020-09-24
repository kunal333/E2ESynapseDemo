#Connect-AzAccount
#Get-AzSubscription
#Set-AzContext -SubscriptionName "Adam's sub"

#Get Urer Input
$resourceGroupName = Read-Host "Enter Resource Group Name"
$servername = $resourceGroupName.ToLower()+"server"
$database = $resourceGroupName.ToLower()+"pool"
$adfName = $resourceGroupName.ToLower()+"adf"
$storageName = $resourceGroupName.ToLower()+"storage"

#Default variables
$location = "westus2"
$adminlogin = $servername+"admin"
$password = "NewPassword0~"
# The ip address range that you want to allow to access your server - change as appropriate

Function Set-resourceGroupName {

    $rgInstance = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($rgInstance)
    {
        Write-Host "Resource Group Name already exists"
        $script:resourceGroupName = Read-Host "Enter Resource Group Name"
        Set-resourceGroupName
    }
    else 
    {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
}

Function Set-sqlServerName {
    
    $serverInstance = Get-AzSqlServer -ServerName $servername -ErrorAction SilentlyContinue
    if ($serverInstance)
    {
        Write-Host "Server Name already exists"
        $script:servername = Read-Host "Enter Server Name"
        Set-sqlServerName
    }
    else 
    {
        New-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $servername -Location $location -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
    }
}

Function Set-DatabaseName {
     
     $dbInstance = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $servername -DatabaseName $database -ErrorAction SilentlyContinue
    if ($dbInstance)
    {
        Write-Host "Server Name already exists"
        $script:database = Read-Host "Enter Database Name"
        Set-DatabaseName
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

Function Set-ADFName {
     
    $adfInstance = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $adfName  -ErrorAction SilentlyContinue
   if ($adfInstance)
   {
       Write-Host "ADF Name already exists"
       $script:adfName = Read-Host "Enter ADF Name"
       Set-ADFName
   }
   else {
        Set-AzDataFactoryV2 -ResourceGroupName $resourcegroupname -Name $adfName -Location $location
   }
}

Function Set-StorageName {
     
    $storageInstance = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName  -ErrorAction SilentlyContinue
   if ($storageInstance)
   {
       Write-Host "Storage Name already exists"
       $script:storageName = Read-Host "Enter Storage Name"
       Set-StorageName
   }
   else {
        New-AzStorageAccount -ResourceGroupName $resourcegroupname -AccountName $storageName -Location $location -SkuName Standard_LRS -Kind StorageV2 -EnableHierarchicalNamespace $true
   }
}


#Prompt for details
Get-yourPublicIP
Set-resourceGroupName
Set-sqlServerName
Set-FirewallRule
Set-DatabaseName
Set-ADFName
Set-StorageName

write-host "RG: $resourceGroupName, Server: $servername, DB: $database, SQLServerAdminUsername: $adminlogin, ADF Name: $adfName, StorageName: $storageName, IP address: $ipaddr"

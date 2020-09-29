$currentTime = Get-Date
Write-Host "Script started at" + $currentTime

# Install-Module dbatools
# Connect-AzAccount
# Get-AzSubscription
# Set-AzContext -SubscriptionName "Adam's sub"

#Get Urer Input
$resourceGroupName = Read-Host "Enter Resource Group Name"
$password = Read-Host "Enter SQL Server Password" #-assecurestring

#Default variables
$servername = $resourceGroupName.ToLower()+"server"
$database = $resourceGroupName.ToLower()+"pool"
$adfName = $resourceGroupName.ToLower()+"adf"
#$integrationRuntimeName = $resourceGroupName.ToLower()+"ir"
$storageName = $resourceGroupName.ToLower()+"storage"
$location = "westus2"
$adminlogin = $servername+"admin"
$path = Get-Location
$ContainerName = "cms-part-d-prescriber"


# Functions

Function Set-resourceGroupName {

    $rgInstance = Get-AzResourceGroup -Name $resourceGroupName `
        -ErrorAction SilentlyContinue
    if ($rgInstance)
    {
        Write-Host "Resource Group Name already exists"
        $script:resourceGroupName = Read-Host "Enter Resource Group Name"
        Set-resourceGroupName
    }
    else 
    {
        New-AzResourceGroup -Name $resourceGroupName `
            -Location $location
    }
}

Function Set-SQLServer {
    
    $serverInstance = Get-AzSqlServer -ServerName $servername -ErrorAction SilentlyContinue
    if ($serverInstance)
    {
        Write-Host "Server Name already exists"
        $script:servername = Read-Host "Enter Server Name"
        Set-SQLServer
    }
    else 
    {
        New-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $servername -Location $location -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
    }
}

Function Set-SQLPool {
     
     $dbInstance = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $servername -DatabaseName $database -ErrorAction SilentlyContinue
    if ($dbInstance)
    {
        Write-Host "Server Name already exists"
        $script:database = Read-Host "Enter Database Name"
        Set-SQLPool
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

    New-AzSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName $clientIPRuleName -StartIpAddress $ipaddr -EndIpAddress $ipaddr

    $adfIP = "20.42.132.37"

    New-AzSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName "ADF" -StartIpAddress $adfIP -EndIpAddress $adfIP
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

Function Set-ContainerAndSAS {    
    $script:context = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageName).context

    New-AzStorageContainer -Context $context -Name $ContainerName -Permission Off
    New-AzStorageContainer -Context $context -Name "staging" -Permission Off
    $StartTime = Get-Date
    $EndTime = $startTime.AddHours(10.0)
    $script:sasToken = New-AzStorageAccountSASToken -Context $context -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup -StartTime $StartTime -ExpiryTime $EndTime

}

Function Get-CMSDataAndUnzip {
    Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_13.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_13.zip
    Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_14.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_14.zip
    Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_15.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_15.zip
    Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_16.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_16.zip
    Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_17.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_17.zip
<#
    Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_13.zip" -DestinationPath $path -Verbose
    Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_14.zip" -DestinationPath $path -Verbose
    Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_15.zip" -DestinationPath $path -Verbose
    Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_16.zip" -DestinationPath $path -Verbose
    Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_17.zip" -DestinationPath $path -Verbose
#>
}

Function Set-UploadCMSData {
    ./azcopy copy "$path/PartD_*.txt" "https://$storageName.blob.core.windows.net/$ContainerName/$sasToken" --recursive=true
}

Function Set-CleanUp {
}

Function Set-ParametersFile {

    $MyJsonVariable = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "factoryName": {
            "value": "$adfName"
        },
        "AzureDataLakeStorage1_accountKey": {
            "value": "$storageKey1"
        },
        "AzureSqlDB_connectionString": {
            "value": "$SQLPoolconnectionString"
        },
        "cmsdemopool_connectionString": {
            "value": "$SQLPoolconnectionString"
        },
        "AzureDataLakeStorage1_properties_typeProperties_url": {
            "value": "https://$storageName.dfs.core.windows.net/"
        }
    }
}
"@

    Set-Content adf_csm_arm_template_parameters.json $MyJsonVariable

}

Function Set-DeployADFARMTemplate {
    $templateFile = "$path/adf_csm_arm_template.json"
    $parameterFile="$path/adf_csm_arm_template_parameters.json"
    New-AzResourceGroupDeployment `
    -Name $adfName `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFile `
    -TemplateParameterFile $parameterFile
}

Function Get-StorageKey {
    $script:storageKey1 = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageName -ListKerbKey)[0].Value
}

Function Get-ConnectionString {
    $script:SQLPoolconnectionString = "data source="+$servername+".database.windows.net;Initial Catalog="+$database+";Persist Security Info=False;User ID="+$adminlogin+";Password="+$password+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
#    "integrated security=False;encrypt=True;connection timeout=30;data source=cmsdemo4server.database.windows.net;initial catalog=cmsdemo4pool;user id=cmsdemo4serveradmin;server=tcp:cmsdemo4server.database.windows.net,1433;persist security info=False;multipleactiveresultsets=False;trustservercertificate=False",
     #    $script:SQLPoolconnectionString = "Server=$servername;Database=$database;User ID=$adminlogin;Password=$password;Timeout=60;datasource=$servername"
}

Function Set-SynapseDDLs {

$synapseSqlName = $servername+".database.windows.net"
$loginName = Get-Credential -Message "Enter your SQL on-demand password" -UserName $adminlogin
Invoke-DbaQuery -SqlInstance $synapseSqlName -Database $databaseName -SqlCredential $loginName -File "$path/synapseCMSddls.sql"
}

Function Get-ADFIR {
    $integrationRuntimeName = Get-AzDataFactoryV2IntegrationRuntime $adfName -ResourceGroupName $resourceGroupName
}

Function Set-ADFLinkedServices {
    $sqlServerLinkedServiceDefinition = @"
{
   "properties": {
     "type": "AzureSqlDW",
     "typeProperties": {
         "connectionString": {
             "type": "SecureString",
            "value": "Server=$servername;Database=$database;User ID=$adminlogin;Password=$password;Timeout=60"
         }
     }
 },
 "name": "SynapseLinkedService"
}
"@

## IMPORTANT: stores the JSON definition in a file that will be used by the Set-AzDataFactoryLinkedService command. 
$sqlServerLinkedServiceDefinition | Out-File "$path\SynapseLinkedService.json"

## Encrypt SQL Server credentials 
New-AzDataFactoryV2LinkedServiceEncryptedCredential -IntegrationRuntimeName "AutoResolveIntegrationRuntime" -DataFactoryName $adfName -ResourceGroupName $resourceGroupName -DefinitionFile "$path\SynapseLinkedService.json" > "$path\EncryptedSynapseLinkedService.json"

# Create a SQL Server linked service
Set-AzDataFactoryV2LinkedService -DataFactoryName $adfName -ResourceGroupName $resourceGroupName -Name "EncryptedSqlServerLinkedService" -File "$path\EncryptedSynapseLinkedService.json"

}

# Call Functions
Get-yourPublicIP
Set-resourceGroupName
Set-SQLServer
Set-FirewallRule
Set-SQLPool
Set-StorageName
Set-ContainerAndSAS
Get-StorageKey
Get-ConnectionString
Set-ADFName
Set-ParametersFile
#Set-ADFIR
#Set-ADFLinkedServices
Set-DeployADFARMTemplate
#Set-SynapseDDLs

write-host "RG:$resourceGroupName, Server:$servername, DB:$database, SQLServerAdminUsername:$adminlogin, ADF Name:$adfName, StorageName:$storageName, IP address:$ipaddr, Password:$password, SaSTokey:$sasToken"

$currentTime = Get-Date
Write-Host "Script Finished at" + $currentTime


#Get-CMSDataAndUnzip
#Set-UploadCMSData
#Set-CleanUp


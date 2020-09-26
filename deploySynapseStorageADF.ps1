Connect-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionName "Adam's sub"

#Get Urer Input
$resourceGroupName = Read-Host "Enter Resource Group Name"
$password = Read-Host "Enter SQL Server Password" #-assecurestring

#Default variables
$servername = $resourceGroupName.ToLower()+"server"
$database = $resourceGroupName.ToLower()+"pool"
$adfName = $resourceGroupName.ToLower()+"adf"
$storageName = $resourceGroupName.ToLower()+"storage"
$location = "westus2"
$adminlogin = $servername+"admin"
$path = Get-Location
$ContainerName = "cms-part-d-prescriber"


# Call Functions
Get-yourPublicIP
Set-resourceGroupName
Set-sqlServerName
Set-FirewallRule
Set-DatabaseName
Set-ADFName
Set-StorageName
Set-ContainerAndSAS
Set-DeployADFARMTemplate
Get-StorageKey
Get-ConnectionString
Set-ParametersFile
#Get-CMSDataAndUnzip
#Set-UploadCMSData
#Set-CleanUp

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
    $script:SQLPoolconnectionString = "Server=tcp:"+$servername+".database.windows.net,1433;Initial Catalog="+$database+";Persist Security Info=False;User ID="+$adminlogin+";Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
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

write-host "RG:$resourceGroupName, Server:$servername, DB:$database, SQLServerAdminUsername:$adminlogin, ADF Name:$adfName, StorageName:$storageName, IP address:$ipaddr, Password:$password, SaSTokey:$sasToken"

$currentTime = Get-Date
Write-Host "Script started at" + $currentTime

# Install-Module -Name SqlServer # Restart Powershell Command line
# Update-Module -Name SqlServer

#Connect-AzAccount
#Get-AzSubscription
#Set-AzContext -SubscriptionName <subscription name>

#Get Urer Input
$resourceGroupName = Read-Host "Enter Resource Group Name"
$password = Read-Host "Enter SQL Server Password" #-assecurestring

#Default variables
$servername = $resourceGroupName.ToLower()+"server"
$database = $resourceGroupName.ToLower()+"pool"
$DataFactoryName = $resourceGroupName.ToLower()+"adf"
$storageName = $resourceGroupName.ToLower()+"storage"
$location = "westus2"
$adminlogin = $servername+"admin"
$path = Get-Location
$ContainerName = "cms-part-d-prescriber"


# Functions

Function Set-resourceGroupName {
    Write-Host  "Step 1/15: Creating Resource Group: $resourceGroupName" 
    Write-Host "Note:All subsequent resources will be created inside this Resource Group"

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
    
    Write-Host  "Step 2/15: Creating SQL Server: $servername"

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

    Write-Host  "Step 5/15: Creating SQL Pool: $database"

     $dbInstance = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $servername -DatabaseName $database -ErrorAction SilentlyContinue
    if ($dbInstance)
    {
        Write-Host "Server Name already exists"
        $script:database = Read-Host "Enter Database Name"
        Set-SQLPool
    }
    else {
        New-AzSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $database  -Edition "DataWarehouse" -RequestedServiceObjectiveName "DW400c" -CollationName "SQL_Latin1_General_CP1_CI_AS" -MaxSizeBytes 10995116277760
    }
}

function Get-yourPublicIP {
    Write-Host  "Step 3/15: Getting your Public IP so we can set in the Synapse Firewall"

    $script:ipaddr = (Invoke-WebRequest -uri "https://api.ipify.org/").Content
}

Function Set-FirewallRule {

    Write-Host  "Step 4/15: Setting the Firewall Rules for Synapse"
    
    $clientIPRuleName = "ClientIP-"+$ipaddr

    New-AzSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName $clientIPRuleName -StartIpAddress $ipaddr -EndIpAddress $ipaddr

    $adfIP = "20.42.132.37"

    New-AzSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName "ADF" -StartIpAddress $adfIP -EndIpAddress $adfIP
    
    New-AzSqlServerFirewallRule -ResourceGroupName $resourcegroupname -ServerName $servername -FirewallRuleName "Allow Trusted Services" -StartIpAddress '0.0.0.0' -EndIpAddress '0.0.0.0'

}

Function Set-DataFactory {

    Write-Host  "Step 10/15: Creating Azure Data Factory: $DataFactoryName"

    $adfInstance = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $DataFactoryName  -ErrorAction SilentlyContinue
   if ($adfInstance)
   {
       Write-Host "ADF Name already exists"
       $script:adfName = Read-Host "Enter ADF Name"
       Set-DataFactory
   }
   else {
        Set-AzDataFactoryV2 -ResourceGroupName $resourcegroupname -Name $DataFactoryName -Location $location
   }
}

Function Set-StorageName {

    Write-Host  "Step 6/15: Creating Storage Account: $storageName"

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

    Write-Host  "Step 7/15: Creating Storage Containers $ContainerName and Staging for the CMS data"

    $script:context = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageName).context

    New-AzStorageContainer -Context $context -Name $ContainerName -Permission Off
    New-AzStorageContainer -Context $context -Name "staging" -Permission Off
    $StartTime = Get-Date
    $EndTime = $startTime.AddHours(10.0)
    $script:sasToken = New-AzStorageAccountSASToken -Context $context -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup -StartTime $StartTime -ExpiryTime $EndTime

}

Function Set-CleanUp {
}

Function Set-ParametersFile {

    Write-Host  "Step 11/15: Creating Parameters File for the ADF ARM Template"

    $MyJsonVariable = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "factoryName": {
            "value": "$DataFactoryName"
        },
        "AzureDataLakeStorage1_accountKey": {
            "value": "$storageKey1"
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

    Set-Content arm_template_parameters.json $MyJsonVariable

}

Function Set-DeployADFARMTemplate {

    Write-Host  "Step 12/15: Deploying ADF ARM Template with the new Parameters File"

    $templateFile = "$path/arm_template.json"
    $parameterFile="$path/arm_template_parameters.json"
    New-AzResourceGroupDeployment `
    -Name $DataFactoryName `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFile `
    -TemplateParameterFile $parameterFile
}

Function Get-StorageKey {
    
    Write-Host  "Step 8/15: Getting Storage Access Key"

    $script:storageKey1 = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageName -ListKerbKey)[0].Value
}

Function Get-ConnectionString {
    
    Write-Host  "Step 9/15: Getting Connection String for the Synapse Pool"

    $script:SQLPoolconnectionString = "data source="+$servername+".database.windows.net;Initial Catalog="+$database+";Persist Security Info=False;User ID="+$adminlogin+";Password="+$password+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

Function Set-SynapseDDLs {

    Write-Host  "Step 14/15: Creating Tables and Views in Synapse"

    $synapseSqlName = $servername+".database.windows.net"
    Invoke-Sqlcmd -InputFile "$path/synapseCMSddls.sql" -ServerInstance $synapseSqlName -Database $database -Username $adminlogin -Password $password
}

Function Get_CMSData {

    Write-Host "Step 13/15: Downloading CMS data from website and saving into ADLS"

    for ($num = 13 ; $num -le 17 ; $num++)
    {
        $CMSFileName = "Download_CMSPart$num"
        $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName $CMSFileName

        while ($True) {
        $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $runId

        if ($run) {
            if ($run.Status -ne 'InProgress') {
                Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Yellow"
                $run
                break
            }
            Write-Host  "Pipeline is running...status: InProgress" -foregroundcolor "Yellow"
        }

        Start-Sleep -Seconds 15
        }
    }
    
    $newRunId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName "uncompress_CMS_Files"

    while ($True) {
        $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $newRunId

        if ($run) {
            if ($run.Status -ne 'InProgress') {
                Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Yellow"
                $run
                break
            }
            Write-Host  "Pipeline is running...status: InProgress" -foregroundcolor "Yellow"
        }

        Start-Sleep -Seconds 15
    }
    
    Write-Host "All CMS files needed for the demo saved in the Storage Account: $storageName"

}

Function Set-LoadSynapseTables {

    Write-Host "Step 15/15: Executing ADF Pipelines that loades into Synapse the CMS Data from Storage "

    $TablesList1 = @("Drug","Providers","Specialty","States")
    $myarray1 = [System.Collections.ArrayList]::new()

    Foreach ($i in $TablesList1)
    {
        Write-Host "Loading Table: $i"
        $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName $i
        $myArray1.Add($runId)
    }
    foreach ($element in $myArray1) {$element}
    foreach ($element in $myArray1) {
        while ($True) {

            $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $element

            if ($run) {
                if ($run.Status -ne 'InProgress') {
                    Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Green"
                    $run
                    break
                }
                Write-Host  "Pipeline is running...status: InProgress... Will check again in 60 seconds" -foregroundcolor "Yellow"
            }

        Start-Sleep -Seconds 60
        }
    }

    $TablesList2 = @("Geography")
    $myarray2 = [System.Collections.ArrayList]::new()

    Foreach ($i in $TablesList2)
    {
        Write-Host "Loading Table: $i"
        $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName $i
        $myArray2.Add($runId)
    }
    foreach ($element in $myArray2) {$element}
    foreach ($element in $myArray2) {
        while ($True) {

            $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $element

            if ($run) {
                if ($run.Status -ne 'InProgress') {
                    Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Green"
                    $run
                    break
                }
                Write-Host  "Pipeline is running...status: InProgress... Will check again in 60 seconds" -foregroundcolor "Yellow"
            }

        Start-Sleep -Seconds 60
        }
    }

    $TablesList3 = @("Details")
    $myarray3 = [System.Collections.ArrayList]::new()

    Foreach ($i in $TablesList3)
    {
        Write-Host "Loading Table: $i"
        $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName $i
        $myArray3.Add($runId)
    }
    foreach ($element in $myArray3) {Write-Host "Pipeline IDs as: $element"}
    foreach ($element in $myArray3) {
        while ($True) {

            $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $element

            if ($run) {
                if ($run.Status -ne 'InProgress') {
                    Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Green"
                    $run
                    break
                }
                Write-Host  "Pipeline is running...status: InProgress... Will check again in 60 seconds" -foregroundcolor "Yellow"
            }

        Start-Sleep -Seconds 60
        }
    }

    Write-Host "All Tables loaded to Synapse Instance: $database"
}

Function Set-ScaleDownSynapse {
    Write-Host "Synapse Scale down has started from DW400c to DW100c" -foregroundcolor "Yellow"
    Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -DatabaseName $database -ServerName $servername -RequestedServiceObjectiveName "DW100c"
    Write-Host "Synapse Scale down has finished to DW100c" -foregroundcolor "Green"
}

# Call Functions
Set-resourceGroupName
Set-SQLServer
Get-yourPublicIP
Set-FirewallRule
Set-SQLPool
Set-StorageName
Set-ContainerAndSAS
Get-StorageKey
Get-ConnectionString
Set-DataFactory
Set-ParametersFile
Set-DeployADFARMTemplate
Get_CMSData
Set-SynapseDDLs
Set-LoadSynapseTables
Set-ScaleDownSynapse

#Set-CleanUp

$currentTime = Get-Date
Write-Host "Script Finished at" + $currentTime

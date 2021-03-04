$currentTime = Get-Date
Write-Host "Script started at" + $currentTime

#Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

$path = Get-Location
$getDate = Get-Date -Format "MMddyyyy"
$location = "westus2"

$UPN = (Get-AzContext).Account.Id
$principalId = (Get-AzAdUser -UserPrincipalName $UPN).Id

$resourceCheck = Read-Host "Do you want to use any existing resource(s) or create all resources from scratch?  Enter 1 for NEW or 2 for EXISTING"
if ($resourceCheck -eq 1)
{
    # Set Variables
    $resourceGroupName = Read-Host "Enter New Resource Group Name"
    $sqlAdministratorLoginPassword = Read-Host "Enter SQL Server Password" #-assecurestring
    $workspaceName = $resourceGroupName.ToLower()+ $getDate+"ws"
    $defaultDataLakeStorageAccountName = $resourceGroupName.ToLower() + ((97..122) | Get-Random -Count 1 | % {[char]$_}) # "storage"+$getDate + ((65..90) + (97..122) | Get-Random -Count 1 | % {[char]$_})
    $defaultDataLakeStorageFilesystemName = $resourceGroupName.ToLower()+"ws"
    $DataFactoryName = $resourceGroupName.ToLower()+ $getDate+"adf"

New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

    # CREATE Storage
    $StorageParametersVariable =  @"
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "defaultDataLakeStorageAccountName": {
            "value": "$defaultDataLakeStorageAccountName"
        },
        "storageSKU": {
            "value": "Standard_RAGRS"
        },
        "workspaceName": {
            "value": "$workspaceName"
        }
    }
}
"@
    Set-Content ParametersStorage.json $StorageParametersVariable
    $StorageTemplateFilePath = "./deployStorage.json"
    $StorageTemplateParameterFilePath = "./ParametersStorage.json"
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $StorageTemplateFilePath -TemplateParameterFile $StorageTemplateParameterFilePath

    Start-Sleep -Seconds 10

    # CREATE Synapse Workspace and SQL Pool
    $SynapseWorkspaceParametersVariable = @"
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "name": {
            "value": "$workspaceName"
        },
        "location": {
            "value": "$location"
        },
        "defaultDataLakeStorageAccountName": {
            "value": "$defaultDataLakeStorageAccountName"
        },
        "defaultDataLakeStorageFilesystemName": {
            "value": "$defaultDataLakeStorageFilesystemName"
        },
        "sqlAdministratorLogin": {
            "value": "sqladminuser"
        },
        "sqlAdministratorLoginPassword": {
            "value": "$sqlAdministratorLoginPassword"
        },
        "setWorkspaceIdentityRbacOnStorageAccount": {
            "value": true
        },
        "allowAllConnections": {
            "value": true
        },
        "grantWorkspaceIdentityControlForSql": {
            "value": "Enabled"
        },
        "managedVirtualNetwork": {
            "value": ""
        },
        "tagValues": {
            "value": {}
        },
        "storageSubscriptionID": {
            "value": ""
        },
        "storageResourceGroupName": {
            "value": ""
        },
        "storageLocation": {
            "value": ""
        },
        "storageRoleUniqueId": {
            "value": ""
        },
        "adlaResourceId": {
            "value": ""
        },
        "storageAccessTier": {
            "value": "Hot"
        },
        "storageKind": {
            "value": "StorageV2"
        },
        "storageAccountType": {
            "value": "Standard_RAGRS"
        },
        "storageSupportsHttpsTrafficOnly": {
            "value": true
        },
        "storageKind": {
            "value": "StorageV2"
        },
        "storageIsHnsEnabled": {
            "value": true
        },
        "userObjectId": {
            "value": "$principalId"
        },
        "setSbdcRbacOnStorageAccount": {
            "value": true
        }
    }
}
"@
    Set-Content ParametersSynapseWorkspace.json $SynapseWorkspaceParametersVariable
    $SynapseTemplateFilePath = "./deploySynapseWorkspace.json"
    $SynapseTemplateParameterFilePath = "./ParametersSynapseWorkspace.json"
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $SynapseTemplateFilePath -TemplateParameterFile $SynapseTemplateParameterFilePath

    # CREATE ADF
    Set-AzDataFactoryV2 -ResourceGroupName $resourcegroupname -Name $DataFactoryName -Location $location -Force
}

    Start-Sleep -Seconds 20

    # CREATE SQL Pool
    $SQLPoolParametersVariable = @"
 {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
       "name": {
           "value": "$workspaceName"
       },
       "location": {
           "value": "$location"
       },
       "sqlpoolName": {
           "value": "sqlpool1"
       },
       "sku": {
           "Value":"DW100c"
       }
    }
}
"@
    Set-Content ParametersSQLPool.json $SQLPoolParametersVariable
    $SQLPoolTemplateFilePath = "./deploySqlPool.json"
    $SQLPoolTemplateParameterFilePath = "./ParametersSQLPool.json"
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $SQLPoolTemplateFilePath -TemplateParameterFile $SQLPoolTemplateParameterFilePath

    # CREATE FUNCTIONS
    Function Get-StorageKey {
  
        Write-Host  "Getting Storage Access Key"
    
        $script:storageKey1 = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $defaultDataLakeStorageAccountName -ListKerbKey)[0].Value
    
        Write-Host $script:storageKey1
    }
    
    Function Get-ConnectionString {
        
        Write-Host  "Getting Connection String for the Synapse Pool"
    
    #    $script:SQLPoolconnectionString = "data source="+$servername+".database.windows.net;Initial Catalog="+$database+";Encrypt=True;Connection Timeout=30;"
        $script:SQLPoolconnectionString = "data source="+$workspaceName+".sql.azuresynapse.net;Initial Catalog=sqlpool1;Persist Security Info=False;User ID=sqladminuser;Password="+$sqlAdministratorLoginPassword+";MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

        Write-Host $script:SQLPoolconnectionString
    }
    
    Function Set-ParametersFile {

        Write-Host  "Creating Parameters File for the Synapse Integrate ARM Template"
    
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
            "value": "https://$defaultDataLakeStorageAccountName.dfs.core.windows.net/"
        }
    }
}
"@
        Set-Content ParametersARMTemplate.json $MyJsonVariable
    }
    
    Function Set-DeployADFARMTemplate {

        Write-Host  "Deploying ADF ARM Template with the new Parameters File"
    
        $templateFile = "$path/deployARMTemplate.json"
        $parameterFile="$path/ParametersARMTemplate.json"
        New-AzResourceGroupDeployment `
        -Name $DataFactoryName `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $parameterFile
    }
    
    Function Get-CMSData {

        Write-Host "Downloading CMS data from website and saving into ADLS"
    
        Write-Host "Updating IntegrationRuntime TTL to 10 minutes and CoreCount to 16"
        Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -Name 'AutoResolveIntegrationRuntime' -DataFlowTimeToLive 10 -Type 'Managed' -Location 'AutoResolve' -DataFlowCoreCount 16 -DataFlowComputeType 'General' -ErrorAction SilentlyContinue -Force
    
        $TablesList2 = @("Download_CMSPart13","Download_CMSPart14","Download_CMSPart15","Download_CMSPart16","Download_CMSPart17","Download_CMSPart18")
        $myarray2 = [System.Collections.ArrayList]::new()
    
        Foreach ($i in $TablesList2)
        {
            Write-Host "Loading Table: $i"
            $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName $i
            $myArray2.Add($runId)
        }
    #    foreach ($element in $myArray1) {$element}
        foreach ($element in $myArray2) {
            while ($True) {
    
                $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $element
    
                if ($run) {
                    if ($run.Status -ne 'InProgress') {
                        Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Green"
                        $run
                        break
                    }
                    Write-Host  "ADF Pipeline is still running... Will check progress in 15 seconds" -foregroundcolor "Yellow"
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
                Write-Host  "ADF Pipeline is still running... Will check progress in 15 seconds" -foregroundcolor "Yellow"
            }
    
            Start-Sleep -Seconds 15
        }
        
        Write-Host "All CMS files needed for the demo saved in the Storage Account: $storageName"
    
    }
    Function Set-SynapseDDLs {
    
        Write-Host  "Creating Tables and Views in Synapse"
    
        $synapseSqlName = $workspaceName+".sql.azuresynapse.net"
        Invoke-Sqlcmd -InputFile "$path/synapseCMSddls.sql" -ServerInstance $synapseSqlName -Database "sqlpool1" -Username "sqladminuser" -Password $sqlAdministratorLoginPassword
    }
    
    Function Set-LoadSynapseTables {
    
        Write-Host "Executing ADF Pipelines that loades into Synapse the CMS Data from Storage "
    
        Write-Host "Updating IntegrationRuntime TTL to 10 minutes and CoreCount to 16"
        Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -Name 'AutoResolveIntegrationRuntime' -DataFlowTimeToLive 10 -Type 'Managed' -Location 'AutoResolve' -DataFlowCoreCount 16 -DataFlowComputeType 'General' -ErrorAction SilentlyContinue -Force
    
        $TablesList1 = @("Drug","Providers","Specialty","States")
        $myarray1 = [System.Collections.ArrayList]::new()
    
        Foreach ($i in $TablesList1)
        {
            Write-Host "Loading Table: $i"
            $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineName $i
            $myArray1.Add($runId)
        }
    #    foreach ($element in $myArray1) {$element}
        foreach ($element in $myArray1) {
            while ($True) {
    
                $run = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $element
    
                if ($run) {
                    if ($run.Status -ne 'InProgress') {
                        Write-Host "Pipeline run finished. The status is: " $run.Status -foregroundcolor "Green"
                        $run
                        break
                    }
                    Write-Host  "ADF Pipeline is still running... Will check progress in 60 seconds" -foregroundcolor "Yellow"
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
                    Write-Host  "ADF Pipeline is still running... Will check progress in 60 seconds" -foregroundcolor "Yellow"
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
                    Write-Host  "ADF Pipeline is still running... Will check progress in 5 minutes" -foregroundcolor "Yellow"
                }
    
            Start-Sleep -Seconds 300
            }
        }
    
        Write-Host "All Tables loaded to Synapse Instance: $database"
    }

    # Call Functions
    Get-StorageKey
    Get-ConnectionString
    Set-ParametersFile
    Set-DeployADFARMTemplate
    Get-CMSData
    Set-SynapseDDLs
    Set-LoadSynapseTables
#    Set-ScaleDownSynapse

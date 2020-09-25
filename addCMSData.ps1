

$path = Get-Location

Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_13.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_13.zip
Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_14.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_14.zip
Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_15.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_15.zip
Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_16.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_16.zip
Invoke-WebRequest http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_17.zip -OutFile $path/PartD_Prescriber_PUF_NPI_DRUG_17.zip

Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_13.zip" -DestinationPath $path -Verbose
Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_14.zip" -DestinationPath $path -Verbose
Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_15.zip" -DestinationPath $path -Verbose
Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_16.zip" -DestinationPath $path -Verbose
Expand-Archive -Path "$path/PartD_Prescriber_PUF_NPI_DRUG_17.zip" -DestinationPath $path -Verbose

Add-Type -Assembly "System.IO.Compression.FileSystem" [System.IO.Compression.ZipFile]::ExtractToDirectory(/mnt/c/Users/kuja/source/repos/E2ESynapseDemo/E2ESynapseDemo/PartD_Prescriber_PUF_NPI_DRUG_13.zip , '/mnt/c/Users/kuja/source/repos/E2ESynapseDemo')

./azcopy copy $path/PartD_Prescriber_PUF_NPI_DRUG_*.txt https://cmsdemostorage.blob.core.windows.net/cms-part-d-prescriber

$shell_app = new-object -com shell.application
$filename = "PartD_Prescriber_PUF_NPI_DRUG_13.zip"
$zip_file = $shell_app.namespace((Get-Location).Path + "\$filename")
$destination = $shell_app.namespace((Get-Location).Path)
$destination.Copyhere($zip_file.items())


$resourceGroupName = Read-Host "Enter Resource Group Name"
$servername = $resourceGroupName.ToLower()+"server"
$database = $resourceGroupName.ToLower()+"pool"
$adfName = $resourceGroupName.ToLower()+"adf"
$storageName = $resourceGroupName.ToLower()+"storage"
$location = "westus2"
$adminlogin = $servername+"admin"
$path = Get-Location
$ContainerName = "cms-part-d-prescriber"

$context = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageName).context
$StartTime = Get-Date
$EndTime = $startTime.AddHours(10.0)
$sasToken = New-AzStorageAccountSASToken -Context $context -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup -StartTime $StartTime -ExpiryTime $EndTime
./azcopy copy "$path/PartD_Prescriber_PUF_NPI_Drug_13.txt" "https://$storageName.blob.core.windows.net/$ContainerName/$sasToken" --recursive=true

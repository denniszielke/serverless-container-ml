
RESOURCE_GROUP="serverless-ml"
LOCATION="Northeurope"
CONTAINERAPPS_ENVIRONMENT=""
LOG_ANALYTICS_WORKSPACE=""
AZURE_STORAGE_ACCOUNT="dserverless1"
STORAGE_ACCOUNT_QUEUE="requests"
STORAGE_ACCOUNT_CONTAINER="details"

az group create --name $RESOURCE_GROUP --location "$LOCATION"

az storage account create --name $AZURE_STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location "$LOCATION" --sku Standard_RAGRS --kind StorageV2


AZURE_STORAGE_KEY=(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $AZURE_STORAGE_ACCOUNT --query '[0].value' --out tsv)
echo $AZURE_STORAGE_KEY

az storage queue create -n $STORAGE_ACCOUNT_QUEUE --fail-on-exist --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY


az storage container create -n $STORAGE_ACCOUNT_CONTAINER --fail-on-exist --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY

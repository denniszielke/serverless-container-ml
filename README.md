# serverless-container-ml

## deployment guid

```

DEPLOYMENT_NAME="dzmlserverless" # here the deployment
RESOURCE_GROUP=$DEPLOYMENT_NAME # here enter the resources group
LOCATION="northeurope" # azure region can only be canadacentral or northeurope
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv) # here enter your subscription id
GHUSER="denniszielke" # replace with your user name
GHREPO="serverless-container-ml" # here the repo name
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
GHREPO_BRANCH=":ref:refs/heads/main"
az group create -n $RESOURCE_GROUP -l $LOCATION -o none

AZURE_CLIENT_ID=$(az ad sp create-for-rbac --name "$DEPLOYMENT_NAME" --role contributor --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" -o json | jq -r '.appId')

AZURE_CLIENT_OBJECT_ID="$(az ad app show --id ${AZURE_CLIENT_ID} --query objectId -otsv)"

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$AZURE_CLIENT_OBJECT_ID/federatedIdentityCredentials" --body "{'name':'$DEPLOYMENT_NAME','issuer':'https://token.actions.githubusercontent.com','subject':'repo:$GHUSER/$GHREPO$GHREPO_BRANCH','description':'GitHub Actions for $DEPLOYMENT_NAME','audiences':['api://AzureADTokenExchange']}"

echo $AZURE_CLIENT_ID

echo $AZURE_TENANT_ID

echo $AZURE_SUBSCRIPTION_ID

echo $RESOURCE_GROUP

```
# serverless-container-ml

This sample is taken from https://techcommunity.microsoft.com/t5/apps-on-azure-blog/azure-container-apps-dapr-binding-example/ba-p/3045890

![](/python.png)


## Deploy Azure resources

```
PROJECT_NAME="dzopt5"
LOCATION="westeurope"

bash ./deploy-infra.sh $PROJECT_NAME $LOCATION

```

## Deploy Apps into Container Apps

```
PROJECT_NAME="dzopt5"
GITHUB_REPO_OWNER="denniszielke"
IMAGE_TAG="main"

bash ./deploy-apps.sh $PROJECT_NAME $GITHUB_REPO_OWNER $IMAGE_TAG

```

## Create test data

```
export AZURE_STORAGE_CONNECTION_STRING=""

MESSAGE=$(echo -n "hello from azure cli" | base64)

az storage message put --content $MESSAGE -q requests

for i in {1..300}; do for i in {1..300}; az storage message put --content $MESSAGE -q requests; done
```

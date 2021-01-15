
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService

# Install the aks-preview extension
az extension add --name aks-preview

# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview
az group create --name nzaplakspodid-rg --location eastus

az network vnet create -g nzaplakspodid-rg -n nzaplakspodid-vnet --address-prefixes 192.168.0.0/16 --subnet-name aks-subnet --subnet-prefix 192.168.1.0/24

VNET_ID=$(az network vnet show --resource-group nzaplakspodid-rg --name nzaplakspodid-vnet --query id -o tsv)
SUBNET_ID=$(az network vnet subnet show --resource-group nzaplakspodid-rg --vnet-name nzaplakspodid-vnet --name aks-subnet --query id -o tsv)

az aks create \
    --resource-group nzaplakspodid-rg \
    --name nzaplakspodid-cluster \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --generate-ssh-keys --enable-managed-identity --enable-pod-identity

az aks get-credentials --resource-group nzaplakspodid-rg --name nzaplakspodid-cluster


IDENTITY_NAME="aks-pod-id"
az identity create --resource-group nzaplakspodid-rg --name $IDENTITY_NAME
IDENTITY_CLIENT_ID="$(az identity show -g nzaplakspodid-rg -n $IDENTITY_NAME --query clientId -otsv)"
IDENTITY_RESOURCE_ID="$(az identity show -g nzaplakspodid-rg -n $IDENTITY_NAME --query id -otsv)"

POD_IDENTITY_NAME="app-pod-id"
POD_IDENTITY_NAMESPACE="my-app"
az aks pod-identity add --resource-group nzaplakspodid-rg --cluster-name nzaplakspodid-cluster --namespace $POD_IDENTITY_NAMESPACE  --name $POD_IDENTITY_NAME --identity-resource-id $IDENTITY_RESOURCE_ID

IDENTITY_RESOURCE_GROUP="nzaplakspodid-rg"

az aks show -g nzaplakspodid-rg -n nzaplakspodid-cluster --query "identity"

kubectl apply -f demo.yaml --namespace $POD_IDENTITY_NAMESPACE



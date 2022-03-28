##register required registries for ARO

az account set --subscription $1



az provider register -n Microsoft.RedHatOpenShift --wait

az provider register -n Microsoft.Compute --wait

az provider register -n Microsoft.Storage --wait

az provider register -n Microsoft.Authorization --wait


##Declare variables
$LOCATION = 'eastus'                 # the location of your cluster
$RESOURCEGROUP = 'aro-cli-rg'            # the name of the resource group where you want to create your cluster
$CLUSTER = 'aro-cluster'                 # the name of your cluster

##create Resource Group
az group create --name $RESOURCEGROUP --location $LOCATION

##Create VNet
az network vnet create --resource-group $RESOURCEGROUP --name aro-vnet --address-prefixes 10.0.0.0/22

##create empty submet for master node
az network vnet subnet create --resource-group $RESOURCEGROUP --vnet-name aro-vnet --name master-subnet --address-prefixes 10.0.0.0/23 --service-endpoints Microsoft.ContainerRegistry

##create empty submet for worker node
az network vnet subnet create --resource-group $RESOURCEGROUP --vnet-name aro-vnet --name worker-subnet --address-prefixes 10.0.2.0/23 --service-endpoints Microsoft.ContainerRegistry

##Disable pribate link service enpoint for master subnet
az network vnet subnet update --name master-subnet --resource-group $RESOURCEGROUP --vnet-name aro-vnet --disable-private-link-service-network-policies true


##Create ARO cluster using pull-scret.txt file containing credentials
az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet aro-vnet --master-subnet master-subnet --worker-subnet worker-subnet  #--pull-sceret @pull-secret.txt

$clusterCredentials = az aro list-credentials --name $CLUSTER --resource-group $RESOURCEGROUP | ConvertFrom-Json
$adminuser = $($clusterCredentials.kubeadminUsername)
$adminpass = $($clusterCredentials.kubeadminPassword)

$clusterurl = $(az aro show --name $CLUSTER --resource-group $RESOURCEGROUP --query "consoleProfile.url" -o tsv)


$apiServer=$(az aro show -g $RESOURCEGROUP -n $CLUSTER --query apiserverProfile.url -o tsv)

Write-Output $clusterurl
Write-Output $adminuser
Write-Output $adminpass
Write-Output $apiServer

oc login $apiServer --username=$adminuser --password=$adminpass
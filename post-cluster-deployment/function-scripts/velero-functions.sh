#!/bin/bash

###################
# List of functions
###################

# Authenticate with Service Principal
auth_with_sp () {
    local tenant_id=$1
    local subscription_id=$2
    local client_id=$3
    local client_secret=$4

    printf "\n"
    echo "--------------------------------"
    echo "Service Principal Authentication"
    echo "--------------------------------"
    printf "\n"

    # export ARM_CLIENT_ID=$client_id
    # export ARM_CLIENT_SECRET=$client_secret
    # export ARM_SUBSCRIPTION_ID=$subscription_id
    # export ARM_TENANT_ID=$tenant_id

    # az login --identity

    az login --service-principal -u $client_id -p $client_secret --tenant $tenant_id

    az login --identity

    az account set --subscription $subscription_id
    echo $tenant_id
    echo $subscription_id
    echo $client_id
    echo $client_secret
}

# Create Storage Account
create_storage_account () {
    local storage_name=$1
    local resource_group=$2
    local region=$3

    printf "\n"
    echo "------------------------"
    echo "Creating Storage Account"
    echo "------------------------"
    printf "\n"

    az group create -n $resource_group --location $region

    az storage account create \
    --name $storage_name \
    --resource-group $resource_group \
    --location $region \
    --sku Standard_GRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot
}

create_storage_container () {
    local container_name=$1
    local storage_name=$2
    # az storage container create -n $container_name --account-name $storage_name

    az storage container create -n $container_name --public-access off --account-name $storage_name
}

create_velero_credentials_file () {
    local subscription_id=$1
    local tenant_id=$2
    local client_id=$3
    local client_secret=$4
    local resource_group=$5

cat > credentials-velero.yaml<< EOF
AZURE_SUBSCRIPTION_ID=${subscription_id}
AZURE_TENANT_ID=${tenant_id}
AZURE_CLIENT_ID=${client_id}
AZURE_CLIENT_SECRET=${client_secret}
AZURE_RESOURCE_GROUP=${resource_group}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF
}

install_velero_backup_for_cluster () {
    local region=$1
    local tenant_id=$2
    local subscription_id=$3
    local resource_group=$4
    local client_id=$5
    local client_secret=$6
    local storage_name=$7
    local container_name=$8

    # echo $region
    # echo $tenant_id
    # echo $subscription_id
    # echo $resource_group
    # echo $client_id
    # echo $client_secret
    # echo $storage_name
    # echo $container_name

    # auth_with_sp $tenant_id $subscription_id $client_id $client_secret

    # create_storage_account $storage_name $resource_group $region

    # create_storage_container $container_name $storage_name

    # create_velero_credentials_file $subscription_id $tenant_id $client_id $client_secret $resource_group

    # velero install --provider azure --plugins velero/velero-plugin-for-microsoft-azure:v1.1.0 \
    # --bucket $container_name \
    # --secret-file .\credentials-velero.yaml 
    # --backup-location-config resourceGroup=$resource_group,storageAccount=$storage_name \
    # --snapshot-location-config apiTimeout=15m \
    # --velero-pod-cpu-limit="0" \
    # --velero-pod-mem-limit="0" \
    # --velero-pod-mem-request="0" \
    # --velero-pod-cpu-request="0"
}
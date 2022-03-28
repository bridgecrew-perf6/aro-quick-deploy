#!/bin/bash

region=eastus
tenant_id=$1
subscription_id=$2
resource_group=aro-cli-rg
aro_cluster=aro-cluster
custom_domain=null
client_id=$3
client_secret=$4
storage_name=velerobackupstorage01
container_name=velerobackupcontainer

source ./function-scripts/aad-functions.sh

source ./function-scripts/velero-functions.sh

# az role assignment create --assignee $client_id --role Contributor --scope /

auth_with_sp $tenant_id $subscription_id $client_id $client_secret


delete_file_if_exist credentials-velero.yaml

install_velero_backup_for_cluster $region $tenant_id $subscription_id $resource_group $client_id $client_secret $storage_name $container_name

delete_file_if_exist credentials-velero.yaml

# printf "\n"
# echo "--######################################--"
# printf "\n"
# echo "AAD AUTHENTICATION CONFIGURATION FOR CLUSTER"
# printf "\n"
# echo "--######################################--"

delete_file_if_exist oidc.yaml

enable_AAD_auth_for_cluster $tenant_id $resource_group $aro_cluster $custom_domain $client_id $client_secret

delete_file_if_exist oidc.yaml


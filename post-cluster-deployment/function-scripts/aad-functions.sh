#!/bin/bash

###################
# List of functions
###################


create_oidc_file () {
  local app_id=$1
  local client_secret=$2
  local tenant_id=$3

cat > oidc.yaml<< EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: AAD
    mappingMethod: claim
    type: OpenID
    openID:
      clientID: $app_id
      clientSecret:
        name: openid-client-secret-azuread
      extraScopes:
      - email
      - profile
      extraAuthorizeParameters:
        include_granted_scopes: "true"
      claims:
        preferredUsername:
        - email
        - upn
        name:
        - name
        email:
        - email
      issuer: https://login.microsoftonline.com/$tenant_id
EOF
}


# Create openid client secret for Azure AD
create_openid_client_secret_azuread () {
  local aro_cluster=$1
  local resource_group=$2
  local apiServer=$3
  local tenant_id=$4
  local client_secret=$5

  printf "\n"
  echo "--------------------------------"
  echo "Openid Client Configuration"
  echo "--------------------------------"
  printf "\n"

  kubeadmin_password=$(az aro list-credentials \
    --name $aro_cluster \
    --resource-group $resource_group \
    --query kubeadminPassword --output tsv)


  oc login $apiServer -u kubeadmin -p $kubeadmin_password


  oc create secret generic openid-client-secret-azuread \
    --namespace openshift-config \
    --from-literal=clientSecret=$client_secret

  oc apply -f oidc.yaml
}


# Set Active Directory app permission
set_add_permission () {
  local oauthCallbackURL=$1
  local app_id=$2
  local client_secret=$3
  local resource_group=$4
  local aro_cluster=$5
  local apiServer=$6
  local tenant_id=$7

  printf "\n"
  echo "--------------------------------"
  echo "Configuring AAD App Registration"
  echo "--------------------------------"
  printf "\n"

  if [ $app_id == null ] || [ $client_secret == null ] ;then
    echo "Creating new AAD App Registration"
    client_secret="xr37Q~C4Qo6tbYB8RdsLAYJBGuQ8CiGIsv1Na"

    app_id=$(az ad app create \
      --query appId -o tsv \
      --display-name aro-auth-new \
      --reply-urls $oauthCallbackURL \
      --password $client_secret)

    az ad app update \
      --set optionalClaims.idToken=@config-files/manifest.json \
      --id $app_id
  else
    echo "Using existing AAD App Registration"
    az ad app update \
    --reply-urls $oauthCallbackURL \
    --set optionalClaims.idToken=@config-files/manifest.json \
    --id $app_id
  fi

  az ad app permission add \
  --api 00000002-0000-0000-c000-000000000000 \
  --api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope \
  --id $app_id 

  az ad app permission grant --id $app_id --api 00000002-0000-0000-c000-000000000000

  create_oidc_file $app_id $client_secret $tenant_id

  create_openid_client_secret_azuread $aro_cluster $resource_group $apiServer $tenant_id $client_secret
}


# Primary function
enable_AAD_auth_for_cluster () {
  local tenant_id=$1
  local resource_group=$2
  local aro_cluster=$3
  local custom_domain=$4
  local app_id=$5
  local client_secret=$6
  
  printf "\n"
  echo "-------------------------"
  echo "Gathering Cluster Details"
  echo "-------------------------"
  printf "\n"

  domain=$(az aro show -g $resource_group -n $aro_cluster --query clusterProfile.domain -o tsv)
  location=$(az aro show -g $resource_group -n $aro_cluster --query location -o tsv)
  apiServer=$(az aro show -g $resource_group -n $aro_cluster --query apiserverProfile.url -o tsv)

  if [ $custom_domain == null ];then
    oauthCallbackURL="https://oauth-openshift.apps.$domain.$location.aroapp.io/oauth2callback/AAD"
  else
    oauthCallbackURL="https://oauth-openshift.apps.$domain/oauth2callback/AAD"
  fi

  echo $($oauthCallbackURL $apiServer)

  set_add_permission $oauthCallbackURL $app_id $client_secret $resource_group $aro_cluster $apiServer $tenant_id
}


delete_file_if_exist () {
  file=$1

  if [ -f "$file" ] ; then
      rm -rf "$file"
  fi
}
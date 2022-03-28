terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.95.0"
    }
    random = {
      version = ">=3.0"
    }
  }

}

provider "azurerm" {
  features {}
}

data azurerm_subscription "current" {}
data azuread_client_config "current" {}

resource "azuread_application" "aro" {
  display_name = "aroClusterADapp"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "aro" {
  application_id               = azuread_application.aro.application_id
  owners                       = [data.azuread_client_config.current.object_id]
  depends_on = [
    azuread_application.aro
  ]
}

resource "azuread_service_principal_password" "aro" {
  service_principal_id = azuread_service_principal.aro.object_id
  depends_on = [
    azuread_service_principal.aro
  ]
}

resource "azurerm_role_assignment" "sp_assignment" {
  scope			= data.azurerm_subscription.current.id
  role_definition_name	= "Contributor"
  principal_id		= azuread_service_principal.aro.object_id
}

# resource "azurerm_container_registry" "acr" {
#   name                = "voyacontainerregistry1"
#   resource_group_name = azurerm_resource_group.resource_group.name
#   location            = azurerm_resource_group.resource_group.location
#   sku                 = "Basic"
#   admin_enabled       = true
# }

resource "azurerm_storage_account" "backup_storage" {
  name                     = "arovoyabackupstorage01"
  resource_group_name      = var.resource_group
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "BlobStorage"
}

resource "azurerm_storage_container" "blob_container" {
  name                  = "velerocontainer001"
  storage_account_name  = azurerm_storage_account.backup_storage.name
  container_access_type = "private"

  depends_on		= [
    azurerm_storage_account.backup_storage
  ]
}

resource "null_resource" "velero_install" {
  provisioner "local-exec" {
    command = "./velero-installation.ps1"
    interpreter = ["PowerShell", "-Command"]
    environment = {
      AZURE_SUBSCRIPTION_ID = var.subscription_id
      AZURE_TENANT_ID = var.tenant_id
      AZURE_CLIENT_ID = azuread_application.aro.application_id
      AZURE_CLIENT_SECRET = nonsensitive(azuread_service_principal_password.aro.value)
      AZURE_RESOURCE_GROUP = var.resource_group
      AZURE_CLOUD_NAME = "AzurePublicCloud"
      STORAGE_ID = azurerm_storage_account.backup_storage.id
      CLUSTER_NAME = var.cluster_name
      BLOB_CONTAINER = azurerm_storage_container.blob_container.name
    #   CONTAINER_REGISTRY = azurerm_container_registry.acr.name
    }
  }
}
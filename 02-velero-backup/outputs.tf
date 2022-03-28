output "StorageAccount" {
  value = azurerm_storage_account.backup_storage.name
}

output "BlobContainer" {
  value = azurerm_storage_container.blob_container.name
}
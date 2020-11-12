data "azurerm_subnet" "appsubnet" {
  name                 = "subnet-n-nonprod-vmss02-10.208.253.64-26"
  virtual_network_name = "vnet-sg01-sea-n-nonprodsrv01"
  resource_group_name  = "rg-sg01-sea-n-nonprodsrv01-network01"
}

data "azurerm_shared_image" "example" {
  name                = "Redhat7"
  gallery_name        = "SharedimagegalleryGO"
  resource_group_name = "rg-go01-eas-p-sharedimage"
}

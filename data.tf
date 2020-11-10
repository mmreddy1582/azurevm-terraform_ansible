data "azurerm_subnet" "appsubnet" {
  name                 = "subnet-n-nonprod-vmss02-10.208.253.64-26"
  virtual_network_name = "vnet-sg01-sea-n-nonprodsrv01"
  resource_group_name  = "rg-sg01-sea-n-nonprodsrv01-network01"
}

data "azurerm_image" "redhat" {
  name                = "img-sg01-sea-rhel78-1.0.9"
  resource_group_name = "rg-sg01-sea-p-vmimages-redhat01"

}
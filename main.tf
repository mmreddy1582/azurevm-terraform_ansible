provider "azurerm" {
  version = "=2.20.0" 
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "vmsspocimage-rg"
  location = "Southeast Asia"
}

module "linuxservers" {
  source                        = "./terraform-azurerm-compute"
  resource_group_name           = azurerm_resource_group.example.name
  vm_hostname                   = "muravmssimagevm1"
  nb_public_ip                  = 0
  remote_port                   = "22"
  nb_instances                  = 1
  vm_os_id                      = data.azurerm_image.redhat.id
  vm_os_publisher               = "RedHat"
  vm_os_offer                   = "RHEL"
  vm_os_sku                     = "7.8"
  vnet_subnet_id                = data.azurerm_subnet.appsubnet.id
  boot_diagnostics              = false
  delete_os_disk_on_termination = false
  nb_data_disk                  = 1
  data_disk_size_gb             = 64
  data_sa_type                  = "Premium_LRS"
  enable_ssh_key                = true
  vm_size                       = "Standard_D4s_v3"
  
  tags = {
    environment = "poc"
    costcenter  = "testpoc"
    application = "testpoc"
    owner       = "Mura"
  }

  enable_accelerated_networking = true
}

output "linux_vm_private_ips" {
  value = module.linuxservers.network_interface_private_ip
}


output "linux_vm_hostname" {
  value = module.linuxservers.vm_hostname
}


module "os" {
  source       = "./os"
  vm_os_simple = var.vm_os_simple
}

data "azurerm_resource_group" "vm" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "vm-sa" {
  count                    = var.boot_diagnostics ? 1 : 0
  name                     = "bootdiag${var.vm_hostname}"
  resource_group_name      = data.azurerm_resource_group.vm.name
  location                 = coalesce(var.location, data.azurerm_resource_group.vm.location)
  account_tier             = element(split("_", var.boot_diagnostics_sa_type), 0)
  account_replication_type = element(split("_", var.boot_diagnostics_sa_type), 1)
  tags                     = var.tags
}

resource "azurerm_virtual_machine" "vm-linux" {
  name                          = var.vm_hostname
  resource_group_name           = data.azurerm_resource_group.vm.name
  location                      = coalesce(var.location, data.azurerm_resource_group.vm.location)
  availability_set_id           = azurerm_availability_set.vm.id
  vm_size                       = var.vm_size
  network_interface_ids         = azurerm_network_interface.vm.*.id
  delete_os_disk_on_termination = var.delete_os_disk_on_termination

  dynamic identity {
    for_each = length(var.identity_ids) == 0 && var.identity_type == "SystemAssigned" ? [var.identity_type] : []
    content {
      type = var.identity_type
    }
  }

  dynamic identity {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "UserAssigned" ? [var.identity_type] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : []
    }
  }

  storage_image_reference {
    id        = var.vm_os_id
    publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher) : ""
    offer     = var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os.calculated_value_os_offer) : ""
    sku       = var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os.calculated_value_os_sku) : ""
    version   = var.vm_os_id == "" ? var.vm_os_version : ""
  }

  storage_os_disk {
    name              = "osdisk-${var.vm_hostname}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = var.storage_account_type
  }

  dynamic storage_data_disk {
    for_each = range(var.nb_data_disk)
    content {
      name              = "${var.vm_hostname}-datadisk-${storage_data_disk.value}"
      create_option     = "Empty"
      lun               = storage_data_disk.value
      disk_size_gb      = var.data_disk_size_gb
      managed_disk_type = var.data_sa_type
    }
  }

  os_profile {
    computer_name  = var.vm_hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = var.custom_data
  }

  os_profile_linux_config {
    disable_password_authentication = var.enable_ssh_key

    dynamic ssh_keys {
      for_each = var.enable_ssh_key ? [var.ssh_key] : []
      content {
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
        key_data = file(var.ssh_key)
      }
    }
  }

  tags = var.tags

  boot_diagnostics {
    enabled     = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint) : ""
  }

  provisioner "remote-exec" {
    inline = [
    ]
    connection {
      agent       = false 
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.ssh_privatekey)
      host        = azurerm_network_interface.vm.private_ip_address
    }
  }
  
  provisioner "local-exec" {
     command = "ansible-playbook -i '${azurerm_network_interface.vm.private_ip_address},' -u ${var.admin_username} --private-key ${var.ssh_privatekey} ansible-playbook.yml"
  }

}

resource "azurerm_availability_set" "vm" {
  name                         = "${var.vm_hostname}-avset"
  resource_group_name          = data.azurerm_resource_group.vm.name
  location                     = coalesce(var.location, data.azurerm_resource_group.vm.location)
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = var.tags
}

resource "azurerm_network_interface" "vm" {
  name                          = "${var.vm_hostname}-nic"
  resource_group_name           = data.azurerm_resource_group.vm.name
  location                      = coalesce(var.location, data.azurerm_resource_group.vm.location)
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "${var.vm_hostname}-ip"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = var.private_ip_allocation_method
    private_ip_address            = var.vm_ipaddress
     }
  
  tags                            = var.tags
}

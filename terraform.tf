terraform {
    backend "azurerm" {
        resource_group_name  = "vmssremotepoc-rg1"
        storage_account_name = "vmsstfremotestorage"
        container_name       = "vmtfstate"
        key                  = "vmsspocimage-rg.tfstate"
    }
}

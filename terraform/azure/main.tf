# terraform {
#   required_providers {
#     azurerm = {
#       source = "hashicorp/azurerm"
#     }
#   }
# }

provider "azurerm" {
  features {}
}

# TODO: Move the variables in a separate file
variable "vm_count" {
  description = "Number of VMs to create"
  default     = 1
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-alex-tf"
  location = "West Europe"

  tags = {
    "Environment Type"  = "Test"
    "Owner or Customer" = "Alex,for DevOps POC"
    "Review Date"       = "March 2024"
  }
}

data "azurerm_virtual_network" "existing_vnet" {
  name                = "Test-Azure-WestEurope"
  resource_group_name = "Test-Azure-WestEurope-RG"
}

data "azurerm_subnet" "existing_subnet" {
  name                 = "Front-End"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_virtual_network.existing_vnet.resource_group_name
}

locals {
  vm_identifiers = { for i in range(var.vm_count) : "vm${i}" => i }
}

# Virtual Network and Subnet

resource "azurerm_virtual_network" "devops_vnet" { 
  name = "devops-vnet" 
  address_space = [ "10.0.0.0/16" ] 
  location = "westeurope" 
  resource_group_name = azurerm_resource_group.rg.name 
} 

resource "azurerm_subnet" "devops_subnet" { 
  name = "devops_subnet" 
  resource_group_name = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.devops_vnet.name 
  address_prefixes = ["10.0.1.0/24"] 
}

# Public IP

resource "azurerm_public_ip" "devops_publicip" { 
  name = "devops-publicip" 
  location = "westeurope" 
  resource_group_name = azurerm_resource_group.rg.name 
  allocation_method = "Dynamic" 
  sku = "Basic" 
}

# Network Interface

resource "azurerm_network_interface" "devops_nic" { 
  for_each = local.vm_identifiers
  name = "devops-nic-${each.value + 1}" 
  location = "westeurope" 
  resource_group_name = azurerm_resource_group.rg.name 

  ip_configuration { 
    name = "ipconfig1" 
    subnet_id = data.azurerm_subnet.existing_subnet.id 
    private_ip_address_allocation = "Dynamic" 
  }
}

resource "azurerm_windows_virtual_machine" "devops_poc_vm" {
  for_each = local.vm_identifiers
  name                  = "devops-poc-${each.value + 1}"
  location              = "westeurope"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.devops_nic[each.key].id]
  size                  = "Standard_B1ls"
  admin_username        = "adminuser"
  admin_password        = "Password123!"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
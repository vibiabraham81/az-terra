provider "azurerm" {
    version = 1.38
    }

# Create virtual network
resource "azurerm_virtual_network" "TFNet" {
    name                = "${var.vnet_name}"
    address_space       = ["${var.address_space}"]
    location            = "${var.location}"
    resource_group_name = "${var.resource_group}"

    tags = {
        environment = "Terraform VNET"
    }
}
# Create subnet
resource "azurerm_subnet" "tfsubnet" {
    name                 = "default"
    resource_group_name = "${var.resource_group}"
    virtual_network_name = azurerm_virtual_network.TFNet.name
    address_prefix       = "${var.address_prefix}"
}

#Deploy Public IP
resource "azurerm_public_ip" "example" {
  name                = "${var.public_ip}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
  allocation_method   = "${var.allocation_method}"
  sku                 = "${var.sku}"
}

#Create NIC
resource "azurerm_network_interface" "example" {
  name                = "${var.nic_name}"  
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"

    ip_configuration {
    name                          = "${var.ipconfig_name}"
    subnet_id                     = azurerm_subnet.tfsubnet.id 
    private_ip_address_allocation  = "${var.ip_allocation}"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

#Create Boot Diagnostic Account
resource "azurerm_storage_account" "sa" {
  name                     = "${var.diag_account}" 
  resource_group_name      = "${var.resource_group}"
  location                 = "${var.location}"
   account_tier            = "${var.account_tier}"
   account_replication_type = "${var.account_repln}"

   tags = {
    environment = "Boot Diagnostic Storage"
    CreatedBy = "Admin"
   }
  }

#Create Virtual Machine
resource "azurerm_virtual_machine" "example" {
  name                  = "${var.vm_name}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group}"
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "${var.vm_size}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${var.publisher}"
    offer     = "${var.offer}"
    sku       = "${var.vm_sku}"
    version   = "${var.vm_version}"
  }

  storage_os_disk {
    name              = "${var.stor_name}"
    disk_size_gb      = "${var.stor_size}"
    caching           = ""${var.caching}"
    create_option     = "${var.create_option}"
    managed_disk_type = "${var.disk_type}"
  }

  os_profile {
    computer_name  = "${var.comp_name}"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_pass}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.sa.primary_blob_endpoint
    }
}
}

resource "azurerm_resource_group" "zitmycheapvnet" {
  name     = var.azure_rg_name
  location = var.azure_location
  tags     = local.tags
}

#create virtual network

resource "azurerm_virtual_network" "mycheapvnet" {
  name                = var.virtual_network_name
  address_space       = ["10.255.196.0/22"]
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags

}

#create subnet 1 transfer

resource "azurerm_subnet" "mycheapvnettransfer" {
  name                 = var.virtual_subnet1-name
  resource_group_name  = azurerm_resource_group.zitmycheapvnet.name
  virtual_network_name = azurerm_virtual_network.mycheapvnet.name
  address_prefixes     = ["10.255.196.0/24"]

}

#create subnet 2 server

resource "azurerm_subnet" "mycheapvnetserver" {
  name                 = var.virtual_subnet2-name
  resource_group_name  = azurerm_resource_group.zitmycheapvnet.name
  virtual_network_name = azurerm_virtual_network.mycheapvnet.name
  address_prefixes     = ["10.255.197.0/24"]

}

# create route 10.0.0.0/8

resource "azurerm_route_table" "routetoOnPremServer" {

  name                = var.route_to_onPrem
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags

  route {
    name                   = "route1"
    address_prefix         = "10.0.0.0/8"
    next_hop_in_ip_address = "10.255.197.4"
    next_hop_type          = "VirtualAppliance"
  }

  route {
    name                   = "route2"
    address_prefix         = "192.168.0.0/16"
    next_hop_in_ip_address = "10.255.197.4"
    next_hop_type          = "VirtualAppliance"
  }

  route {
    name                   = "route3"
    address_prefix         = "172.16.0.0/12"
    next_hop_in_ip_address = "10.255.197.4"
    next_hop_type          = "VirtualAppliance"
  }

}



# associate route to subnet

resource "azurerm_subnet_route_table_association" "servervnettoOnPrem" {
  subnet_id      = azurerm_subnet.mycheapvnetserver.id
  route_table_id = azurerm_route_table.routetoOnPremServer.id
}

#create subnet 3 clients

resource "azurerm_subnet" "mycheapvnetclients" {
  name                 = var.virtual_subnet3-name
  resource_group_name  = azurerm_resource_group.zitmycheapvnet.name
  virtual_network_name = azurerm_virtual_network.mycheapvnet.name
  address_prefixes     = ["10.255.198.0/24"]

}





# Create Linux VM

# Subtask Create Network Interface transfer

resource "azurerm_network_interface" "zitnictransfer" {

  name                = var.network_nic_name_transfer
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags
  ip_configuration {
    name                          = "zitnic1config"
    subnet_id                     = azurerm_subnet.mycheapvnettransfer.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.255.196.4"
  }
}

resource "azurerm_network_interface" "zitnicserver" {

  name                = var.network_nic_name_server
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags
  ip_configuration {
    name                          = "zitnic2config"
    subnet_id                     = azurerm_subnet.mycheapvnetserver.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.255.197.4"
  }
}

resource "azurerm_network_interface" "zitnicclients" {

  name                = var.network_nic_name_clients
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags
  ip_configuration {
    name                          = "zitnic3config"
    subnet_id                     = azurerm_subnet.mycheapvnetclients.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Generate Random name

resource "random_id" "random_id" {
  keepers = {
    resource_group = azurerm_resource_group.zitmycheapvnet.name
  }
  byte_length = 8
}

resource "random_password" "random_password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
}

#Create storage account

resource "azurerm_storage_account" "zitsta" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name      = azurerm_resource_group.zitmycheapvnet.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# Generate Linux VM

resource "azurerm_linux_virtual_machine" "mycheapvnetgw" {

  name                            = "mycheapvnetgw"
  admin_username                  = "sysadmin"
  admin_password                  = var.linuxpw
  disable_password_authentication = false
  location                        = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name             = azurerm_resource_group.zitmycheapvnet.name
  network_interface_ids           = [azurerm_network_interface.zitnictransfer.id, azurerm_network_interface.zitnicserver.id]
  size                            = "Standard_B1s"
  tags                            = local.tags
  os_disk {
    name                 = "mycheapvnetdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.zitsta.primary_blob_endpoint
  }
  vtpm_enabled = true
}

# Linux Test machine


resource "azurerm_network_interface" "zitnicmytest" {

  name                = var.network_nic_name_mytest
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags
  ip_configuration {
    name                          = "zitnicmytestconfig"
    subnet_id                     = azurerm_subnet.mycheapvnetserver.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "mytest" {

  name                            = "mytest"
  admin_username                  = "sysadmin"
  admin_password                  = var.linuxpw
  disable_password_authentication = false
  location                        = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name             = azurerm_resource_group.zitmycheapvnet.name
  network_interface_ids           = [azurerm_network_interface.zitnicmytest.id]
  size                            = "Standard_B1s"
  tags                            = local.tags
  os_disk {
    name                 = "mytestdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.zitsta.primary_blob_endpoint
  }
  vtpm_enabled = true
}

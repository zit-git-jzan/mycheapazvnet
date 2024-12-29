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





# Create Linux VM GW

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

# Generate Linux VM GW

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

# Create Linux Test Machine (to coment out if not needed)
#
#
#resource "azurerm_network_interface" "zitnicmytest" {
#
#  name                = var.network_nic_name_mytest
#  location            = azurerm_resource_group.zitmycheapvnet.location
#  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
#  tags                = local.tags
#  ip_configuration {
#    name                          = "zitnicmytestconfig"
#    subnet_id                     = azurerm_subnet.mycheapvnetserver.id
#    private_ip_address_allocation = "Dynamic"
#  }
#}

#resource "azurerm_linux_virtual_machine" "mytest" {
#  name                            = "mytest"
#  admin_username                  = "sysadmin"
#  admin_password                  = var.linuxpw
#  disable_password_authentication = false
#  location                        = azurerm_resource_group.zitmycheapvnet.location
#  resource_group_name             = azurerm_resource_group.zitmycheapvnet.name
#  network_interface_ids           = [azurerm_network_interface.zitnicmytest.id]
#  size                            = "Standard_B1s"
#  tags                            = local.tags
#  os_disk {
#    name                 = "mytestdisk"
#    caching              = "ReadWrite"
#    storage_account_type = "Premium_LRS"
#  }
#  source_image_reference {
#    publisher = "debian"
#    offer     = "debian-12"
#    sku       = "12-gen2"
#    version   = "latest"
#  }
#  boot_diagnostics {
#    storage_account_uri = azurerm_storage_account.zitsta.primary_blob_endpoint
#  }
#  vtpm_enabled = true
#}


# Create Windows Server DC
#
#
resource "azurerm_network_interface" "zitnicazsrvdc02" {

  name                = var.network_nic_name_azsrvdc02
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags
  dns_servers         = ["192.168.128.10", "10.255.197.5"]
  ip_configuration {
    name                          = "zitnicazsrvdc02"
    subnet_id                     = azurerm_subnet.mycheapvnetserver.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.255.197.5"
  }
}

resource "azurerm_windows_virtual_machine" "zitazsrvdc02" {
  name                  = "azsrvdc02"
  admin_username        = "sysadmin"
  admin_password        = var.linuxpw
  location              = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name   = azurerm_resource_group.zitmycheapvnet.name
  network_interface_ids = [azurerm_network_interface.zitnicazsrvdc02.id]
  size                  = "Standard_B2s"
  tags                  = local.tags

  os_disk {
    name                 = "azsrvdc02disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.zitsta.primary_blob_endpoint
  }
  vtpm_enabled                      = true
  vm_agent_platform_updates_enabled = true
}


# Create Windows Server APP
#
#
resource "azurerm_network_interface" "zitnicazsrvapp01" {

  name                = var.network_nic_name_azsrvapp01
  location            = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
  tags                = local.tags
  dns_servers         = ["10.255.197.5", "192.168.128.10"]
  ip_configuration {
    name                          = "zitnicazsrvapp01"
    subnet_id                     = azurerm_subnet.mycheapvnetserver.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.255.197.6"
  }
}

resource "azurerm_windows_virtual_machine" "zitazsrvapp01" {
  name                  = "azsrvapp01"
  admin_username        = "sysadmin"
  admin_password        = var.linuxpw
  location              = azurerm_resource_group.zitmycheapvnet.location
  resource_group_name   = azurerm_resource_group.zitmycheapvnet.name
  network_interface_ids = [azurerm_network_interface.zitnicazsrvapp01.id]
  size                  = "Standard_B2ms"
  tags                  = local.tags

  os_disk {
    name                 = "azsrvapp01disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.zitsta.primary_blob_endpoint
  }
  vtpm_enabled                      = true
  vm_agent_platform_updates_enabled = true
}

# Create Linux Machine for Omnissa Tunnel
#
#
# Create public IP
#resource "azurerm_public_ip" "zitpubipazsrvtunnel01" {
#  name                = var.public_ip_name_azsrvtunnel01
#  location            = azurerm_resource_group.zitmycheapvnet.location
#  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
#  tags                = local.tags
#  allocation_method   = "Static"
#
#}


#resource "azurerm_network_interface" "zitnicazsrvtunnel01" {
#
#  name                = var.network_nic_name_azsrvtunnel01
#  location            = azurerm_resource_group.zitmycheapvnet.location
#  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
#  tags                = local.tags
#  ip_configuration {
#    name                          = "zitnicsrvtunnelconfig"
#    subnet_id                     = azurerm_subnet.mycheapvnetserver.id
#    private_ip_address_allocation = "Static"
#    private_ip_address            = "10.255.197.7"
#    public_ip_address_id          = azurerm_public_ip.zitpubipazsrvtunnel01.id
#  }
#}

#resource "azurerm_network_security_group" "zitsgazsrvtunnel01" {
#  name                = "zitsgazsrvtunnel01"
#  location            = azurerm_resource_group.zitmycheapvnet.location
#  resource_group_name = azurerm_resource_group.zitmycheapvnet.name
#  tags                = local.tags
#}

#resource "azurerm_network_security_rule" "zitazrrvtunnel01inbound" {
#  name                        = "TunnelInbound"
#  priority                    = 300
#  direction                   = "Inbound"
#  access                      = "Allow"
#  protocol                    = "Tcp"
#  source_port_range           = "*"
#  destination_port_range      = "8443"
#  source_address_prefix       = "*"
#  destination_address_prefix  = "*"
#  resource_group_name         = azurerm_resource_group.zitmycheapvnet.name
#  network_security_group_name = azurerm_network_security_group.zitsgazsrvtunnel01.name
#}

#resource "azurerm_network_interface_security_group_association" "zitazsrvtunnel01nsg" {
#  network_interface_id      = azurerm_network_interface.zitnicazsrvtunnel01.id
#  network_security_group_id = azurerm_network_security_group.zitsgazsrvtunnel01.id
#}

#resource "azurerm_linux_virtual_machine" "myazsrvtunnel01" {
#  name                            = "myazsrvtunnel01"
#  admin_username                  = "sysadmin"
#  admin_password                  = var.linuxpw
#  disable_password_authentication = false
#  location                        = azurerm_resource_group.zitmycheapvnet.location
#  resource_group_name             = azurerm_resource_group.zitmycheapvnet.name
#  network_interface_ids           = [azurerm_network_interface.zitnicazsrvtunnel01.id]
#  size                            = "Standard_B1s"
#  tags                            = local.tags
#  os_disk {
#    name                 = "myazsrvtunnel01disk"
#    caching              = "ReadWrite"
#    storage_account_type = "Premium_LRS"
#  }
#  source_image_reference {
#    publisher = "debian"
#    offer     = "debian-12"
#    sku       = "12-gen2"
#    version   = "latest"
#  }
#  boot_diagnostics {
#    storage_account_uri = azurerm_storage_account.zitsta.primary_blob_endpoint
#  }
#  vtpm_enabled = true
#}
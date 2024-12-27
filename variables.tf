variable "azure_rg_name" {
  type        = string
  description = "Azure RG Group Name for this project"
  default     = "zit-cheap-vnet"
}

variable "azure_location" {
  type        = string
  description = "Azure Regiorn"
  default     = "Germany West Central"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the vnet"
  default     = "mycheapvnet"
}

variable "virtual_subnet1-name" {
  type        = string
  description = "Virtual Subnet 1"
  default     = "mycheapvnettransfer"
}

variable "virtual_subnet2-name" {
  type        = string
  description = "Virtual Subnet 2"
  default     = "mycheapvnetserver"
}
variable "virtual_subnet3-name" {
  type        = string
  description = "Virtual Subnet 3"
  default     = "mycheapvnetclients"
}

variable "network_nic_name_transfer" {
  type        = string
  description = "NIC Name"
  default     = "zitnictransfer"
}

variable "network_nic_name_server" {
  type        = string
  description = "NIC Name"
  default     = "zitnicserver"
}

variable "network_nic_name_clients" {
  type        = string
  description = "NIC Name"
  default     = "zitnicclients"
}

variable "network_nic_name_mytest" {
  type        = string
  description = "NIC name"
  default     = "zitnicmytest"

}

variable "prefix" {
  type        = string
  default     = "debian"
  description = "Name of "

}

variable "linuxpw" {
  type        = string
  default     = "Vpn123+++Vpn123+++"
  description = "Password"
}
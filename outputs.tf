output "resource_group_name" {
  value = azurerm_resource_group.zitmycheapvnet.name
}

output "vm_password" {

  value     = azurerm_linux_virtual_machine.mycheapvnetgw.admin_password
  sensitive = true

}

#output "azsrvtunnel01_public-ip" {
#  value = azurerm_public_ip.zitpubipazsrvtunnel01.ip_address
#}
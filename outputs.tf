output "resource_group_name" {
  value = azurerm_resource_group.zitmycheapvnet.name
}

output "vm_password" {

  value     = azurerm_linux_virtual_machine.mycheapvnetgw.admin_password
  sensitive = true

}
output "app_public_ip" {
  description = "Public IP address of the EpicBook frontend VM"
  value       = azurerm_public_ip.frontend.ip_address
}

output "backend_ansible_host" {
  description = "Private IP address used by Ansible to reach the backend VM"
  value       = azurerm_network_interface.backend.private_ip_address
}

output "backend_private_ip" {
  description = "Private IP address of the EpicBook backend VM"
  value       = azurerm_network_interface.backend.private_ip_address
}

output "mysql_fqdn" {
  description = "Private FQDN of the Azure MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.epicbook.fqdn
}

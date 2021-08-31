output "hostname" {
  value = var.hostname
}
output "public_ip" {
  value = azurerm_public_ip.csr_public_ip.ip_address
}
output "ssh_cmd_csr" {
  value = "ssh -i ${var.hostname}-key.pem adminuser@${azurerm_public_ip.csr_public_ip.ip_address}"
}
output "ssh_cmd_client" {
  value = "ssh -i ${var.hostname}-key.pem adminuser@${azurerm_public_ip.csr_public_ip.ip_address} -p 2222"
}
output "user_data" {
  value = base64decode(azurerm_linux_virtual_machine.CSROnprem.custom_data)
}

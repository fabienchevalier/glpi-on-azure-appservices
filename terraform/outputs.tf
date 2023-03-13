output "mysql_server_fqdn" {
    description = "Name of the Azure SQL Database created."
    value       = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_database_password" {
    description = "MySQL database password"
    value       = nonsensitive(random_password.mysql_password.result)
}

output "app_service_fqdn" {
  value = azurerm_linux_web_app.glpi-app-service.default_hostname
}
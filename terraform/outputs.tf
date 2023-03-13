output "mysql_database_password" {
    description = "MySQL database password"
    value       = random_password.mysql_password.result
    sensitive   = true
}

output "mysql_server_name" {
    description = "Name of the Azure SQL Database created."
    value       = azurerm_mysql_server.mysql.name
}
output "mysql_database_password" {
    description = "MySQL database password"
    value       = random_password.mysql_password.result
}

output "mysql_server_fqdn" {
    description = "Fully Qualified Domain Name (FQDN) of the Azure SQL Database created."
    value       = azurerm_mysql_server.mysql.fully_qualified_domain_name
}
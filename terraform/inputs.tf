# General variables
variable "location" {
    type = string
    default = "francecentral"
}

# Ressource group
variable "resource_group_name" {
    type = string
    default = "glpi-on-azure-appservices"
}

# Virtual Network
variable "vnet_name" {
    type = string
    default = "tf-vnet"
}

variable "vnet_address_space" {
    type = list(string)
    default = ["10.0.0.0/16"]
}

# Subnet
variable "mysql_subnet_name" {
    type = string
    default = "tf-mysql-subnet"
}

variable "mysql_subnet_address_prefixes" {
    type = list(string)
    default = ["10.0.1.0/24"]
}

variable "app_subnet_name" {
    type = string
    default = "tf-app-subnet"
}

variable "app_subnet_address_prefixes" {
    type = list(string)
    default = ["10.0.2.0/24"]
}

# Private DNS Zone
variable "mysql_private_zone_name" {
    type = string
    default = "mysql-glpi-appservices.mysql.database.azure.com"
}

# Private DNS zone link
variable "mysql_private_zone_link_name" {
    type = string
    default = "tf-mysql-private-zone-link"
}

# MySQL Database server
variable "mysql_server_name" {
    type = string
    default = "tf-mysql-glpi"
}

variable "mysql_database_admin_username" {
    type = string
    default = "glpi"
}

resource "random_password" "mysql_password" {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
}

# MySQL Database
variable "mysql_database_name" {
    type = string
    default = "tf-glpi-db"
}

# App Service Plan
variable "glpi_app_service_plan_name" {
    type = string
    default = "tf-glpi-service-plan"
}

# Linux Web App
variable "glpi_app_service_name" {
    type = string
    default = "tf-glpi-app-service"
}
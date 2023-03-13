terraform {
    backend "azurerm" {
        resource_group_name  = "backend-terraform-rg"
        storage_account_name = "terraformbackend9809"
        container_name       = "terraform"
        key                  = "terraform.tfstate"
    }

    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 3.47.0"
    }
}

    required_version = ">= 1.4.0"
}

provider "azurerm" {
    features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.location
}

# Virtual Network and subnet
resource "azurerm_virtual_network" "vnet" {
    name                = var.vnet_name
    address_space       = var.vnet_address_space
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "mysql_subnet" {
    name                 = var.mysql_subnet_name
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = var.mysql_subnet_address_prefixes
    service_endpoints    = ["Microsoft.Sql"]

    delegation {
        name = "vnet-delegation"

    service_delegation {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = [
            "Microsoft.Network/virtualNetworks/subnets/action"
            ]
        }
    }
}

resource "azurerm_subnet" "app_service_subnet" {
    name                 = var.app_subnet_name
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = var.app_subnet_address_prefixes

    delegation {
    name = "vnet-delegation"

    service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "mysql-private-zone" {
    name                = var.mysql_private_zone_name
    resource_group_name = azurerm_resource_group.rg.name
}

# Private DNS zone link
resource "azurerm_private_dns_zone_virtual_network_link" "mysql-private-zone-link" {
    name                  = var.mysql_private_zone_link_name
    private_dns_zone_name = azurerm_private_dns_zone.mysql-private-zone.name
    virtual_network_id    = azurerm_virtual_network.vnet.id
    resource_group_name   = azurerm_resource_group.rg.name
}

# MySQL Database server
resource "azurerm_mysql_flexible_server" "mysql" {
    name                = var.mysql_server_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    administrator_login    = var.mysql_database_admin_username
    administrator_password = random_password.mysql_password.result

    backup_retention_days  = 5
    sku_name            = "B_Standard_B1s"

    delegated_subnet_id = azurerm_subnet.mysql_subnet.id
    private_dns_zone_id = azurerm_private_dns_zone.mysql-private-zone.id
}

# MySQL Database
resource "azurerm_mysql_database" "mysql" {
    name                = var.mysql_database_name
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mysql_flexible_server.mysql.name
    charset             = "utf8"
    collation           = "utf8_unicode_ci"
}

# Azure App Service Plan
resource "azurerm_service_plan" "glpi-service-plan" {
    name                = var.glpi_app_service_plan_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    os_type             = "Linux"
    sku_name            = "B1"
}

# Azure App Service Web App
resource "azurerm_linux_web_app" "glpi-app-service" {
    name                = var.glpi_app_service_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_service_plan.glpi-service-plan.location
    service_plan_id     = azurerm_service_plan.glpi-service-plan.id

    site_config {
        always_on           = false
        application_stack {
            docker_image     = "diouxx/glpi"
            docker_image_tag = "latest"
        }
    }
}

#Connect the Azure App to subnet
resource "azurerm_app_service_virtual_network_swift_connection" "app" {
    app_service_id = azurerm_linux_web_app.glpi-app-service.id
    subnet_id      = azurerm_subnet.app_service_subnet.id
}
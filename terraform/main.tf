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
    name                = "tf-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet" {
    name                 = "tf-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
    service_endpoints    = ["Microsoft.Sql"]

    delegation {
        name = "vnet-delegation"

    service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }
}

# MySQL Database server
resource "azurerm_mysql_server" "mysql" {
    name                = "tf-mysql"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name

    administrator_login          = "mysqladmin"
    administrator_login_password = random_password.mysql_password.result

    sku_name   = "B_Gen5_1"
    storage_mb = 5120
    version    = "5.7"

    public_network_access_enabled = true
    ssl_enforcement_enabled       = true
}

# MySQL Database
resource "azurerm_mysql_database" "mysql" {
    name                = "tf-glpi-db"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mysql_server.mysql.name
    charset             = "utf8"
    collation           = "utf8_unicode_ci"
}

# Mysql Virtual Network Rule
resource "azurerm_mysql_virtual_network_rule" "mysql" {
    name                = "tf-mysql-vnet-rule"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mysql_server.mysql.name
    subnet_id           = azurerm_subnet.vnet.id
}

# Mysql Firewall Rule
resource "azurerm_mysql_firewall_rule" "mysql" {
    name                = "tf-mysql-firewall-rule"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mysql_server.mysql.name
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "0.0.0.0"
}

# Azure App Service Plan
resource "azurerm_service_plan" "glpi-service-plan" {
    name                = "tf-glpi-service-plan"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    os_type             = "Linux"
    sku_name            = "B1"
}

# Azure App Service Web App
resource "azurerm_linux_web_app" "glpi-app-service" {
    name                = "tf-glpi-app-service"
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

# Connect the Azure App to subnet
resource "azurerm_app_service_virtual_network_swift_connection" "app" {
  app_service_id = azurerm_linux_web_app.glpi-app-service.id
  subnet_id      = azurerm_subnet.vnet.id
}
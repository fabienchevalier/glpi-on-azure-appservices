variable "resource_group_name" {
    type = string
    default = "glpi-on-azure-appservices"
}

variable "location" {
    type = string
    default = "francecentral"
}

resource "random_password" "mysql_password" {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
}


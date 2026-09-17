resource "azurerm_resource_group" "epicbook" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_virtual_network" "epicbook" {
  name                = "vnet-${var.project_name}"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.10.3.0/24"]

  delegation {
    name = "mysql-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
    }
  }
}

resource "azurerm_public_ip" "frontend" {
  name                = "pip-${var.project_name}-frontend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project = var.project_name
    Role    = "frontend"
  }
}

resource "azurerm_network_security_group" "frontend" {
  name                = "nsg-${var.project_name}-frontend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-approved-ip"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "52.182.171.79/32"
    destination_address_prefix = "*"
  }

  tags = {
    Project = var.project_name
    Role    = "frontend"
  }
}

resource "azurerm_network_security_group" "backend" {
  name                = "nsg-${var.project_name}-backend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "allow-ssh-approved-ip"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "52.182.171.79/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-backend-from-frontend"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.10.1.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    Project = var.project_name
    Role    = "backend"
  }
}

resource "azurerm_network_interface" "frontend" {
  name                = "nic-${var.project_name}-frontend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend.id
  }

  tags = {
    Project = var.project_name
    Role    = "frontend"
  }
}

resource "azurerm_network_interface_security_group_association" "frontend" {
  network_interface_id      = azurerm_network_interface.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_network_interface" "backend" {
  name                = "nic-${var.project_name}-backend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Project = var.project_name
    Role    = "backend"
  }
}

resource "azurerm_network_interface_security_group_association" "backend" {
  network_interface_id      = azurerm_network_interface.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_linux_virtual_machine" "frontend" {
  name                = "vm-${var.project_name}-frontend"
  resource_group_name = azurerm_resource_group.epicbook.name
  location            = azurerm_resource_group.epicbook.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.frontend.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Project = var.project_name
    Role    = "frontend"
  }
}

resource "azurerm_linux_virtual_machine" "backend" {
  name                = "vm-${var.project_name}-backend"
  resource_group_name = azurerm_resource_group.epicbook.name
  location            = azurerm_resource_group.epicbook.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.backend.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Project = var.project_name
    Role    = "backend"
  }
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.project_name}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.epicbook.name

  tags = {
    Project = var.project_name
    Role    = "database"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "link-${var.project_name}-mysql"
  resource_group_name   = azurerm_resource_group.epicbook.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.epicbook.id

  tags = {
    Project = var.project_name
    Role    = "database"
  }
}

resource "azurerm_mysql_flexible_server" "epicbook" {
  name                   = "mysql-${var.project_name}"
  resource_group_name    = azurerm_resource_group.epicbook.name
  location               = azurerm_resource_group.epicbook.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password

  backup_retention_days = 7
  delegated_subnet_id   = azurerm_subnet.database.id
  private_dns_zone_id   = azurerm_private_dns_zone.mysql.id

  sku_name = "B_Standard_B1ms"

  version = "8.0.21"

  tags = {
    Project = var.project_name
    Role    = "database"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]

}

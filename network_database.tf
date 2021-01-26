resource "azurerm_virtual_network" "vnet_aula_infra" {
    name                = "my_vnet_aula_infra"
    address_space       = ["10.80.0.0/20"]
    location            = var.location
    resource_group_name = azurerm_resource_group.aula_infra.name

    tags = {
        environment = "aula infra"
    }

    depends_on = [ azurerm_resource_group.aula_infra ]
}


resource "azurerm_public_ip" "ip_aula_infra" {
    name                         = "my_ip_aula_infra"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.aula_infra.name
    allocation_method            = "Static"
    idle_timeout_in_minutes = 30

    tags = {
        environment = "aula infra database"
    }

    depends_on = [ azurerm_resource_group.aula_infra ]
}

resource "azurerm_subnet" "subnet_aula" {
    name                 = "my_subnet"
    resource_group_name  = azurerm_resource_group.aula_infra.name
    virtual_network_name = azurerm_virtual_network.vnet_aula_infra.name
    address_prefixes       = ["10.80.2.0/21"]

    depends_on = [ azurerm_resource_group.aula_infra]
}

resource "azurerm_network_interface" "ni_aula_infra" {
    name                      = "my_ni_bd"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.aula_infra.name

    ip_configuration {
        name                          = "my_ni_config"
 	subnet_id                     = azurerm_subnet.subnet_aula.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.80.2.10"
        public_ip_address_id          = azurerm_public_ip.ip_aula_infra.id
    }

    tags = {
        environment = "aula infra"
    }

    depends_on = [ azurerm_resource_group.aula_infra ]
}

resource "azurerm_network_interface_security_group_association" "nisql_aula_bd" {
    network_interface_id      = azurerm_network_interface.ni_aula_infra.id
    network_security_group_id = azurerm_network_security_group.aula_infra_sg.id

    depends_on = [ azurerm_network_interface.ni_aula_infra, azurerm_network_security_group.aula_infra_sg ]
}

resource "azurerm_network_security_group" "aula_infra_sg" {
    name                = "my_network_sg"
    location            = var.location
    resource_group_name = azurerm_resource_group.aula_infra.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "18"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
	
  security_rule {
        name                       = "MySql_outbound"
        priority                   = 1004
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


  security_rule {
        name                       = "MySql_inbound"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPInbound"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8081"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPOutbound"
        priority                   = 1003
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8081"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "aula infra"
    }

    depends_on = [ azurerm_resource_group.aula_infra ]
}


data "azurerm_public_ip" "ip_aula_data_infra" {
  name                = azurerm_public_ip.ip_aula_infra.name
  resource_group_name = azurerm_resource_group.aula_infra.name
}
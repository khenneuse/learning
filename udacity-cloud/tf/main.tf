# Used the https://github.com/hashicorp/terraform-provider-azurerm/blob/main/examples/virtual-machines/linux/basic-password/main.tf
# as a starting point for this file


provider "azurerm" {
  features {}
}

data "azurerm_image" "packer_image" {
  name                = "myPackerImage"
  resource_group_name = "AZUREDEVOPS"
}

resource "azurerm_virtual_network" "udacity-final" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = var.location
  resource_group_name = var.resource_group_name

  # MUST use the exact policy tag name discovered in your JSON definition
  tags = {
    environment = "Udacity_Final"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.udacity-final.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "udacity-final" {
  name                = "${var.prefix}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  security_rule {
    name                       = "Allow-Subnet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.internal.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }

  security_rule {
    name                       = "Allow-LB-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
 }

  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }

  tags = {
    environment = "Udacity_Final"
  }
}

resource "azurerm_subnet_network_security_group_association" "udacity-final" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.udacity-final.id
}

resource "azurerm_network_interface" "udacity-final" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "Udacity_Final"
  }
}

resource "azurerm_public_ip" "udacity-final" {
  name                = "UdacityPublicIp1"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"

  tags = {
    environment = "Udacity_Final"
  }
}

resource "azurerm_lb" "udacity-final" {
  name                = "${var.prefix}-lb"
  resource_group_name = var.resource_group_name
  location            = var.location

  frontend_ip_configuration {
    name                 = "PublicFrontEnd"
    public_ip_address_id = azurerm_public_ip.udacity-final.id
  }

  tags = {
    environment = "Udacity_Final"
  }
}

resource "azurerm_lb_backend_address_pool" "udacity-final" {
  name            = "BackendAddressPool"
  loadbalancer_id = azurerm_lb.udacity-final.id
}

resource "azurerm_lb_rule" "udacity-final" {
  loadbalancer_id                = azurerm_lb.udacity-final.id
  name                           = "InboundHTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.udacity-final.id]
}

resource "azurerm_network_interface_backend_address_pool_association" "udacity-final" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.udacity-final[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.udacity-final.id
}

resource "azurerm_availability_set" "udacity-final" {
  name                = "${var.prefix}-avset"
  resource_group_name = var.resource_group_name
  location            = var.location
  managed             = true

  tags = {
    environment = "Udacity_Final"
  }
}

resource "azurerm_linux_virtual_machine" "udacity-final" {
  count                           = var.vm_count
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_D2s_v3"

  availability_set_id = azurerm_availability_set.udacity-final.id

  admin_username                  = "udacityadmin"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "udacityadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.udacity-final[count.index].id,
  ]

  source_image_id = data.azurerm_image.packer_image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment = "Udacity_Final"
  }
}

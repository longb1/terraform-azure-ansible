#main vnet
resource "azurerm_virtual_network" "longb_vnet" {
  name                = "longb_vnet_rg"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name
  address_space       = ["10.89.0.0/16"]
}
#subnet for web VMs
resource "azurerm_subnet" "subnet_web" {
  name                 = "web_tier_tf"
  resource_group_name  = azurerm_resource_group.longb_rg.name
  virtual_network_name = azurerm_virtual_network.longb_vnet.name
  address_prefixes     = ["10.89.1.0/24"]
}
#NIC for web VMs
resource "azurerm_network_interface" "nic_web" {
  count               = 3
  name                = "longb_nic_web${count.index}"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  ip_configuration {
    name                          = "NICwebconfig"
    subnet_id                     = azurerm_subnet.subnet_web.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.89.1.1${count.index}"
  }
}
/* #web security group
resource "azurerm_network_security_group" "web_sg" {
  name                = "longb_web_SecurityGroup"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  security_rule {
    name                       = "allow-ping"
    description                = "allow-ping"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

#security group association to websubnet
resource "azurerm_subnet_network_security_group_association" "web-sg-associate" {
  subnet_id                 = azurerm_subnet.subnet_web.id
  network_security_group_id = azurerm_network_security_group.web_sg.id
} */

#public ip for loadbalancer
resource "azurerm_public_ip" "web_lb_publicip" {
  name                = "publicip_web"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name
  allocation_method   = "Static"
}
#loadbalancer EXTERNAL
resource "azurerm_lb" "longb_lb_public" {
  name                = "longb_lb_external"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  frontend_ip_configuration {
    name                 = "longb_publicip_config"
    public_ip_address_id = azurerm_public_ip.web_lb_publicip.id
  }
}
resource "azurerm_lb_backend_address_pool" "ext_lb_pool" {
  loadbalancer_id = azurerm_lb.longb_lb_public.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "ext_probe" {
  resource_group_name = azurerm_resource_group.longb_rg.name
  loadbalancer_id     = azurerm_lb.longb_lb_public.id
  name                = "tcpProbe"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "LBRuleHTTP" {
  resource_group_name            = azurerm_resource_group.longb_rg.name
  loadbalancer_id                = azurerm_lb.longb_lb_public.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "longb_publicip_config"
  probe_id                       = azurerm_lb_probe.ext_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ext_lb_pool.id]
}

#associate VMs by their NICs to LB pools (external LB)
resource "azurerm_network_interface_backend_address_pool_association" "NIC_to_LB_external" {
  count                   = length(azurerm_network_interface.nic_web)
  network_interface_id    = azurerm_network_interface.nic_web[count.index].id
  ip_configuration_name   = "NICwebconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ext_lb_pool.id
}

#subnet for db VMs
resource "azurerm_subnet" "subnet_db" {
  name                 = "db_tier_tf"
  resource_group_name  = azurerm_resource_group.longb_rg.name
  virtual_network_name = azurerm_virtual_network.longb_vnet.name
  address_prefixes     = ["10.89.2.0/24"]
}
#NIC for db VMs
resource "azurerm_network_interface" "nic_db" {
  count               = 3
  name                = "longb_nic_db${count.index}"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  ip_configuration {
    name                          = "NICdbconfig"
    subnet_id                     = azurerm_subnet.subnet_db.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.89.2.2${count.index}"
  }
}
/* #database security group
resource "azurerm_network_security_group" "db_sg" {
  name                = "longb_db_SecurityGroup"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  security_rule {
    name                       = "allow-ssh-in"
    description                = "Allow ssh connections"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-sql-in" #sql from web subnet
    description                = "allow SQL from web"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1443"
    source_address_prefix      = "10.89.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-out" 
    description                = "Deny outbound traffic to the internet"
    priority                   = 500
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}
#security group association to database subnet
resource "azurerm_subnet_network_security_group_association" "db-sg-associate" {
  subnet_id                 = azurerm_subnet.subnet_db.id
  network_security_group_id = azurerm_network_security_group.db_sg.id
} */

#loadbalancer INTERNAL
resource "azurerm_lb" "longb_lb_private" {
  name                = "longb_lb_internal"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  frontend_ip_configuration {
    name                          = "longb_lb_privateIP"
    subnet_id                     = azurerm_subnet.subnet_db.id
    private_ip_address            = "10.89.2.15"
    private_ip_address_allocation = "Static" #private ip config
  }
}
resource "azurerm_lb_backend_address_pool" "int_lb_pool" {
  loadbalancer_id = azurerm_lb.longb_lb_private.id
  name            = "BackEndAddressPool"
}
resource "azurerm_lb_probe" "int_probe" {
  resource_group_name = azurerm_resource_group.longb_rg.name
  loadbalancer_id     = azurerm_lb.longb_lb_private.id
  name                = "tcpProbe"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "LBRuleSQL" {
  resource_group_name            = azurerm_resource_group.longb_rg.name
  loadbalancer_id                = azurerm_lb.longb_lb_private.id
  name                           = "LBRuleINT"
  protocol                       = "Tcp"
  frontend_port                  = 1443
  backend_port                   = 1443 #sql port
  frontend_ip_configuration_name = "longb_lb_privateIP"
  probe_id                       = azurerm_lb_probe.int_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.int_lb_pool.id]
}

#associate NICs to LB pools (internal LB)
resource "azurerm_network_interface_backend_address_pool_association" "NIC_to_LB_internal" {
  count                   = length(azurerm_network_interface.nic_db)
  network_interface_id    = azurerm_network_interface.nic_db[count.index].id
  ip_configuration_name   = "NICdbconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.int_lb_pool.id
}

#managemnt subnet (for pushing out ansible configs, etc..)
resource "azurerm_subnet" "subnet_management" {
  name                 = "mgnt_subnet"
  resource_group_name  = azurerm_resource_group.longb_rg.name
  virtual_network_name = azurerm_virtual_network.longb_vnet.name
  address_prefixes     = ["10.89.3.0/24"]
}
resource "azurerm_public_ip" "mgnt_publicip" {
  name                = "publicip_mgnt"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name
  allocation_method   = "Static"
}
#NIC for web VMs
resource "azurerm_network_interface" "nic_mgnt" {
  name                = "longb_nic_mgnt"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  ip_configuration {
    name                          = "NICmgntconfig"
    subnet_id                     = azurerm_subnet.subnet_management.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.89.3.30"
    public_ip_address_id          = azurerm_public_ip.mgnt_publicip.id
  }
}

/* #mgnmt security group
resource "azurerm_network_security_group" "mgnt_sg" {
  name                = "longb_mgnt_SG"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  security_rule {
    name                       = "allow-ping"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}
#security group association to websubnet
resource "azurerm_subnet_network_security_group_association" "mgnt-sg-link" {
  subnet_id                 = azurerm_subnet.subnet_management.id
  network_security_group_id = azurerm_network_security_group.mgnt_sg.id
} */
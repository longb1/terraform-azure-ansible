#vnet security group
resource "azurerm_network_security_group" "longb_vnet_sg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  /* security_rule {
    name                       = "allow-rdp"
    description                = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
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
    source_address_prefix      = "*"
    destination_address_prefix = "*" 
  }*/
}
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
  name                = "longb_nic_tf${count.index}"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  ip_configuration {
    name                          = "NICwebconfig"
    subnet_id                     = azurerm_subnet.subnet_web.id
    private_ip_address_allocation = "Dynamic"
  }
}
/* #security group association to websubnet
resource "azurerm_subnet_network_security_group_association" "web_to_sg_winrm" {
  subnet_id                 = azurerm_subnet.subnet_web.id
  network_security_group_id = azurerm_network_security_group.longb_vnet_sg.id
} */
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
    private_ip_address_allocation = "Dynamic"
  }
}
#public ip for loadbalancer
resource "azurerm_public_ip" "longb_publicip" {
  name                = "longb_publicip_tf"
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
    public_ip_address_id = azurerm_public_ip.longb_publicip.id
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
  probe_id = azurerm_lb_probe.ext_probe.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.ext_lb_pool.id]
}

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
  probe_id = azurerm_lb_probe.int_probe.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.int_lb_pool.id]
}

#associate VMs by their NICs to LB pools (external LB)
resource "azurerm_network_interface_backend_address_pool_association" "NIC_to_LB_external" {
  count                   = length(azurerm_network_interface.nic_web)
  network_interface_id    = azurerm_network_interface.nic_web[count.index].id
  ip_configuration_name   = "NICwebconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ext_lb_pool.id
}
#associate NICs to LB pools (internal LB)
resource "azurerm_network_interface_backend_address_pool_association" "NIC_to_LB_internal" {
  count                   = length(azurerm_network_interface.nic_db)
  network_interface_id    = azurerm_network_interface.nic_db[count.index].id
  ip_configuration_name   = "NICdbconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.int_lb_pool.id
}

#route for web VM to internal load balancer
resource "azurerm_route_table" "web_to_db" {
  name                = "route_web_to_db"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  route {
    name                   = "route1"
    address_prefix         = element(azurerm_subnet.subnet_db.address_prefixes,0)
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_lb.longb_lb_private.private_ip_address
  }
}
resource "azurerm_subnet_route_table_association" "assign_to_web" {
  subnet_id      = azurerm_subnet.subnet_web.id
  route_table_id = azurerm_route_table.web_to_db.id
}

#route for database VMs to internal load balancer
resource "azurerm_route_table" "db_to_web" {
  name                = "route_db_to_web"
  location            = azurerm_resource_group.longb_rg.location
  resource_group_name = azurerm_resource_group.longb_rg.name

  route {
    name                   = "route2"
    address_prefix         = "0.0.0.0/0" #direct all traffic out the same way it came in
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_lb.longb_lb_private.private_ip_address
  }
}
resource "azurerm_subnet_route_table_association" "assign_to_db" {
  subnet_id      = azurerm_subnet.subnet_db.id
  route_table_id = azurerm_route_table.db_to_web.id
}


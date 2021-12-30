#availability set for web VMs
resource "azurerm_availability_set" "avset_web" {
  name                        = "longb_web_avset"
  location                    = azurerm_resource_group.longb_rg.location
  resource_group_name         = azurerm_resource_group.longb_rg.name
  platform_fault_domain_count = 2
}
#web virtual machens
resource "azurerm_virtual_machine" "longb_vm_web" {
  count                 = 3 #create three identical VMs
  name                  = "long_vm_tf${count.index}"
  location              = azurerm_resource_group.longb_rg.location
  resource_group_name   = azurerm_resource_group.longb_rg.name
  network_interface_ids = [azurerm_network_interface.nic_web[count.index].id]
  vm_size               = "Standard_D2as_v4"
  availability_set_id   = azurerm_availability_set.avset_web.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "longb_webosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-tf${count.index}"
    admin_username = "foo"
    admin_password = "Barbaz000"
  }
  os_profile_windows_config {
    timezone = "GMT Standard Time"
  }
}

#availability set for db VMs
resource "azurerm_availability_set" "avset_db" {
  name                        = "longb_db_avset"
  location                    = azurerm_resource_group.longb_rg.location
  resource_group_name         = azurerm_resource_group.longb_rg.name
  platform_fault_domain_count = 2
}
#db virtual machens
resource "azurerm_virtual_machine" "longb_vm_db" {
  count                 = 3
  name                  = "long_vm_db${count.index}"
  location              = azurerm_resource_group.longb_rg.location
  resource_group_name   = azurerm_resource_group.longb_rg.name
  network_interface_ids = [azurerm_network_interface.nic_db[count.index].id]
  vm_size               = "Standard_D2as_v4"
  availability_set_id   = azurerm_availability_set.avset_db.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "longb_dbosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-tf-db${count.index}"
    admin_username = "foo"
    admin_password = "Barbaz000"
  }
  os_profile_windows_config {
    timezone = "GMT Standard Time"
  }
}

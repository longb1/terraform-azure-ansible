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
  name                  = "long_vm_web${count.index}"
  location              = azurerm_resource_group.longb_rg.location
  resource_group_name   = azurerm_resource_group.longb_rg.name
  network_interface_ids = [azurerm_network_interface.nic_web[count.index].id]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.avset_web.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "longb_webosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-tf-web${count.index}"
    admin_username = var.adminusername
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys { #review this...
      key_data = tls_private_key.private-key-example.public_key_openssh
      path     = "/home/${var.adminusername}/.ssh/authorized_keys"
    }
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
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.avset_db.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
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
    admin_username = var.adminusername
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys { #review this...
      key_data = tls_private_key.private-key-example.public_key_openssh
      path     = "/home/${var.adminusername}/.ssh/authorized_keys"
    }
  }
}

#management VM (pushing out ansible)
resource "azurerm_virtual_machine" "mgnt_vm" {
  name                  = "long_vm_mgnt"
  location              = azurerm_resource_group.longb_rg.location
  resource_group_name   = azurerm_resource_group.longb_rg.name
  network_interface_ids = [azurerm_network_interface.nic_mgnt.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "longb_dbosdisk_mgnt"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm-tf-mgnt"
    admin_username = var.adminusername
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys { #review this...
      key_data = tls_private_key.private-key-example.public_key_openssh
      path     = "/home/${var.adminusername}/.ssh/authorized_keys"
    }
  }

  connection {
    type        = "ssh"
    host        = format("%s", azurerm_public_ip.mgnt_publicip.ip_address)
    user        = var.adminusername
    private_key = tls_private_key.private-key-example.private_key_pem
  }
  provisioner "file" { #copies private key to linux home to be used with ansible
    source      = local_file.private_key.filename
    destination = ".ssh/${local_file.private_key.filename}" #destination is already at home directory (~)
  }
  provisioner "file" { #copies ansible host inventory to mgnt VM
    source      = "./ansible/hosts"
    destination = "/tmp/hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install ansible -y",
      "sudo chmod 777 /etc/ansible/hosts",
      "sudo cat /tmp/hosts >> /etc/ansible/hosts",
      "chmod 400 .ssh/${local_file.private_key.filename}"
    ]
  }


}
resource "azurerm_storage_account" "storage_aula_infra" 
{
    name                        = "storage_aula_infra"
    resource_group_name         = azurerm_resource_group.aula_infra.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "aula infra"
    }

    depends_on = [ azurerm_resource_group.aula_infra ]
}

resource "azurerm_linux_virtual_machine" "vm_aula_infra" 
{
    name                  = "my_VM"
    location              = var.location
    resource_group_name   = azurerm_resource_group.aula_infra.name
    network_interface_ids = [azurerm_network_interface.ni_aula_infra.id]
    size                  = "Standard_D2_v3"

    os_disk {
        name              = "my_os_bd_disk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "my_VM"
    admin_username = var.user
    admin_password = var.password
    disable_password_authentication = false


    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage_aula_infra.primary_blob_endpoint
    }

    tags = {
        environment = "aula infra bd"
    }

    depends_on = [ azurerm_resource_group.aula_infra, azurerm_network_interface.ni_aula_infra, 
    azurerm_storage_account.storage_aula_infra, azurerm_public_ip.ip_aula_infra ]
}


resource "null_resource" "upload" 
{
    provisioner "file" {
        connection {
            type = "ssh"
            user = var.user
            password = var.password
            host = data.azurerm_public_ip.ip_aula_data_infra.ip_address
        }
        source = "mysql"
        destination = "/home/{user}"
    }

}

resource "null_resource" "deploy"
 {
    triggers = {
        order = null_resource.upload.id
    }
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = var.user
            password = var.password
            host = data.azurerm_public_ip.ip_aula_data_infra.ip_address
        }
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y mysql-server-5.7",
        ]
    }
}
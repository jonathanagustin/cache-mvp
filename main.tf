# ./main.tf

# Configure AWS provider
provider "aws" {
  region = "us-west-2"
}

# Create an AWS EC2 instance with RHEL
resource "aws_instance" "rhel_instance" {
  # RHEL 8 AMI ID (us-west-2)
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "RHEL_Instance"
  }
}

# Configure Azure provider
provider "azurerm" {
  features {}
}

# Create Azure resource group
resource "azurerm_resource_group" "test" {
  name     = "test-resources"
  location = "East US"
}

# Create Azure virtual network
resource "azurerm_virtual_network" "test" {
  name                = "test-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

# Create Azure subnet
resource "azurerm_subnet" "test" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefix       = "10.0.1.0/24"
}

# Create Azure network interface
resource "azurerm_network_interface" "test" {
  name                = "test-nic"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create an Azure virtual machine with RHEL
resource "azurerm_virtual_machine" "rhel_vm" {
  name                  = "test-vm"
  location              = azurerm_resource_group.test.location
  resource_group_name   = azurerm_resource_group.test.name
  network_interface_ids = [azurerm_network_interface.test.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "test-vm"
    admin_username = "azureuser"
    admin_password = "password1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name = "RHEL_VM"
  }
}
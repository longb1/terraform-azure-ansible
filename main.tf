#create resource group
resource "azurerm_resource_group" "longb_rg" {
  name     = "longb_terraform_rg"
  location = "UK South"
}
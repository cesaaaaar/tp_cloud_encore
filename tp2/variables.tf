# variables.tf

variable "subscription_id" { 
   type = string 
}
variable "client_id" { 
   type = string 
}
variable "client_secret" { 
   type = string
}
variable "tenant_id" { 
   type = string 
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
}

variable "public_key_path" {
  type        = string
  description = "Path to your SSH public key"
}

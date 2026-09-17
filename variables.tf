variable "location" {
  description = "Azure region"
  type        = string
  default     = "West US 2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "epicbook"
}

variable "admin_username" {
  description = "Linux administrator username"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key for the Azure VMs"
  type        = string
  sensitive   = true
}

variable "mysql_admin_username" {
  description = "Azure MySQL administrator username"
  type        = string
  sensitive   = true
}

variable "mysql_admin_password" {
  description = "Azure MySQL administrator password"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Azure VM size for the frontend and backend"
  type        = string
  default     = "Standard_D2as_v7"
}

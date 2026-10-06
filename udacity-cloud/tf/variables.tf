variable "prefix" {
  description = "The prefix which should be used for all resources in this project"
  type    = string
  default = "udacity"
}

variable "resource_group_name" {
  description = "The resource group name that is already built for the project"
  type    = string
}

variable "location" {
  description = "The Azure Region in which all resources in this project should be created."
  default = "westus2"
}

variable "vm_count" {
  description = "The number of VMs to create in our pool for the project"
  type        = number
  default     = 3
}

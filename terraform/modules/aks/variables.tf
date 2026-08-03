variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "The name of the resource group to create"
  type        = string
  default     = "rg-devsecops-workload"
}


variable "acr_id" {
  description = "The ID of the ACR the AKS cluster should pull from"
  type        = string
}


variable "subnet_id" {
  description = "The ID of the subnet to deploy the AKS cluster into"
  type        = string
}

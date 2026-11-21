variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "aks_kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version — verify with az aks get-versions"
}

variable "aks_node_count" {
  type        = number
  description = "Number of AKS nodes"
  default     = 1
}

variable "aks_node_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags for all resources"
  default     = {}
}
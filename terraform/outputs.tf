output "resource_group_name" {
  value       = module.infra.resource_group_name
  description = "Name of the resource group"
}

output "acr_login_server" {
  value       = module.infra.acr_login_server
  description = "ACR login server URL"
}

output "acr_name" {
  value       = module.infra.acr_name
  description = "ACR name for az acr login"
}

output "aks_cluster_name" {
  value       = module.infra.aks_cluster_name
  description = "AKS cluster name"
}
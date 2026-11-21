project_name           = "atlas-07"
environment            = "dev"
location               = "centralindia"
aks_kubernetes_version = "1.36.5"
aks_node_count         = 1
aks_node_size          = "Standard_B2s"
os_disk_size_gb        = 30

tags = {
  project     = "atlas-07-gitops-argocd"
  environment = "dev"
  team        = "platform"
  cost-center = "atlas-learning"
  created-by  = "terraform"
  managed-by  = "ado-pipeline"
  destroy-by  = "end-of-day"
}

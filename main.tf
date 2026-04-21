terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  cluster_name = can(regex(".*/(.+)$", var.aks_cluster_name)) ? regex(".*/(.+)$", var.aks_cluster_name)[0] : var.aks_cluster_name

  cluster_resource_id_falcon = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${local.cluster_name}"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = local.cluster_name
  resource_group_name = var.resource_group_name
}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  token                  = data.azurerm_kubernetes_cluster.aks.kube_config.0.password
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
    token                  = data.azurerm_kubernetes_cluster.aks.kube_config.0.password
  }
}

# Use official CrowdStrike Falcon Sensor module
module "falcon_sensor" {
  source = "github.com/CrowdStrike/terraform-kubectl-falcon//modules/falcon_sensor"

  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
  cid           = var.falcon_cid
  cloud         = var.falcon_cloud_region

  sensor_image_tag        = var.falcon_sensor_version
  sensor_image_repository = "registry.crowdstrike.com/falcon-sensor/release/falcon-sensor"
  sensor_image_pull_token = var.falcon_registry_pull_token

  node_backend = "bpf"
  tags         = var.falcon_tags
}

# Use official CrowdStrike Falcon KAC module
module "falcon_kac" {
  source = "github.com/CrowdStrike/terraform-kubectl-falcon//modules/falcon_kac"

  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
  cid           = var.falcon_cid
  cloud         = var.falcon_cloud_region

  kac_image_tag        = var.falcon_kac_version
  kac_image_repository = "registry.crowdstrike.com/falcon-kac/release/falcon-kac"
  kac_image_pull_token = var.falcon_kac_pull_token

  cluster_name = local.cluster_resource_id_falcon

  depends_on = [module.falcon_sensor]
}

# Use official CrowdStrike Falcon IAR module
module "falcon_iar" {
  source = "github.com/CrowdStrike/terraform-kubectl-falcon//modules/falcon_iar"

  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
  cid           = var.falcon_cid
  cloud         = var.falcon_cloud_region

  iar_image_tag        = var.falcon_iar_version
  iar_image_repository = "registry.crowdstrike.com/falcon-imageanalyzer/${var.falcon_cloud_region}/release/falcon-imageanalyzer"
  iar_image_pull_token = var.falcon_iar_pull_token

  cluster_name = local.cluster_resource_id_falcon

  depends_on = [module.falcon_sensor]
}

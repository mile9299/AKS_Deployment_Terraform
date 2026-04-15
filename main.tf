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

# Data source for existing AKS cluster
data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
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

# Create falcon-system namespace
resource "kubectl_manifest" "falcon_system_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: falcon-system
  YAML
}

# Create falcon-kac namespace
resource "kubectl_manifest" "falcon_kac_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: falcon-kac
  YAML
}

# Create falcon-image-analyzer namespace
resource "kubectl_manifest" "falcon_image_analyzer_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: falcon-image-analyzer
  YAML
}

# Create image pull secret for falcon-system
resource "kubectl_manifest" "crowdstrike_pull_secret_system" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: crowdstrike-pull-secret
      namespace: falcon-system
    type: kubernetes.io/dockerconfigjson

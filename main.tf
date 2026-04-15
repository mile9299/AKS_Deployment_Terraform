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

# Create namespace for Falcon
resource "kubectl_manifest" "falcon_system_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: falcon-system
  YAML
}

# Create Falcon API credentials secret
resource "kubectl_manifest" "falcon_credentials" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: falcon-api-credentials
      namespace: falcon-system
    type: Opaque
    stringData:
      client_id: ${var.falcon_client_id}
      client_secret: ${var.falcon_client_secret}
  YAML

  depends_on = [kubectl_manifest.falcon_system_namespace]
}

# Deploy Falcon Sensor as DaemonSet
resource "helm_release" "falcon_sensor" {
  name       = "falcon-sensor"
  repository = "https://crowdstrike.github.io/falcon-helm"
  chart      = "falcon-sensor"
  namespace  = "falcon-system"
  version    = var.falcon_sensor_version

  set {
    name  = "falcon.cid"
    value = var.falcon_cid
  }

  set_sensitive {
    name  = "falcon.apd"
    value = "false"
  }

  set {
    name  = "node.backend"
    value = "kernel"
  }

  set {
    name  = "falcon.tags"
    value = var.falcon_tags
  }

  set {
    name  = "node.image.repository"
    value = var.falcon_image_registry
  }

  depends_on = [kubectl_manifest.falcon_credentials]
}

# Deploy Kubernetes Admission Controller (KAC)
resource "helm_release" "falcon_kac" {
  name       = "falcon-kac"
  repository = "https://crowdstrike.github.io/falcon-helm"
  chart      = "falcon-kac"
  namespace  = "falcon-system"
  version    = var.falcon_kac_version

  set {
    name  = "falcon.cid"
    value = var.falcon_cid
  }

  set {
    name  = "image.repository"
    value = "${var.falcon_image_registry}/falcon-kac"
  }

  set {
    name  = "falcon.clientID"
    value = var.falcon_client_id
  }

  set_sensitive {
    name  = "falcon.clientSecret"
    value = var.falcon_client_secret
  }

  set {
    name  = "installNamespace"
    value = "falcon-system"
  }

  depends_on = [kubectl_manifest.falcon_credentials]
}

# Deploy Image Assessment at Runtime (IAR)
resource "helm_release" "falcon_iar" {
  name       = "falcon-image-analyzer"
  repository = "https://crowdstrike.github.io/falcon-helm"
  chart      = "falcon-image-analyzer"
  namespace  = "falcon-system"
  version    = var.falcon_iar_version

  set {
    name  = "deployment.enabled"
    value = "true"
  }

  set {
    name  = "crowdstrikeConfig.clientID"
    value = var.falcon_client_id
  }

  set_sensitive {
    name  = "crowdstrikeConfig.clientSecret"
    value = var.falcon_client_secret
  }

  set {
    name  = "crowdstrikeConfig.clusterName"
    value = var.aks_cluster_name
  }

  set {
    name  = "image.repository"
    value = "${var.falcon_image_registry}/falcon-imageanalyzer"
  }

  set {
    name  = "crowdstrikeConfig.cid"
    value = var.falcon_cid
  }

  depends_on = [kubectl_manifest.falcon_credentials]
}

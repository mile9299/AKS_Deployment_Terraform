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

resource "kubectl_manifest" "falcon_system_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: falcon-system
YAML
}

resource "kubectl_manifest" "falcon_kac_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: falcon-kac
YAML
}

resource "kubectl_manifest" "falcon_image_analyzer_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: falcon-image-analyzer
YAML
}

resource "kubectl_manifest" "crowdstrike_pull_secret_system" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: crowdstrike-pull-secret
  namespace: falcon-system
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${var.falcon_registry_pull_token}
YAML

  depends_on = [kubectl_manifest.falcon_system_namespace]
}

# -----------------------------------------------
# Falcon Sensor - DaemonSet in falcon-system
# -----------------------------------------------
resource "helm_release" "falcon_sensor" {
  name             = "falcon-sensor"
  repository       = "https://crowdstrike.github.io/falcon-helm"
  chart            = "falcon-sensor"
  namespace        = "falcon-system"
  create_namespace = false
  timeout          = 600
  wait             = true

  set {
    name  = "falcon.cid"
    value = var.falcon_cid
  }

  set {
    name  = "node.backend"
    value = "bpf"
  }

  set {
    name  = "falcon.tags"
    value = var.falcon_tags
  }

  set {
    name  = "node.image.repository"
    value = "registry.crowdstrike.com/falcon-sensor/release/falcon-sensor"
  }

  set {
    name  = "node.image.tag"
    value = var.falcon_sensor_version
  }

  set {
    name  = "node.image.pullSecrets"
    value = "crowdstrike-pull-secret"
  }

  depends_on = [
    kubectl_manifest.falcon_system_namespace,
    kubectl_manifest.crowdstrike_pull_secret_system
  ]
}

# -----------------------------------------------
# Falcon KAC - in falcon-kac namespace
# -----------------------------------------------
resource "helm_release" "falcon_kac" {
  name             = "falcon-kac"
  repository       = "https://crowdstrike.github.io/falcon-helm"
  chart            = "falcon-kac"
  namespace        = "falcon-kac"
  create_namespace = false
  timeout          = 600
  wait             = true

  set {
    name  = "falcon.cid"
    value = var.falcon_cid
  }

  set {
    name  = "falcon.cloud"
    value = var.falcon_cloud_region
  }

  # Set cloud provider under falcon namespace
  set {
    name  = "falcon.cloudProvider"
    value = "azure"
  }

  set {
    name  = "image.repository"
    value = "registry.crowdstrike.com/falcon-kac/release/falcon-kac"
  }

  set {
    name  = "image.tag"
    value = var.falcon_kac_version
  }

  set_sensitive {
    name  = "image.registryConfigJSON"
    value = var.falcon_kac_pull_token
  }

  set {
    name  = "clusterName"
    value = local.cluster_resource_id_falcon
  }

  set {
    name  = "cloudProvider"
    value = "azure"
  }

  set {
    name  = "azure.enabled"
    value = "true"
  }

  set {
    name  = "azure.subscriptionID"
    value = var.azure_subscription_id
  }

  set {
    name  = "azure.location"
    value = data.azurerm_kubernetes_cluster.aks.location
  }

  depends_on = [
    kubectl_manifest.falcon_kac_namespace
  ]
}

# -----------------------------------------------
# Falcon IAR - in falcon-image-analyzer namespace
# -----------------------------------------------
resource "helm_release" "falcon_iar" {
  name             = "falcon-imageanalyzer"
  repository       = "https://crowdstrike.github.io/falcon-helm"
  chart            = "falcon-image-analyzer"
  namespace        = "falcon-image-analyzer"
  create_namespace = false
  timeout          = 600
  wait             = true

  set {
    name  = "crowdstrikeConfig.cid"
    value = var.falcon_cid
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
    value = local.cluster_resource_id_falcon
  }

  set {
    name  = "crowdstrikeConfig.cloud"
    value = var.falcon_cloud_region
  }

  set {
    name  = "deployment.enabled"
    value = "true"
  }

  set {
    name  = "image.repository"
    value = "registry.crowdstrike.com/falcon-imageanalyzer/${var.falcon_cloud_region}/release/falcon-imageanalyzer"
  }

  set {
    name  = "image.tag"
    value = var.falcon_iar_version
  }

  set_sensitive {
    name  = "image.registryConfigJSON"
    value = var.falcon_iar_pull_token
  }

  set {
    name  = "azure.enabled"
    value = "true"
  }

  set {
    name  = "azure.subscriptionID"
    value = var.azure_subscription_id
  }

  depends_on = [
    kubectl_manifest.falcon_image_analyzer_namespace
  ]
}

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
    data:
      .dockerconfigjson: ${base64encode(jsonencode({
        auths = {
          "registry.crowdstrike.com" = {
            username = var.falcon_client_id
            password = var.falcon_client_secret
            auth     = base64encode("${var.falcon_client_id}:${var.falcon_client_secret}")
          }
        }
      }))}
  YAML

  depends_on = [kubectl_manifest.falcon_system_namespace]
}

# Create image pull secret for falcon-kac
resource "kubectl_manifest" "crowdstrike_pull_secret_kac" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: crowdstrike-pull-secret
      namespace: falcon-kac
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: ${base64encode(jsonencode({
        auths = {
          "registry.crowdstrike.com" = {
            username = var.falcon_client_id
            password = var.falcon_client_secret
            auth     = base64encode("${var.falcon_client_id}:${var.falcon_client_secret}")
          }
        }
      }))}
  YAML

  depends_on = [kubectl_manifest.falcon_kac_namespace]
}

# Create image pull secret for falcon-image-analyzer
resource "kubectl_manifest" "crowdstrike_pull_secret_iar" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: crowdstrike-pull-secret
      namespace: falcon-image-analyzer
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: ${base64encode(jsonencode({
        auths = {
          "registry.crowdstrike.com" = {
            username = var.falcon_client_id
            password = var.falcon_client_secret
            auth     = base64encode("${var.falcon_client_id}:${var.falcon_client_secret}")
          }
        }
      }))}
  YAML

  depends_on = [kubectl_manifest.falcon_image_analyzer_namespace]
}

# Deploy Unified Falcon Platform (Sensor, KAC, and IAR)
resource "helm_release" "falcon_platform" {
  name       = "falcon-platform"
  repository = "https://crowdstrike.github.io/falcon-helm"
  chart      = "falcon-platform"
  namespace  = "falcon-system"
  version    = var.falcon_platform_version

  create_namespace = false
  timeout          = 600
  wait             = true

  # Falcon Sensor Configuration (DaemonSet in falcon-system namespace)
  set {
    name  = "falcon-sensor.enabled"
    value = "true"
  }

  set {
    name  = "falcon-sensor.falcon.cid"
    value = var.falcon_cid
  }

  set {
    name  = "falcon-sensor.node.backend"
    value = "kernel"
  }

  set {
    name  = "falcon-sensor.falcon.tags"
    value = var.falcon_tags
  }

  set {
    name  = "falcon-sensor.node.image.repository"
    value = "registry.crowdstrike.com/falcon-node-sensor"
  }

  set {
    name  = "falcon-sensor.node.image.pullSecrets[0].name"
    value = "crowdstrike-pull-secret"
  }

  # Falcon KAC Configuration (in falcon-kac namespace)
  set {
    name  = "falcon-kac.enabled"
    value = "true"
  }

  set {
    name  = "falcon-kac.installNamespace"
    value = "falcon-kac"
  }

  set {
    name  = "falcon-kac.falcon.cid"
    value = var.falcon_cid
  }

  set {
    name  = "falcon-kac.falcon.clientID"
    value = var.falcon_client_id
  }

  set_sensitive {
    name  = "falcon-kac.falcon.clientSecret"
    value = var.falcon_client_secret
  }

  set {
    name  = "falcon-kac.falcon.cloud"
    value = var.falcon_cloud_region
  }

  set {
    name  = "falcon-kac.image.repository"
    value = "registry.crowdstrike.com/falcon-kac"
  }

  set {
    name  = "falcon-kac.image.pullSecrets[0].name"
    value = "crowdstrike-pull-secret"
  }

  # Falcon Image Analyzer (IAR) Configuration (in falcon-image-analyzer namespace)
  set {
    name  = "falcon-image-analyzer.enabled"
    value = "true"
  }

  set {
    name  = "falcon-image-analyzer.installNamespace"
    value = "falcon-image-analyzer"
  }

  set {
    name  = "falcon-image-analyzer.deployment.enabled"
    value = "true"
  }

  set {
    name  = "falcon-image-analyzer.crowdstrikeConfig.cid"
    value = var.falcon_cid
  }

  set {
    name  = "falcon-image-analyzer.crowdstrikeConfig.clientID"
    value = var.falcon_client_id
  }

  set_sensitive {
    name  = "falcon-image-analyzer.crowdstrikeConfig.clientSecret"
    value = var.falcon_client_secret
  }

  set {
    name  = "falcon-image-analyzer.crowdstrikeConfig.clusterName"
    value = var.aks_cluster_name
  }

  set {
    name  = "falcon-image-analyzer.crowdstrikeConfig.cloud"
    value = var.falcon_cloud_region
  }

  set {
    name  = "falcon-image-analyzer.image.repository"
    value = "registry.crowdstrike.com/falcon-imageanalyzer"
  }

  set {
    name  = "falcon-image-analyzer.image.pullSecrets[0].name"
    value = "crowdstrike-pull-secret"
  }

  set {
    name  = "falcon-image-analyzer.azure.enabled"
    value = "true"
  }

  set {
    name  = "falcon-image-analyzer.azure.subscriptionID"
    value = var.azure_subscription_id
  }

  depends_on = [
    kubectl_manifest.falcon_system_namespace,
    kubectl_manifest.falcon_kac_namespace,
    kubectl_manifest.falcon_image_analyzer_namespace,
    kubectl_manifest.crowdstrike_pull_secret_system,
    kubectl_manifest.crowdstrike_pull_secret_kac,
    kubectl_manifest.crowdstrike_pull_secret_iar
  ]
}

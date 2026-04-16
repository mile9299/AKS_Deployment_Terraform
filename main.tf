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

# Pull secret for Falcon Sensor - uses pull token
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

# Pull secret for Falcon KAC - uses pull token
resource "kubectl_manifest" "crowdstrike_pull_secret_kac" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: crowdstrike-pull-secret
  namespace: falcon-kac
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${var.falcon_registry_pull_token}
YAML

  depends_on = [kubectl_manifest.falcon_kac_namespace]
}

# Pull secret for Falcon IAR - uses Client ID and Secret directly
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

resource "helm_release" "falcon_platform" {
  name       = "falcon-platform"
  repository = "https://crowdstrike.github.io/falcon-helm"
  chart      = "falcon-platform"
  namespace  = "falcon-system"
  version    = var.falcon_platform_version

  create_namespace = false
  timeout          = 600
  wait             = true

  set {
    name  = "nameOverride"
    value = ""
  }

  set {
    name  = "fullnameOverride"
    value = ""
  }

  # Falcon Sensor Configuration
  set {
    name  = "falcon-sensor.enabled"
    value = "true"
  }

  set {
    name  = "falcon-sensor.nameOverride"
    value = "falcon-sensor"
  }

  set {
    name  = "falcon-sensor.fullnameOverride"
    value = "falcon-sensor"
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
    value = "registry.crowdstrike.com/falcon-sensor/release/falcon-sensor"
  }

  set {
    name  = "falcon-sensor.node.image.tag"
    value = var.falcon_sensor_version
  }

  set {
    name  = "falcon-sensor.node.image.pullSecrets"
    value = "crowdstrike-pull-secret"
  }

  # Falcon KAC Configuration
  set {
    name  = "falcon-kac.enabled"
    value = "true"
  }

  set {
    name  = "falcon-kac.nameOverride"
    value = "falcon-kac"
  }

  set {
    name  = "falcon-kac.fullnameOverride"
    value = "falcon-kac"
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
    name  = "falcon-kac.falcon.cloud"
    value = var.falcon_cloud_region
  }

  set {
    name  = "falcon-kac.image.repository"
    value = "registry.crowdstrike.com/falcon-kac/release/falcon-kac"
  }

  set {
    name  = "falcon-kac.image.tag"
    value = var.falcon_kac_version
  }

  set {
    name  = "falcon-kac.image.pullSecrets"
    value = "crowdstrike-pull-secret"
  }

  # Falcon Image Analyzer Configuration
  set {
    name  = "falcon-image-analyzer.enabled"
    value = "true"
  }

  set {
    name  = "falcon-image-analyzer.nameOverride"
    value = "falcon-image-analyzer"
  }

  set {
    name  = "falcon-image-analyzer.fullnameOverride"
    value = "falcon-image-analyzer"
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
    value = "registry.crowdstrike.com/falcon-imageanalyzer/${var.falcon_cloud_region}/release/falcon-imageanalyzer"
  }

  set {
    name  = "falcon-image-analyzer.image.tag"
    value = var.falcon_iar_version
  }

  set {
    name  = "falcon-image-analyzer.image.pullSecrets"
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

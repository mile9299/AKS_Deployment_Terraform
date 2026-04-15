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
    name  = "falcon-sensor.node.image.pullSecrets"
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
    name  = "falcon-kac.image.pullSecrets"
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

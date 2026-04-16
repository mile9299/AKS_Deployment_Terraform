output "falcon_platform_status" {
  description = "Falcon Platform deployment status"
  value       = helm_release.falcon_platform.status
}

output "falcon_platform_version" {
  description = "Deployed Falcon Platform Helm chart version"
  value       = helm_release.falcon_platform.version
}

output "falcon_sensor_namespace" {
  description = "Namespace where Falcon Sensor is deployed"
  value       = "falcon-system"
}

output "falcon_kac_namespace" {
  description = "Namespace where Falcon KAC is deployed"
  value       = "falcon-kac"
}

output "falcon_iar_namespace" {
  description = "Namespace where Falcon IAR is deployed"
  value       = "falcon-image-analyzer"
}

output "cluster_resource_id" {
  description = "Full Azure Resource ID used for KAC and IAR cluster identification"
  value       = data.azurerm_kubernetes_cluster.aks.id
}

output "deployment_notes" {
  description = "Post-deployment verification commands"
  value       = <<-EOT
    Verify deployments with:

    # Check Falcon Sensor (DaemonSet)
    kubectl get daemonset -n falcon-system
    kubectl get pods -n falcon-system

    # Check Falcon KAC
    kubectl get deployment -n falcon-kac
    kubectl get pods -n falcon-kac

    # Check Falcon IAR
    kubectl get deployment -n falcon-image-analyzer
    kubectl get pods -n falcon-image-analyzer

    # Check KAC cluster registration
    kubectl get configmap falcon-kac-meta -n falcon-kac -o yaml

    # Check KAC logs
    kubectl logs -n falcon-kac -l app.kubernetes.io/name=falcon-kac -c falcon-watcher --tail=50
  EOT
}

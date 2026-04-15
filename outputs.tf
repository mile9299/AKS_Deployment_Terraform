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
  value       = "falcon-imageanalyzer"
}

output "deployment_notes" {
  description = "Post-deployment verification commands"
  value = <<-EOT
    Verify deployments with:
    
    # Check Falcon Sensor (DaemonSet)
    kubectl get daemonset -n falcon-system
    kubectl get pods -n falcon-system
    
    # Check Falcon KAC
    kubectl get deployment -n falcon-kac
    kubectl get pods -n falcon-kac
    
    # Check Falcon IAR
    kubectl get deployment -n falcon-imageanalyzer
    kubectl get pods -n falcon-imageanalyzer
  EOT
}

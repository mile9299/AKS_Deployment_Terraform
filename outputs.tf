output "falcon_sensor_status" {
  description = "Falcon Sensor deployment status"
  value       = helm_release.falcon_sensor.status
}

output "falcon_kac_status" {
  description = "Falcon KAC deployment status"
  value       = helm_release.falcon_kac.status
}

output "falcon_iar_status" {
  description = "Falcon IAR deployment status"
  value       = helm_release.falcon_iar.status
}

output "falcon_sensor_namespace" {
  value = "falcon-system"
}

output "falcon_kac_namespace" {
  value = "falcon-kac"
}

output "falcon_iar_namespace" {
  value = "falcon-image-analyzer"
}

output "cluster_resource_id_falcon" {
  description = "Cluster Resource ID in Falcon format"
  value       = local.cluster_resource_id_falcon
}

output "deployment_notes" {
  value = <<-EOT
    Verify deployments:

    kubectl get pods -n falcon-system
    kubectl get pods -n falcon-kac
    kubectl get pods -n falcon-image-analyzer

    Check RFM state:
    kubectl exec -n falcon-system \
      $(kubectl get pods -n falcon-system -o jsonpath='{.items[0].metadata.name}') \
      -c falcon-node-sensor -- \
      /opt/CrowdStrike/falconctl -g --rfm-state --aid
  EOT
}

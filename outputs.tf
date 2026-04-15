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

output "namespace" {
  description = "Namespace where Falcon components are deployed"
  value       = "falcon-system"
}

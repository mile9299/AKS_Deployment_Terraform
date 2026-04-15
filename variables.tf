variable "resource_group_name" {
  description = "Azure Resource Group name where AKS cluster exists"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the existing AKS cluster"
  type        = string
}

variable "falcon_client_id" {
  description = "Falcon API Client ID"
  type        = string
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "Falcon API Client Secret"
  type        = string
  sensitive   = true
}

variable "falcon_cid" {
  description = "Falcon Customer ID (CID)"
  type        = string
}

variable "falcon_cloud_region" {
  description = "Falcon Cloud Region (us-1, us-2, eu-1, us-gov-1)"
  type        = string
  default     = "us-1"
}

variable "falcon_image_registry" {
  description = "Falcon container registry"
  type        = string
  default     = "registry.crowdstrike.com"
}

variable "falcon_sensor_version" {
  description = "Falcon Sensor Helm chart version"
  type        = string
  default     = "latest"
}

variable "falcon_kac_version" {
  description = "Falcon KAC Helm chart version"
  type        = string
  default     = "latest"
}

variable "falcon_iar_version" {
  description = "Falcon IAR Helm chart version"
  type        = string
  default     = "latest"
}

variable "falcon_tags" {
  description = "Tags to apply to Falcon sensor"
  type        = string
  default     = ""
}

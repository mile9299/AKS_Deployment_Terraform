variable "resource_group_name" {
  description = "Azure Resource Group name where AKS cluster exists"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the existing AKS cluster"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
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

variable "falcon_registry_pull_token" {
  description = "CrowdStrike Registry Pull Token for Sensor (--type falcon-sensor --get-pull-token)"
  type        = string
  sensitive   = true
}

variable "falcon_kac_pull_token" {
  description = "CrowdStrike Registry Pull Token for KAC (--type falcon-kac --get-pull-token)"
  type        = string
  sensitive   = true
}

variable "falcon_iar_pull_token" {
  description = "CrowdStrike Registry Pull Token for IAR (--type falcon-imageanalyzer --get-pull-token)"
  type        = string
  sensitive   = true
}

variable "falcon_cid" {
  description = "Falcon Customer ID (CID) with checksum"
  type        = string
}

variable "falcon_cloud_region" {
  description = "Falcon Cloud Region (us-1, us-2, eu-1, us-gov-1)"
  type        = string
  default     = "us-1"
}

variable "falcon_platform_version" {
  description = "Falcon Platform Helm chart version (leave empty for latest)"
  type        = string
  default     = ""
}

variable "falcon_sensor_version" {
  description = "Falcon Sensor image version"
  type        = string
  default     = "7.35.0-18803-1"
}

variable "falcon_kac_version" {
  description = "Falcon KAC image version"
  type        = string
  default     = "7.36.0-3401"
}

variable "falcon_iar_version" {
  description = "Falcon Image Analyzer version"
  type        = string
  default     = "1.0.23"
}

variable "falcon_tags" {
  description = "Tags to apply to Falcon sensor"
  type        = string
  default     = ""
}

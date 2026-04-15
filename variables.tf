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
  description = "Falcon Platform Helm chart version"
  type        = string
  default     = ""  # Empty string uses latest stable version
}

variable "falcon_tags" {
  description = "Tags to apply to Falcon sensor (comma-separated)"
  type        = string
  default     = ""
}

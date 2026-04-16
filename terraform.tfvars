resource_group_name      = "TedsAKS_group"
aks_cluster_name         = "TedsAKS-9"
azure_subscription_id    = ""

# Falcon API Credentials
falcon_client_id         = "your-api-client-id"
falcon_client_secret     = "your-api-client-secret"

# Registry Pull Token (base64 encoded - same for all components)
# Sensor uses it as-is (base64), KAC and IAR use it decoded
falcon_registry_pull_token = ""

# Falcon Configuration
falcon_cid               = ""
falcon_cloud_region      = "us-1"
falcon_platform_version  = ""

# Component Versions
falcon_sensor_version    = "7.35.0-18803-1"
falcon_kac_version       = "7.36.0-3401"
falcon_iar_version       = "1.0.23"

falcon_tags              = "env:production,cloud:azure,cluster:TedsAKS-9"

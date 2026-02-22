# =============================================================================
# 本地变量
# =============================================================================

locals {
  # 通用标签
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "ZhaoChaoqun"
      CostCenter  = "Personal"
    },
    var.extra_tags
  )

  # 环境特定配置
  env_config = {
    dev = {
      app_service_sku       = "B1"
      postgresql_sku        = "B_Standard_B1ms"
      postgresql_storage_mb = 32768
    }
    staging = {
      app_service_sku       = "B1"
      postgresql_sku        = "B_Standard_B1ms"
      postgresql_storage_mb = 32768
    }
    prod = {
      app_service_sku       = "B2"
      postgresql_sku        = "B_Standard_B2s"
      postgresql_storage_mb = 65536
    }
  }

  # 当前环境配置
  current_env_config = local.env_config[var.environment]
}

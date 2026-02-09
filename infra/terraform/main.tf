# =============================================================================
# FoodMoment Azure Infrastructure
# 预算: $150/月
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # 可选：远程状态存储（生产环境建议启用）
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatefoodmoment"
  #   container_name       = "tfstate"
  #   key                  = "foodmoment.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# -----------------------------------------------------------------------------
# 数据源
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# 随机后缀（确保资源名称唯一）
# -----------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# 资源组
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# 虚拟网络
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

# 子网 - App Service
resource "azurerm_subnet" "app_service" {
  name                 = "snet-app-service"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# 子网 - 数据库
resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# 子网 - Redis
resource "azurerm_subnet" "redis" {
  name                 = "snet-redis"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# 子网 - 私有端点
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]
}

# -----------------------------------------------------------------------------
# 私有 DNS 区域
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# 预估成本: ~$25-40/月 (Burstable B1ms)
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  delegated_subnet_id    = azurerm_subnet.database.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  # Burstable B1ms: 1 vCore, 2GB RAM - 适合开发/小规模生产
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768  # 32GB
  storage_tier           = "P4"

  backup_retention_days  = 7
  geo_redundant_backup_enabled = false

  zone = "1"

  tags = local.common_tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# PostgreSQL 数据库
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "foodmoment"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# PostgreSQL 配置
resource "azurerm_postgresql_flexible_server_configuration" "timezone" {
  name      = "timezone"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "UTC"
}

# -----------------------------------------------------------------------------
# Redis Cache
# 预估成本: ~$16/月 (Basic C0)
# -----------------------------------------------------------------------------

resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Basic C0: 250MB, 适合开发/小规模
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"

  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Storage Account (Blob - 图片存储)
# 预估成本: ~$5-10/月 (取决于存储量和流量)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = "st${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # 本地冗余，节省成本
  account_kind             = "StorageV2"

  # 启用 Blob 公共访问（用于 CDN）
  allow_nested_items_to_be_public = true

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "PUT", "POST"]
      allowed_origins    = var.cors_allowed_origins
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }

    delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# Blob 容器 - 用户上传
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"  # 公开读取
}

# Blob 容器 - 用户头像
resource "azurerm_storage_container" "avatars" {
  name                  = "avatars"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"
}

# Blob 容器 - 产品图片
resource "azurerm_storage_container" "products" {
  name                  = "products"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"
}

# Blob 容器 - 临时文件
resource "azurerm_storage_container" "temp" {
  name                  = "temp"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# 生命周期管理 - 自动清理临时文件
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "delete-temp-files"
    enabled = true

    filters {
      prefix_match = ["temp/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
    }
  }
}

# -----------------------------------------------------------------------------
# App Service Plan
# 预估成本: ~$55/月 (B1)
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # B1: 1 vCore, 1.75GB RAM - 适合小规模生产
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# App Service (Web App - FastAPI)
# 包含在 App Service Plan 中
# -----------------------------------------------------------------------------

resource "azurerm_linux_web_app" "api" {
  name                = "app-${var.project_name}-api-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  https_only = true

  site_config {
    always_on        = true
    ftps_state       = "Disabled"
    http2_enabled    = true
    minimum_tls_version = "1.2"

    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = true
    }
  }

  app_settings = {
    # 应用配置
    "APP_NAME"                    = "FoodMoment API"
    "DEBUG"                       = var.environment == "dev" ? "true" : "false"
    "API_V1_PREFIX"               = "/api/v1"

    # 数据库
    "DATABASE_URL"                = "postgresql+asyncpg://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/foodmoment"

    # Redis
    "REDIS_URL"                   = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}/0"

    # JWT (从 Key Vault 引用)
    "JWT_SECRET_KEY"              = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=jwt-secret-key)"
    "JWT_ALGORITHM"               = "HS256"
    "ACCESS_TOKEN_EXPIRE_MINUTES" = "10080"

    # AI 服务 (从 Key Vault 引用)
    "GEMINI_API_KEY"              = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=gemini-api-key)"
    "OPENAI_API_KEY"              = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=openai-api-key)"
    "AI_PROVIDER"                 = "gemini"

    # Azure Storage
    "AZURE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.main.primary_connection_string
    "AZURE_STORAGE_ACCOUNT_NAME"      = azurerm_storage_account.main.name
    "AZURE_STORAGE_CONTAINER_UPLOADS" = azurerm_storage_container.uploads.name
    "AZURE_CDN_ENDPOINT"              = var.enable_cdn ? "https://${azurerm_cdn_endpoint.main[0].fqdn}" : "https://${azurerm_storage_account.main.name}.blob.core.windows.net"

    # 日志
    "LOG_LEVEL"                   = var.environment == "dev" ? "DEBUG" : "INFO"

    # Python 配置
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "WEBSITES_PORT"                  = "8000"
  }

  identity {
    type = "SystemAssigned"
  }

  virtual_network_subnet_id = azurerm_subnet.app_service.id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Key Vault
# 预估成本: ~$0.03/10000 操作（基本免费）
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  tags = local.common_tags
}

# Key Vault 访问策略 - 当前用户
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# Key Vault 访问策略 - App Service
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.api.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret-key"
  value        = var.jwt_secret_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "gemini_api_key" {
  name         = "gemini-api-key"
  value        = var.gemini_api_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "openai_api_key" {
  name         = "openai-api-key"
  value        = var.openai_api_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# -----------------------------------------------------------------------------
# CDN (可选)
# 预估成本: ~$20-30/月 (取决于流量)
# -----------------------------------------------------------------------------

resource "azurerm_cdn_profile" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = "cdn-${var.project_name}-${var.environment}"
  location            = "global"
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"

  tags = local.common_tags
}

resource "azurerm_cdn_endpoint" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = "cdne-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  profile_name        = azurerm_cdn_profile.main[0].name
  location            = "global"
  resource_group_name = azurerm_resource_group.main.name

  origin {
    name      = "blob-origin"
    host_name = azurerm_storage_account.main.primary_blob_host
  }

  origin_host_header = azurerm_storage_account.main.primary_blob_host

  is_compression_enabled = true
  content_types_to_compress = [
    "application/json",
    "text/plain",
    "text/css",
    "application/javascript",
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Application Insights (监控)
# 预估成本: ~$2-5/月 (基于数据量)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.common_tags
}

# 将 Application Insights 连接字符串添加到 App Service
resource "azurerm_linux_web_app_slot" "staging" {
  count          = var.environment == "prod" ? 1 : 0
  name           = "staging"
  app_service_id = azurerm_linux_web_app.api.id

  site_config {
    always_on     = false
    http2_enabled = true

    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = azurerm_linux_web_app.api.app_settings

  tags = local.common_tags
}

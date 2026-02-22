# =============================================================================
# FoodMoment Azure Infrastructure
# Phase 1: MVP 部署（F1 免费层 + PostgreSQL 公网访问）
# 预估月费: ~$30
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
# PostgreSQL Flexible Server（公网访问模式）
# 预估成本: ~$25/月 (Burstable B1ms)
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  # Burstable B1ms: 1 vCore, 2GB RAM
  sku_name               = local.current_env_config.postgresql_sku
  storage_mb             = local.current_env_config.postgresql_storage_mb
  storage_tier           = "P4"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  zone = "1"

  tags = local.common_tags
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

# 防火墙规则 - 允许 Azure 服务访问
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# Storage Account (Blob - 图片存储)
# 预估成本: ~$3/月
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = "st${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

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
  container_access_type = "blob"
}

# Blob 容器 - 用户头像
resource "azurerm_storage_container" "avatars" {
  name                  = "avatars"
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
# F1 免费层: 共享计算, 60 CPU min/天
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  os_type  = "Linux"
  sku_name = local.current_env_config.app_service_sku

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# App Service (Web App - FastAPI)
# -----------------------------------------------------------------------------

resource "azurerm_linux_web_app" "api" {
  name                = "app-${var.project_name}-api-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  https_only = true

  site_config {
    always_on         = true  # B1 支持 always-on
    ftps_state        = "Disabled"
    http2_enabled     = true
    minimum_tls_version = "1.2"
    health_check_path = "/health"

    application_stack {
      python_version = "3.12"
    }

    app_command_line = "gunicorn app.main:app -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --timeout 120"
  }

  app_settings = {
    # 应用配置
    "APP_NAME"                    = "FoodMoment API"
    "DEBUG"                       = var.environment == "dev" ? "true" : "false"
    "API_V1_PREFIX"               = "/api/v1"

    # 数据库 (公网访问)
    "DATABASE_URL" = "postgresql+asyncpg://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/foodmoment?ssl=require"

    # JWT (从 Key Vault 引用)
    "JWT_SECRET_KEY"              = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=jwt-secret-key)"
    "JWT_ALGORITHM"               = "HS256"
    "ACCESS_TOKEN_EXPIRE_MINUTES" = "10080"

    # AI 服务 - Anthropic Claude (via Agent Maestro proxy)
    "ANTHROPIC_BASE_URL"  = var.anthropic_base_url
    "ANTHROPIC_MODEL"     = "claude-opus-4.6-fast"
    "ANTHROPIC_ENABLED"   = "true"
    "ANTHROPIC_PROXY_KEY" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=anthropic-proxy-key)"

    # Azure Storage
    "AZURE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.main.primary_connection_string
    "AZURE_STORAGE_CONTAINER"         = azurerm_storage_container.uploads.name
    "STORAGE_PUBLIC_URL"              = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.uploads.name}"

    # 监控
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string

    # 日志
    "LOG_LEVEL" = var.environment == "dev" ? "DEBUG" : "INFO"
    "LOG_DIR"   = "/home/LogFiles"

    # Python 构建配置
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "WEBSITES_PORT"                  = "8000"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

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

resource "azurerm_key_vault_secret" "anthropic_proxy_key" {
  name         = "anthropic-proxy-key"
  value        = var.anthropic_proxy_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# -----------------------------------------------------------------------------
# Application Insights (监控)
# 预估成本: ~$2/月
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

# =============================================================================
# 输出值
# =============================================================================

# -----------------------------------------------------------------------------
# 资源组
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "资源组名称"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "资源组位置"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

output "postgresql_server_name" {
  description = "PostgreSQL 服务器名称"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_server_fqdn" {
  description = "PostgreSQL 服务器 FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database_name" {
  description = "PostgreSQL 数据库名称"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "postgresql_connection_string" {
  description = "PostgreSQL 连接字符串（不含密码）"
  value       = "postgresql+asyncpg://${var.db_admin_username}:<PASSWORD>@${azurerm_postgresql_flexible_server.main.fqdn}:5432/foodmoment"
  sensitive   = false
}

# -----------------------------------------------------------------------------
# Redis
# -----------------------------------------------------------------------------

output "redis_hostname" {
  description = "Redis 主机名"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_ssl_port" {
  description = "Redis SSL 端口"
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_connection_string" {
  description = "Redis 连接字符串"
  value       = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}/0"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------

output "storage_account_name" {
  description = "存储账户名称"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Blob 存储主端点"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_connection_string" {
  description = "存储账户连接字符串"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_container_uploads" {
  description = "上传容器 URL"
  value       = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.uploads.name}"
}

# -----------------------------------------------------------------------------
# App Service
# -----------------------------------------------------------------------------

output "app_service_name" {
  description = "App Service 名称"
  value       = azurerm_linux_web_app.api.name
}

output "app_service_default_hostname" {
  description = "App Service 默认主机名"
  value       = azurerm_linux_web_app.api.default_hostname
}

output "app_service_url" {
  description = "API 服务 URL"
  value       = "https://${azurerm_linux_web_app.api.default_hostname}"
}

output "app_service_principal_id" {
  description = "App Service 托管标识 ID"
  value       = azurerm_linux_web_app.api.identity[0].principal_id
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

output "key_vault_name" {
  description = "Key Vault 名称"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

# -----------------------------------------------------------------------------
# CDN (可选)
# -----------------------------------------------------------------------------

output "cdn_endpoint_hostname" {
  description = "CDN 端点主机名"
  value       = var.enable_cdn ? azurerm_cdn_endpoint.main[0].fqdn : null
}

output "cdn_endpoint_url" {
  description = "CDN 端点 URL"
  value       = var.enable_cdn ? "https://${azurerm_cdn_endpoint.main[0].fqdn}" : null
}

# -----------------------------------------------------------------------------
# Application Insights
# -----------------------------------------------------------------------------

output "application_insights_name" {
  description = "Application Insights 名称"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights 连接字符串"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# 汇总信息
# -----------------------------------------------------------------------------

output "summary" {
  description = "部署摘要"
  value = <<-EOT

  ============================================================
  FoodMoment Azure 基础设施部署完成
  ============================================================

  环境: ${var.environment}
  区域: ${var.location}

  API 服务:
    URL: https://${azurerm_linux_web_app.api.default_hostname}
    健康检查: https://${azurerm_linux_web_app.api.default_hostname}/health

  数据库:
    主机: ${azurerm_postgresql_flexible_server.main.fqdn}
    数据库: foodmoment
    用户: ${var.db_admin_username}

  Redis:
    主机: ${azurerm_redis_cache.main.hostname}
    端口: ${azurerm_redis_cache.main.ssl_port} (SSL)

  存储:
    Blob 端点: ${azurerm_storage_account.main.primary_blob_endpoint}
    CDN: ${var.enable_cdn ? "https://${azurerm_cdn_endpoint.main[0].fqdn}" : "未启用"}

  Key Vault:
    URI: ${azurerm_key_vault.main.vault_uri}

  监控:
    Application Insights: ${azurerm_application_insights.main.name}

  ============================================================
  EOT
}

# =============================================================================
# 变量定义
# =============================================================================

# -----------------------------------------------------------------------------
# 基础配置
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "项目名称，用于资源命名"
  type        = string
  default     = "foodmoment"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "项目名称只能包含小写字母和数字"
  }
}

variable "environment" {
  description = "环境名称 (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "环境必须是 dev, staging 或 prod"
  }
}

variable "location" {
  description = "Azure 区域"
  type        = string
  default     = "eastasia"  # 香港，延迟较低
}

# -----------------------------------------------------------------------------
# 数据库配置
# -----------------------------------------------------------------------------

variable "db_admin_username" {
  description = "PostgreSQL 管理员用户名"
  type        = string
  default     = "fmadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]+$", var.db_admin_username))
    error_message = "用户名必须以字母开头，只能包含字母、数字和下划线"
  }
}

variable "db_admin_password" {
  description = "PostgreSQL 管理员密码"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_admin_password) >= 12
    error_message = "密码长度至少为 12 个字符"
  }
}

# -----------------------------------------------------------------------------
# JWT 配置
# -----------------------------------------------------------------------------

variable "jwt_secret_key" {
  description = "JWT 签名密钥"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret_key) >= 32
    error_message = "JWT 密钥长度至少为 32 个字符"
  }
}

# -----------------------------------------------------------------------------
# AI 服务配置
# -----------------------------------------------------------------------------

variable "gemini_api_key" {
  description = "Google Gemini API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
  default     = ""
}

# -----------------------------------------------------------------------------
# CORS 配置
# -----------------------------------------------------------------------------

variable "cors_allowed_origins" {
  description = "CORS 允许的源"
  type        = list(string)
  default     = ["*"]
}

# -----------------------------------------------------------------------------
# 可选功能
# -----------------------------------------------------------------------------

variable "enable_cdn" {
  description = "是否启用 CDN（会增加约 $20-30/月成本）"
  type        = bool
  default     = false
}

variable "enable_staging_slot" {
  description = "是否启用 staging 部署槽（仅 prod 环境）"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# 标签
# -----------------------------------------------------------------------------

variable "extra_tags" {
  description = "额外的资源标签"
  type        = map(string)
  default     = {}
}

# FoodMoment Azure Infrastructure

## 概述

本目录包含 FoodMoment 后端服务在 Azure 上的基础设施即代码 (IaC) 配置。

## 预算规划 ($150/月)

| 资源 | SKU | 预估月费用 |
|------|-----|-----------|
| App Service Plan | B1 (1 vCore, 1.75GB) | ~$55 |
| PostgreSQL Flexible | B1ms (1 vCore, 2GB) | ~$25 |
| Redis Cache | Basic C0 (250MB) | ~$16 |
| Storage Account | Standard LRS | ~$5 |
| Application Insights | 基础用量 | ~$3 |
| Key Vault | 标准 | ~$0.03 |
| **总计** | | **~$104** |
| **预留空间** | CDN/流量/突发 | ~$46 |

## 前置要求

1. **Azure CLI**
   ```bash
   # macOS
   brew install azure-cli

   # 登录
   az login
   ```

2. **Terraform**
   ```bash
   # macOS
   brew install terraform

   # 验证
   terraform version
   ```

3. **确认订阅**
   ```bash
   # 查看当前订阅
   az account show

   # 列出所有订阅
   az account list -o table

   # 切换订阅（如需要）
   az account set --subscription "Your Subscription Name"
   ```

## 快速开始

### 1. 配置变量

```bash
cd infra/terraform

# 复制示例配置
cp terraform.tfvars.example terraform.tfvars

# 编辑配置（必须修改密码和密钥）
vim terraform.tfvars
```

**必须修改的值：**
- `db_admin_password`: PostgreSQL 管理员密码（至少 12 字符）
- `jwt_secret_key`: JWT 签名密钥（至少 32 字符）
- `gemini_api_key`: Google Gemini API Key（可选）
- `openai_api_key`: OpenAI API Key（可选）

### 2. 初始化 Terraform

```bash
terraform init
```

### 3. 预览变更

```bash
terraform plan
```

### 4. 部署资源

```bash
terraform apply
```

输入 `yes` 确认部署。

### 5. 查看输出

```bash
terraform output

# 查看敏感信息
terraform output -json redis_connection_string
```

## 部署后配置

### 1. 部署 FastAPI 应用

```bash
# 使用 Azure CLI 部署
cd ../../backend

# 创建部署包
zip -r deploy.zip . -x "*.pyc" -x "__pycache__/*" -x ".env" -x "venv/*"

# 部署到 App Service
az webapp deploy \
  --resource-group rg-foodmoment-dev \
  --name $(terraform output -raw app_service_name) \
  --src-path deploy.zip
```

### 2. 运行数据库迁移

```bash
# 通过 App Service SSH 或本地连接运行
alembic upgrade head
```

### 3. 配置自定义域名（可选）

```bash
# 添加自定义域名
az webapp config hostname add \
  --webapp-name $(terraform output -raw app_service_name) \
  --resource-group rg-foodmoment-dev \
  --hostname api.foodmoment.app

# 绑定 SSL 证书
az webapp config ssl bind \
  --certificate-thumbprint <THUMBPRINT> \
  --ssl-type SNI \
  --name $(terraform output -raw app_service_name) \
  --resource-group rg-foodmoment-dev
```

## 资源说明

### 网络架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Virtual Network (10.0.0.0/16)            │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ snet-app-service│  │  snet-database  │                  │
│  │   10.0.1.0/24   │  │   10.0.2.0/24   │                  │
│  │                 │  │                 │                  │
│  │  ┌───────────┐  │  │  ┌───────────┐  │                  │
│  │  │ App       │  │  │  │ PostgreSQL│  │                  │
│  │  │ Service   │──────│  │ Flexible  │  │                  │
│  │  └───────────┘  │  │  └───────────┘  │                  │
│  └─────────────────┘  └─────────────────┘                  │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   snet-redis    │  │ snet-private-ep │                  │
│  │   10.0.3.0/24   │  │   10.0.4.0/24   │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Vault Secrets

| Secret 名称 | 用途 |
|------------|------|
| `jwt-secret-key` | JWT 签名密钥 |
| `gemini-api-key` | Google Gemini API |
| `openai-api-key` | OpenAI API |

### Storage Containers

| 容器名 | 访问级别 | 用途 |
|--------|---------|------|
| `uploads` | Blob (公开读) | 用户上传的食物图片 |
| `avatars` | Blob (公开读) | 用户头像 |
| `products` | Blob (公开读) | 预包装食品图片 |
| `temp` | Private | 临时文件（24h 自动清理） |

## 常用命令

```bash
# 查看所有资源
terraform state list

# 查看特定资源详情
terraform state show azurerm_linux_web_app.api

# 仅更新特定资源
terraform apply -target=azurerm_linux_web_app.api

# 销毁所有资源（谨慎！）
terraform destroy

# 导入现有资源
terraform import azurerm_resource_group.main /subscriptions/<sub-id>/resourceGroups/rg-foodmoment-dev
```

## 故障排除

### 1. PostgreSQL 连接失败

确保 App Service 在同一 VNet 中并且正确配置了私有 DNS：

```bash
# 检查 DNS 解析
az network private-dns record-set list \
  --zone-name privatelink.postgres.database.azure.com \
  --resource-group rg-foodmoment-dev
```

### 2. Key Vault 权限问题

确保 App Service 的托管标识有访问权限：

```bash
# 获取 App Service 标识
az webapp identity show \
  --name $(terraform output -raw app_service_name) \
  --resource-group rg-foodmoment-dev
```

### 3. Redis 连接超时

确保使用 SSL 连接（端口 6380）：

```bash
# 测试连接
redis-cli -h <hostname> -p 6380 -a <password> --tls ping
```

## 扩展指南

### 启用 CDN

```hcl
# 在 terraform.tfvars 中
enable_cdn = true
```

### 升级到生产环境

```hcl
# 在 terraform.tfvars 中
environment = "prod"
```

这将自动升级：
- App Service: B1 → B2
- PostgreSQL: B1ms → B2s
- Redis: Basic C0 → Standard C1

## 安全注意事项

1. **不要提交敏感信息**
   - `terraform.tfvars` 已在 `.gitignore` 中
   - 使用 Azure Key Vault 存储密钥

2. **定期轮换密钥**
   - JWT 密钥
   - 数据库密码
   - API 密钥

3. **启用日志审计**
   - Application Insights 已配置
   - 考虑启用 Azure Security Center

## 支持

如有问题，请提交 Issue 或联系：
- GitHub: @ZhaoChaoqun

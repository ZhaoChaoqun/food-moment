# FoodMoment Azure Infrastructure

## 概述

本目录包含 FoodMoment 后端服务在 Azure 上的基础设施即代码 (IaC) 配置。

## Phase 1 架构（开发/测试）

- **App Service F1** (免费层) — FastAPI 后端
- **PostgreSQL Flexible Server** (B1ms) — 公网访问模式
- **Storage Account** (Standard LRS) — 图片/头像存储
- **Key Vault** — 密钥管理
- **Application Insights** — 监控

## 月费预估

| 资源 | SKU | 预估月费用 |
|------|-----|-----------|
| App Service Plan | F1 (免费) | $0 |
| PostgreSQL Flexible | B1ms (1 vCore, 2GB) | ~$25 |
| Storage Account | Standard LRS | ~$3 |
| Application Insights | 基础用量 | ~$2 |
| Key Vault | 标准 | ~$0 |
| **总计** | | **~$30** |

## 前置要求

1. **Azure CLI**
   ```bash
   brew install azure-cli
   az login
   ```

2. **Terraform**
   ```bash
   brew install terraform
   terraform version
   ```

## 快速开始

### 1. 配置变量

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

**必须修改的值：**
- `db_admin_password`: PostgreSQL 管理员密码（至少 12 字符）
- `jwt_secret_key`: JWT 签名密钥（至少 32 字符）
- `anthropic_base_url`: Agent Maestro ngrok 地址（可选，留空使用 mock）
- `anthropic_proxy_key`: Agent Maestro proxy key（可选）

### 2. 部署

```bash
./deploy.sh deploy
```

### 3. 部署后端代码

```bash
cd ../../backend
uv export --format requirements-txt --no-hashes > requirements.txt
zip -r ../deploy.zip . -x "*.pyc" "__pycache__/*" ".env" ".venv/*" "uv.lock" "logs/*" ".python-version"
az webapp deploy \
  --resource-group rg-foodmoment-dev \
  --name $(cd ../infra/terraform && terraform output -raw app_service_name) \
  --src-path ../deploy.zip
```

### 4. 验证

```bash
# 查看部署信息
terraform output summary

# 检查 API
curl https://$(terraform output -raw app_service_default_hostname)/health
```

## F1 免费层注意事项

- 每天 60 CPU 分钟限制
- 无 always-on（闲置后冷启动 10-20s）
- 无自定义域名/自有 SSL
- 升级只需改 `sku_name` 为 `"B1"` 并 `terraform apply`

## 常用命令

```bash
terraform state list           # 查看所有资源
terraform plan                 # 预览变更
terraform apply                # 执行变更
terraform output               # 查看输出
terraform destroy              # 销毁所有资源
```

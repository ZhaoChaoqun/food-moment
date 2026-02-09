#!/bin/bash

# =============================================================================
# FoodMoment Azure 基础设施部署脚本
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR"

# 打印带颜色的消息
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查依赖
check_dependencies() {
    info "检查依赖..."

    if ! command -v az &> /dev/null; then
        error "Azure CLI 未安装。请运行: brew install azure-cli"
    fi

    if ! command -v terraform &> /dev/null; then
        error "Terraform 未安装。请运行: brew install terraform"
    fi

    success "所有依赖已安装"
}

# 检查 Azure 登录状态
check_azure_login() {
    info "检查 Azure 登录状态..."

    if ! az account show &> /dev/null; then
        warning "未登录 Azure，正在启动登录..."
        az login
    fi

    SUBSCRIPTION=$(az account show --query name -o tsv)
    info "当前订阅: $SUBSCRIPTION"

    read -p "是否继续使用此订阅? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "可用订阅:"
        az account list -o table
        read -p "请输入要使用的订阅名称: " SUB_NAME
        az account set --subscription "$SUB_NAME"
        success "已切换到订阅: $SUB_NAME"
    fi
}

# 检查 tfvars 文件
check_tfvars() {
    info "检查配置文件..."

    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        warning "terraform.tfvars 不存在，正在从示例文件创建..."
        cp "$TERRAFORM_DIR/terraform.tfvars.example" "$TERRAFORM_DIR/terraform.tfvars"
        warning "请编辑 terraform.tfvars 文件，配置必要的密码和密钥"
        echo ""
        echo "必须修改的配置项："
        echo "  - db_admin_password: PostgreSQL 密码 (至少 12 字符)"
        echo "  - jwt_secret_key: JWT 密钥 (至少 32 字符)"
        echo ""
        read -p "按 Enter 继续编辑配置文件..."
        ${EDITOR:-vim} "$TERRAFORM_DIR/terraform.tfvars"
    fi

    success "配置文件已就绪"
}

# 初始化 Terraform
terraform_init() {
    info "初始化 Terraform..."
    cd "$TERRAFORM_DIR"
    terraform init -upgrade
    success "Terraform 初始化完成"
}

# 验证配置
terraform_validate() {
    info "验证 Terraform 配置..."
    cd "$TERRAFORM_DIR"
    terraform validate
    success "配置验证通过"
}

# 计划部署
terraform_plan() {
    info "生成部署计划..."
    cd "$TERRAFORM_DIR"
    terraform plan -out=tfplan
    success "部署计划已生成"
}

# 执行部署
terraform_apply() {
    info "执行部署..."
    cd "$TERRAFORM_DIR"

    if [ -f "tfplan" ]; then
        terraform apply tfplan
        rm -f tfplan
    else
        terraform apply
    fi

    success "部署完成！"
}

# 显示输出
show_outputs() {
    info "部署信息:"
    cd "$TERRAFORM_DIR"
    terraform output summary
}

# 销毁资源
terraform_destroy() {
    warning "警告: 此操作将销毁所有 Azure 资源！"
    read -p "确定要继续吗? 输入 'destroy' 确认: " CONFIRM

    if [ "$CONFIRM" == "destroy" ]; then
        cd "$TERRAFORM_DIR"
        terraform destroy
        success "所有资源已销毁"
    else
        info "操作已取消"
    fi
}

# 生成安全密码
generate_password() {
    openssl rand -base64 24 | tr -dc 'a-zA-Z0-9!@#$%' | head -c 20
}

# 生成 JWT 密钥
generate_jwt_secret() {
    openssl rand -base64 48
}

# 帮助信息
show_help() {
    echo ""
    echo "FoodMoment Azure 基础设施部署脚本"
    echo ""
    echo "用法: $0 <command>"
    echo ""
    echo "命令:"
    echo "  init        初始化 Terraform"
    echo "  plan        生成部署计划"
    echo "  apply       执行部署"
    echo "  deploy      完整部署流程 (init + plan + apply)"
    echo "  destroy     销毁所有资源"
    echo "  output      显示部署输出"
    echo "  gen-pass    生成安全密码"
    echo "  gen-jwt     生成 JWT 密钥"
    echo "  help        显示此帮助信息"
    echo ""
}

# 完整部署流程
full_deploy() {
    check_dependencies
    check_azure_login
    check_tfvars
    terraform_init
    terraform_validate
    terraform_plan

    echo ""
    read -p "是否继续执行部署? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform_apply
        show_outputs
    else
        info "部署已取消。计划文件保留在 tfplan"
    fi
}

# 主函数
main() {
    case "${1:-}" in
        init)
            check_dependencies
            terraform_init
            ;;
        plan)
            check_dependencies
            terraform_plan
            ;;
        apply)
            check_dependencies
            terraform_apply
            show_outputs
            ;;
        deploy)
            full_deploy
            ;;
        destroy)
            check_dependencies
            terraform_destroy
            ;;
        output)
            show_outputs
            ;;
        gen-pass)
            echo "生成的密码: $(generate_password)"
            ;;
        gen-jwt)
            echo "生成的 JWT 密钥: $(generate_jwt_secret)"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"

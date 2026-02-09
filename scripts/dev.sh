#!/bin/bash

# =============================================================================
# FoodMoment 本地开发环境启动脚本
# 启动 Docker 服务 + FastAPI 后端 + ngrok 隧道
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查依赖
check_dependencies() {
    info "检查依赖..."

    if ! command -v docker &> /dev/null; then
        error "Docker 未安装。请先安装 Docker Desktop"
    fi

    if ! command -v ngrok &> /dev/null; then
        warning "ngrok 未安装，正在安装..."
        brew install ngrok
    fi

    if ! command -v uv &> /dev/null; then
        error "uv 未安装。请运行: curl -LsSf https://astral.sh/uv/install.sh | sh"
    fi

    success "依赖检查完成"
}

# 检查 ngrok 配置
check_ngrok_auth() {
    if ! ngrok config check &> /dev/null; then
        warning "ngrok 未配置 authtoken"
        echo ""
        echo "请按以下步骤操作："
        echo "1. 访问 https://dashboard.ngrok.com/signup 注册账号"
        echo "2. 获取 authtoken: https://dashboard.ngrok.com/get-started/your-authtoken"
        echo "3. 运行: ngrok config add-authtoken <your-token>"
        echo ""
        read -p "配置完成后按 Enter 继续..."
    fi
}

# 启动 Docker 服务
start_docker() {
    info "启动 Docker 服务..."
    cd "$PROJECT_ROOT"

    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        error "Docker 未运行，请先启动 Docker Desktop"
    fi

    docker-compose up -d

    # 等待服务就绪
    info "等待服务启动..."
    sleep 3

    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        success "Docker 服务已启动"
        echo ""
        echo "  PostgreSQL: localhost:5432"
        echo "  Redis:      localhost:6379"
        echo "  MinIO:      localhost:9000 (控制台: localhost:9001)"
    else
        error "Docker 服务启动失败"
    fi
}

# 初始化后端环境
init_backend() {
    info "初始化后端环境..."
    cd "$PROJECT_ROOT/backend"

    # 创建 .env 文件
    if [ ! -f ".env" ]; then
        cp .env.example .env
        success "已创建 .env 文件"
    fi

    # 安装依赖
    info "安装 Python 依赖..."
    uv sync

    success "后端环境就绪"
}

# 启动 ngrok
start_ngrok() {
    info "启动 ngrok 隧道..."

    # 检查是否已有 ngrok 进程
    if pgrep -x "ngrok" > /dev/null; then
        warning "ngrok 已在运行，正在重启..."
        pkill -x ngrok
        sleep 2
    fi

    # 后台启动 ngrok
    ngrok http 8000 --log=stdout > "$PROJECT_ROOT/.ngrok.log" 2>&1 &
    NGROK_PID=$!
    echo $NGROK_PID > "$PROJECT_ROOT/.ngrok.pid"

    # 等待 ngrok 启动（最多等待 15 秒）
    info "等待 ngrok 隧道建立..."
    NGROK_URL=""
    for i in {1..15}; do
        sleep 1
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"https://[^"]*' | cut -d'"' -f4)
        if [ -n "$NGROK_URL" ]; then
            break
        fi
        echo -n "."
    done
    echo ""

    if [ -z "$NGROK_URL" ]; then
        warning "无法自动获取 ngrok URL"
        echo ""
        echo "请手动检查："
        echo "  1. 打开 http://localhost:4040 查看 ngrok 状态"
        echo "  2. 或查看日志: cat $PROJECT_ROOT/.ngrok.log"
        echo ""
        echo "如果 ngrok 正常运行，稍后运行 ./scripts/dev.sh url 获取地址"
        echo ""
        return 0
    fi

    success "ngrok 隧道已建立"
    echo ""
    echo -e "  ${CYAN}公网地址: ${NGROK_URL}${NC}"
    echo -e "  ${CYAN}API 地址: ${NGROK_URL}/api/v1${NC}"
    echo ""

    # 保存 URL 到文件
    echo "$NGROK_URL" > "$PROJECT_ROOT/.ngrok.url"
}

# 启动后端服务
start_backend() {
    info "启动 FastAPI 后端..."
    cd "$PROJECT_ROOT/backend"

    echo ""
    echo "========================================"
    echo -e "${GREEN}所有服务已启动！${NC}"
    echo "========================================"
    echo ""
    echo "本地服务:"
    echo "  API 文档:    http://localhost:8000/docs"
    echo "  PostgreSQL:  localhost:5432"
    echo "  Redis:       localhost:6379"
    echo "  MinIO 控制台: http://localhost:9001"
    echo ""

    if [ -f "$PROJECT_ROOT/.ngrok.url" ]; then
        NGROK_URL=$(cat "$PROJECT_ROOT/.ngrok.url")
        echo "iOS 设备连接:"
        echo -e "  ${CYAN}API Base URL: ${NGROK_URL}/api/v1${NC}"
        echo ""
        echo "ngrok 管理面板: http://localhost:4040"
    fi

    echo ""
    echo "按 Ctrl+C 停止服务"
    echo "========================================"
    echo ""

    # 前台启动 uvicorn
    uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
}

# 停止所有服务
stop_all() {
    info "停止所有服务..."

    # 停止 ngrok
    if [ -f "$PROJECT_ROOT/.ngrok.pid" ]; then
        kill $(cat "$PROJECT_ROOT/.ngrok.pid") 2>/dev/null || true
        rm -f "$PROJECT_ROOT/.ngrok.pid" "$PROJECT_ROOT/.ngrok.url" "$PROJECT_ROOT/.ngrok.log"
    fi
    pkill -x ngrok 2>/dev/null || true

    # 停止 Docker
    cd "$PROJECT_ROOT"
    docker-compose down

    success "所有服务已停止"
}

# 清理函数
cleanup() {
    echo ""
    warning "正在停止服务..."
    if [ -f "$PROJECT_ROOT/.ngrok.pid" ]; then
        kill $(cat "$PROJECT_ROOT/.ngrok.pid") 2>/dev/null || true
        rm -f "$PROJECT_ROOT/.ngrok.pid" "$PROJECT_ROOT/.ngrok.url" "$PROJECT_ROOT/.ngrok.log"
    fi
    pkill -x ngrok 2>/dev/null || true
    info "ngrok 已停止。Docker 服务保持运行。"
    info "如需停止 Docker，运行: docker-compose down"
    exit 0
}

# 显示帮助
show_help() {
    echo ""
    echo "FoodMoment 开发环境启动脚本"
    echo ""
    echo "用法: $0 [command]"
    echo ""
    echo "命令:"
    echo "  start     启动所有服务 (默认)"
    echo "  stop      停止所有服务"
    echo "  restart   重启所有服务"
    echo "  status    查看服务状态"
    echo "  url       显示 ngrok URL"
    echo "  logs      查看后端日志"
    echo "  help      显示帮助"
    echo ""
}

# 查看状态
show_status() {
    echo ""
    echo "Docker 服务状态:"
    cd "$PROJECT_ROOT"
    docker-compose ps
    echo ""

    if [ -f "$PROJECT_ROOT/.ngrok.url" ]; then
        echo "ngrok URL: $(cat $PROJECT_ROOT/.ngrok.url)"
    else
        echo "ngrok: 未运行"
    fi
    echo ""
}

# 显示 ngrok URL
show_url() {
    if [ -f "$PROJECT_ROOT/.ngrok.url" ]; then
        NGROK_URL=$(cat "$PROJECT_ROOT/.ngrok.url")
        echo ""
        echo "========================================"
        echo "iOS App 配置"
        echo "========================================"
        echo ""
        echo "API Base URL:"
        echo -e "  ${CYAN}${NGROK_URL}/api/v1${NC}"
        echo ""
        echo "健康检查:"
        echo "  ${NGROK_URL}/health"
        echo ""
        echo "API 文档:"
        echo "  ${NGROK_URL}/docs"
        echo ""
        echo "========================================"
    else
        # 尝试从 ngrok API 获取
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"https://[^"]*' | cut -d'"' -f4)
        if [ -n "$NGROK_URL" ]; then
            echo "$NGROK_URL" > "$PROJECT_ROOT/.ngrok.url"
            show_url
        else
            warning "ngrok 未运行，请先执行: ./scripts/dev.sh start"
        fi
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            trap cleanup SIGINT SIGTERM
            check_dependencies
            check_ngrok_auth
            start_docker
            init_backend
            start_ngrok
            start_backend
            ;;
        stop)
            stop_all
            ;;
        restart)
            stop_all
            sleep 2
            main start
            ;;
        status)
            show_status
            ;;
        url)
            show_url
            ;;
        logs)
            cd "$PROJECT_ROOT/backend"
            tail -f logs/*.log 2>/dev/null || warning "暂无日志文件"
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

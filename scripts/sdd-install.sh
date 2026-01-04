#!/bin/bash
# IDRM SDD Templates - Self-Contained Install Script
# Version: 0.6.0
# Repository: github.com/jinguoxing/idrm-sdd-templates
#
# 使用方法:
#   远程执行: curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
#   本地执行: ./scripts/sdd-install.sh

set -e

VERSION="0.6.0"

# ============================================================================
# 公共函数 (内联自 lib/common.sh)
# ============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 输出函数
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_step() {
    echo -e "${CYAN}[$1]${NC} $2"
}

# 打印横幅
print_banner() {
    local version=$1
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${GREEN}IDRM SDD Template Installer v${version}${NC}                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         github.com/jinguoxing/idrm-sdd-templates             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 打印成功完成
print_complete() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                    ${GREEN}✅ 安装完成!${NC}                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 检查命令是否存在
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 读取用户输入（带默认值）- 支持管道模式
read_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -n "$default" ]; then
        if [ -t 0 ]; then
            # 终端模式，正常读取
            read -p "$prompt [$default]: " input </dev/tty
        else
            # 管道模式，使用默认值
            input=""
        fi
        eval "$var_name=\"${input:-$default}\""
    else
        if [ -t 0 ]; then
            read -p "$prompt: " input </dev/tty
        else
            input=""
        fi
        eval "$var_name=\"$input\""
    fi
}

# 读取密码输入
read_password() {
    local prompt=$1
    local var_name=$2
    
    if [ -t 0 ]; then
        read -sp "$prompt: " input </dev/tty
        echo ""
    else
        input=""
    fi
    eval "$var_name=\"$input\""
}

# 替换模板变量
replace_template_vars() {
    local file=$1
    shift
    local temp_file="${file}.tmp"
    
    cp "$file" "$temp_file"
    
    while [ $# -gt 0 ]; do
        local key=$1
        local value=$2
        shift 2
        
        # 使用 sed 替换变量
        sed -i.bak "s|{{${key}}}|${value}|g" "$temp_file"
        rm -f "${temp_file}.bak"
    done
    
    mv "$temp_file" "$file"
}

# 生成随机密钥
generate_secret() {
    openssl rand -hex 32 2>/dev/null || cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
}

# 确认操作
confirm() {
    local prompt=$1
    local default=${2:-Y}
    
    if [ ! -t 0 ]; then
        # 管道模式，自动确认
        return 0
    fi
    
    if [ "$default" = "Y" ]; then
        read -p "$prompt [Y/n]: " answer </dev/tty
        case $answer in
            [Nn]* ) return 1;;
            * ) return 0;;
        esac
    else
        read -p "$prompt [y/N]: " answer </dev/tty
        case $answer in
            [Yy]* ) return 0;;
            * ) return 1;;
        esac
    fi
}

# 检查 Spec Kit 是否已初始化
check_speckit() {
    if [ -d ".specify" ]; then
        print_success "发现 .specify/ 目录"
        return 0
    else
        print_error "未发现 .specify/ 目录"
        print_info "请先运行: specify init . --ai cursor --force"
        print_info "或: specify init . --ai claude --force"
        return 1
    fi
}

# 创建 .sdd-version 文件
create_version_file() {
    local version=$1
    local services=$2
    local project_name=$3
    local go_module=$4
    local db_host=$5
    local db_port=$6
    local db_name=$7
    
    cat > .sdd-version <<EOF
{
  "version": "${version}",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "services": [${services}],
  "project_name": "${project_name}",
  "go_module": "${go_module}",
  "db_config": {
    "host": "${db_host}",
    "port": ${db_port},
    "database": "${db_name}"
  }
}
EOF
    print_success "创建 .sdd-version"
}

# ============================================================================
# 全局变量
# ============================================================================

# 模板目录
TEMPLATE_DIR=""
MEMORY_DIR=""
GO_ZERO_DIR=""
SPECIFY_DIR=""

# 服务类型选择
SELECTED_SERVICES=()

# 项目配置
PROJECT_NAME=""
GO_MODULE=""
DOCKER_REGISTRY="docker.io"
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASSWORD=""
DB_NAME="idrm"

# 是否为非交互模式
NON_INTERACTIVE=false

# 检测到的 AI 工具 (cursor/claude/both)
DETECTED_AI_TOOL=""

# ============================================================================
# 主要函数
# ============================================================================

# 下载模板仓库
download_templates() {
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    print_info "正在下载 IDRM SDD Templates..."
    
    if ! git clone --depth 1 https://github.com/jinguoxing/idrm-sdd-templates.git "$TEMP_DIR" 2>/dev/null; then
        print_error "无法下载模板仓库"
        print_info "请检查网络连接或手动克隆: git clone https://github.com/jinguoxing/idrm-sdd-templates.git"
        exit 1
    fi
    
    TEMPLATE_DIR="${TEMP_DIR}/templates"
    MEMORY_DIR="${TEMP_DIR}/memory"
    GO_ZERO_DIR="${TEMP_DIR}/go-zero"
    SPECIFY_DIR="${TEMP_DIR}/.specify"
    
    print_success "下载完成"
}

# 检测执行模式并设置路径
setup_paths() {
    # 获取脚本所在目录
    if [ -n "$BASH_SOURCE" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        
        # 检查是否为本地执行
        if [ -d "${script_dir}/../templates" ]; then
            TEMPLATE_DIR="${script_dir}/../templates"
            MEMORY_DIR="${script_dir}/../memory"
            GO_ZERO_DIR="${script_dir}/../go-zero"
            SPECIFY_DIR="${script_dir}/../.specify"
            print_info "检测到本地模式"
            return 0
        fi
    fi
    
    # 远程执行模式，需要下载
    download_templates
}

# 选择服务类型
select_services() {
    echo ""
    print_step "2/5" "选择 Go-Zero 服务类型 (可多选，用逗号分隔):"
    echo ""
    echo "  [1] API      - HTTP API 服务 (go-zero api)"
    echo "  [2] RPC      - gRPC 微服务 (go-zero zrpc)"
    echo "  [3] Job      - 定时任务服务"
    echo "  [4] Consumer - 消息队列消费者 (Kafka/Redis)"
    echo "  [0] 跳过     - 仅安装模板，不初始化服务"
    echo ""
    
    local input=""
    if [ -t 0 ]; then
        read -p "请输入选项 [1,2,3,4/0]: " input </dev/tty
    else
        # 非交互模式，默认跳过服务初始化
        input="0"
        print_info "非交互模式: 跳过服务初始化"
    fi
    
    if [ "$input" = "0" ] || [ -z "$input" ]; then
        SELECTED_SERVICES=()
        return
    fi
    
    IFS=',' read -ra choices <<< "$input"
    for choice in "${choices[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        case $choice in
            1) SELECTED_SERVICES+=("api");;
            2) SELECTED_SERVICES+=("rpc");;
            3) SELECTED_SERVICES+=("job");;
            4) SELECTED_SERVICES+=("consumer");;
        esac
    done
}

# 收集项目信息
collect_project_info() {
    echo ""
    print_step "3/5" "配置项目信息:"
    echo ""
    
    # 项目名称
    local default_name=$(basename "$(pwd)")
    read_input "  项目名称" "$default_name" PROJECT_NAME
    
    # Go Module
    local default_module="github.com/company/${PROJECT_NAME}"
    read_input "  Go Module" "$default_module" GO_MODULE
    
    # 如果选择了服务，需要配置数据库
    if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
        echo ""
        echo "  数据库配置:"
        read_input "  - MySQL 主机" "$DB_HOST" DB_HOST
        read_input "  - MySQL 端口" "$DB_PORT" DB_PORT
        read_input "  - MySQL 用户名" "$DB_USER" DB_USER
        read_password "  - MySQL 密码" DB_PASSWORD
        read_input "  - MySQL 数据库" "$DB_NAME" DB_NAME
    fi
}

# 确认配置
confirm_config() {
    echo ""
    print_step "4/5" "确认安装配置:"
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │ 项目名称:    ${PROJECT_NAME}"
    echo "  │ Go Module:   ${GO_MODULE}"
    
    if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
        local services_str=$(IFS=', '; echo "${SELECTED_SERVICES[*]}" | tr '[:lower:]' '[:upper:]')
        echo "  │ 服务类型:    ${services_str}"
        echo "  │ 数据库:      ${DB_HOST}:${DB_PORT}/${DB_NAME}"
    else
        echo "  │ 服务类型:    无 (仅安装模板)"
    fi
    
    echo "  └─────────────────────────────────────────────┘"
    echo ""
    
    if ! confirm "确认安装?"; then
        print_warning "安装已取消"
        exit 0
    fi
}

# 安装模板文件
install_templates() {
    echo ""
    echo "  [模板安装]"
    
    # 确保目录存在
    mkdir -p .specify/templates
    mkdir -p .specify/memory
    mkdir -p .specify/workflows
    
    # 复制模板文件
    for file in spec-template.md plan-template.md tasks-template.md checklist-template.md agent-file-template.md README.md; do
        if [ -f "${TEMPLATE_DIR}/${file}" ]; then
            cp "${TEMPLATE_DIR}/${file}" ".specify/templates/${file}"
            print_success "安装 .specify/templates/${file}"
        fi
    done
    
    # 复制额外模板
    for file in api-template.api schema-template.sql; do
        if [ -f "${TEMPLATE_DIR}/${file}" ]; then
            cp "${TEMPLATE_DIR}/${file}" ".specify/templates/${file}"
            print_success "安装 .specify/templates/${file}"
        fi
    done
    
    # 复制 constitution
    if [ -f "${MEMORY_DIR}/constitution.md" ]; then
        cp "${MEMORY_DIR}/constitution.md" ".specify/memory/constitution.md"
        print_success "安装 .specify/memory/constitution.md"
    fi
    
    # 复制 workflows (场景化工作流)
    if [ -d "${SPECIFY_DIR}/workflows" ]; then
        cp -r "${SPECIFY_DIR}/workflows/"* ".specify/workflows/" 2>/dev/null || true
        print_success "安装 .specify/workflows/ (场景化工作流)"
    fi
}

# 安装 AI 工具命令
install_ai_commands() {
    echo ""
    echo "  [AI 工具命令]"
    
    # 根据检测到的 AI 工具安装对应文件
    case "$DETECTED_AI_TOOL" in
        cursor)
            # 仅安装 Cursor 相关文件
            if [ -d "${GO_ZERO_DIR}/.cursor/commands" ]; then
                cp -r "${GO_ZERO_DIR}/.cursor/commands/"* ".cursor/commands/" 2>/dev/null || true
                print_success "安装 .cursor/commands/ (智能场景命令)"
            fi
            
            if [ -f "${GO_ZERO_DIR}/.cursorrules.tpl" ]; then
                cp "${GO_ZERO_DIR}/.cursorrules.tpl" ".cursorrules"
                replace_template_vars ".cursorrules" \
                    "PROJECT_NAME" "$PROJECT_NAME" \
                    "GO_MODULE" "$GO_MODULE"
                print_success "安装 .cursorrules"
            fi
            ;;
        claude)
            # 仅安装 Claude 相关文件
            if [ -d "${GO_ZERO_DIR}/.claude/commands" ]; then
                cp -r "${GO_ZERO_DIR}/.claude/commands/"* ".claude/commands/" 2>/dev/null || true
                print_success "安装 .claude/commands/ (智能场景命令)"
            fi
            
            if [ -f "${GO_ZERO_DIR}/CLAUDE.md.tpl" ]; then
                cp "${GO_ZERO_DIR}/CLAUDE.md.tpl" "CLAUDE.md"
                replace_template_vars "CLAUDE.md" \
                    "PROJECT_NAME" "$PROJECT_NAME" \
                    "GO_MODULE" "$GO_MODULE"
                print_success "安装 CLAUDE.md"
            fi
            ;;
        both)
            # 安装两种 AI 工具文件
            if [ -d "${GO_ZERO_DIR}/.cursor/commands" ]; then
                mkdir -p ".cursor/commands"
                cp -r "${GO_ZERO_DIR}/.cursor/commands/"* ".cursor/commands/" 2>/dev/null || true
                print_success "安装 .cursor/commands/ (智能场景命令)"
            fi
            
            if [ -d "${GO_ZERO_DIR}/.claude/commands" ]; then
                cp -r "${GO_ZERO_DIR}/.claude/commands/"* ".claude/commands/" 2>/dev/null || true
                print_success "安装 .claude/commands/ (智能场景命令)"
            fi
            
            if [ -f "${GO_ZERO_DIR}/CLAUDE.md.tpl" ]; then
                cp "${GO_ZERO_DIR}/CLAUDE.md.tpl" "CLAUDE.md"
                replace_template_vars "CLAUDE.md" \
                    "PROJECT_NAME" "$PROJECT_NAME" \
                    "GO_MODULE" "$GO_MODULE"
                print_success "安装 CLAUDE.md"
            fi
            
            if [ -f "${GO_ZERO_DIR}/.cursorrules.tpl" ]; then
                cp "${GO_ZERO_DIR}/.cursorrules.tpl" ".cursorrules"
                replace_template_vars ".cursorrules" \
                    "PROJECT_NAME" "$PROJECT_NAME" \
                    "GO_MODULE" "$GO_MODULE"
                print_success "安装 .cursorrules"
            fi
            ;;
        *)
            print_warning "未检测到 AI 工具，跳过 AI 命令安装"
            ;;
    esac
}

# 初始化部署文件
init_deploy_files() {
    local access_secret=$1
    
    echo ""
    echo "  [部署文件]"
    
    # 创建部署目录
    mkdir -p deploy/docker deploy/k8s/base deploy/k8s/overlays/dev deploy/k8s/overlays/prod
    
    # 根据选择的服务类型复制对应的 Dockerfile
    for service in "${SELECTED_SERVICES[@]}"; do
        if [ -f "${GO_ZERO_DIR}/deploy/docker/Dockerfile.${service}.tpl" ]; then
            cp "${GO_ZERO_DIR}/deploy/docker/Dockerfile.${service}.tpl" "deploy/docker/Dockerfile.${service}"
            print_success "安装 deploy/docker/Dockerfile.${service}"
        fi
    done
    
    # 复制构建脚本
    if [ -f "${GO_ZERO_DIR}/deploy/docker/build.sh.tpl" ]; then
        cp "${GO_ZERO_DIR}/deploy/docker/build.sh.tpl" "deploy/docker/build.sh"
        replace_template_vars "deploy/docker/build.sh" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DOCKER_REGISTRY" "$DOCKER_REGISTRY"
        chmod +x "deploy/docker/build.sh"
        print_success "安装 deploy/docker/build.sh"
    fi
    
    # 复制 docker-compose.yaml
    if [ -f "${GO_ZERO_DIR}/deploy/docker/docker-compose.yaml.tpl" ]; then
        cp "${GO_ZERO_DIR}/deploy/docker/docker-compose.yaml.tpl" "deploy/docker/docker-compose.yaml"
        replace_template_vars "deploy/docker/docker-compose.yaml" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DB_NAME" "$DB_NAME" \
            "DB_PASSWORD" "$DB_PASSWORD"
        print_success "安装 deploy/docker/docker-compose.yaml"
    fi
    
    # 复制 K8s base 文件
    for k8s_file in deployment.yaml service.yaml configmap.yaml secret.yaml ingress.yaml hpa.yaml pdb.yaml kustomization.yaml; do
        if [ -f "${GO_ZERO_DIR}/deploy/k8s/base/${k8s_file}.tpl" ]; then
            cp "${GO_ZERO_DIR}/deploy/k8s/base/${k8s_file}.tpl" "deploy/k8s/base/${k8s_file}"
            replace_template_vars "deploy/k8s/base/${k8s_file}" \
                "PROJECT_NAME" "$PROJECT_NAME" \
                "DOCKER_REGISTRY" "$DOCKER_REGISTRY" \
                "DB_HOST" "$DB_HOST" \
                "DB_PORT" "$DB_PORT" \
                "DB_NAME" "$DB_NAME" \
                "DB_USER" "$DB_USER" \
                "DB_PASSWORD" "$DB_PASSWORD" \
                "ACCESS_SECRET" "$access_secret"
            print_success "安装 deploy/k8s/base/${k8s_file}"
        fi
    done
    
    # 复制 K8s overlays
    for env in dev prod; do
        if [ -f "${GO_ZERO_DIR}/deploy/k8s/overlays/${env}/kustomization.yaml.tpl" ]; then
            cp "${GO_ZERO_DIR}/deploy/k8s/overlays/${env}/kustomization.yaml.tpl" "deploy/k8s/overlays/${env}/kustomization.yaml"
            replace_template_vars "deploy/k8s/overlays/${env}/kustomization.yaml" \
                "PROJECT_NAME" "$PROJECT_NAME"
            print_success "安装 deploy/k8s/overlays/${env}/kustomization.yaml"
        fi
    done
}

# 初始化 Go-Zero 服务
init_go_zero_services() {
    if [ ${#SELECTED_SERVICES[@]} -eq 0 ]; then
        return
    fi
    
    echo ""
    echo "  [Go-Zero 初始化]"
    
    # 创建公共目录
    mkdir -p model migrations
    
    # 生成 ACCESS_SECRET
    local access_secret=$(generate_secret)
    
    # 复制并处理 Makefile
    if [ -f "${GO_ZERO_DIR}/Makefile.tpl" ]; then
        cp "${GO_ZERO_DIR}/Makefile.tpl" "Makefile"
        replace_template_vars "Makefile" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DOCKER_REGISTRY" "$DOCKER_REGISTRY"
        print_success "安装 Makefile"
    fi
    
    # 复制部署文件
    init_deploy_files "$access_secret"
    
    # 复制并处理 go.mod
    if [ -f "${GO_ZERO_DIR}/go.mod.tpl" ]; then
        cp "${GO_ZERO_DIR}/go.mod.tpl" "go.mod"
        replace_template_vars "go.mod" \
            "GO_MODULE" "$GO_MODULE"
        print_success "安装 go.mod"
    fi
    
    # 初始化各服务
    for service in "${SELECTED_SERVICES[@]}"; do
        case $service in
            api)
                init_api_service "$access_secret"
                ;;
            rpc)
                init_rpc_service
                ;;
            job)
                init_job_service
                ;;
            consumer)
                init_consumer_service
                ;;
        esac
    done
}

# 初始化 API 服务
init_api_service() {
    local access_secret=$1
    
    mkdir -p api/doc/swagger api/etc api/internal/svc
    
    # 复制 api.api
    if [ -f "${GO_ZERO_DIR}/api/doc/api.api.tpl" ]; then
        cp "${GO_ZERO_DIR}/api/doc/api.api.tpl" "api/doc/api.api"
        replace_template_vars "api/doc/api.api" \
            "PROJECT_NAME" "$PROJECT_NAME"
        print_success "安装 api/doc/api.api"
    fi
    
    # 复制 base.api
    if [ -f "${GO_ZERO_DIR}/api/doc/base.api" ]; then
        cp "${GO_ZERO_DIR}/api/doc/base.api" "api/doc/base.api"
        print_success "安装 api/doc/base.api"
    fi
    
    # 复制并处理 api.yaml
    if [ -f "${GO_ZERO_DIR}/api/etc/api.yaml.tpl" ]; then
        cp "${GO_ZERO_DIR}/api/etc/api.yaml.tpl" "api/etc/api.yaml"
        replace_template_vars "api/etc/api.yaml" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DB_HOST" "$DB_HOST" \
            "DB_PORT" "$DB_PORT" \
            "DB_NAME" "$DB_NAME" \
            "DB_USER" "$DB_USER" \
            "DB_PASSWORD" "$DB_PASSWORD" \
            "ACCESS_SECRET" "$access_secret"
        print_success "安装 api/etc/api.yaml"
    fi
    
    # 生成 Swagger 文档
    if command -v goctl &> /dev/null && [ -f "api/doc/api.api" ]; then
        print_info "生成 Swagger 文档..."
        if goctl api swagger --api api/doc/api.api --dir api/doc/swagger --filename swagger 2>/dev/null; then
            print_success "生成 api/doc/swagger/swagger.json"
        else
            print_warning "Swagger 生成失败，请稍后运行: make swagger"
        fi
    else
        print_info "goctl 未安装，跳过 Swagger 生成。请稍后运行: make swagger"
    fi
}

# 初始化 RPC 服务
init_rpc_service() {
    mkdir -p rpc/proto rpc/etc rpc/internal/svc rpc/internal/logic rpc/internal/server
    
    # 复制并处理 rpc.yaml
    if [ -f "${GO_ZERO_DIR}/rpc/etc/rpc.yaml.tpl" ]; then
        cp "${GO_ZERO_DIR}/rpc/etc/rpc.yaml.tpl" "rpc/etc/rpc.yaml"
        replace_template_vars "rpc/etc/rpc.yaml" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DB_HOST" "$DB_HOST" \
            "DB_PORT" "$DB_PORT" \
            "DB_NAME" "$DB_NAME" \
            "DB_USER" "$DB_USER" \
            "DB_PASSWORD" "$DB_PASSWORD"
        print_success "安装 rpc/etc/rpc.yaml"
    fi
}

# 初始化 Job 服务
init_job_service() {
    mkdir -p job/etc job/internal/svc job/internal/logic
    
    # 复制并处理 job.yaml
    if [ -f "${GO_ZERO_DIR}/job/etc/job.yaml.tpl" ]; then
        cp "${GO_ZERO_DIR}/job/etc/job.yaml.tpl" "job/etc/job.yaml"
        replace_template_vars "job/etc/job.yaml" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DB_HOST" "$DB_HOST" \
            "DB_PORT" "$DB_PORT" \
            "DB_NAME" "$DB_NAME" \
            "DB_USER" "$DB_USER" \
            "DB_PASSWORD" "$DB_PASSWORD"
        print_success "安装 job/etc/job.yaml"
    fi
}

# 初始化 Consumer 服务
init_consumer_service() {
    mkdir -p consumer/etc consumer/internal/svc consumer/internal/handler consumer/internal/logic
    
    # 复制并处理 consumer.yaml
    if [ -f "${GO_ZERO_DIR}/consumer/etc/consumer.yaml.tpl" ]; then
        cp "${GO_ZERO_DIR}/consumer/etc/consumer.yaml.tpl" "consumer/etc/consumer.yaml"
        replace_template_vars "consumer/etc/consumer.yaml" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DB_HOST" "$DB_HOST" \
            "DB_PORT" "$DB_PORT" \
            "DB_NAME" "$DB_NAME" \
            "DB_USER" "$DB_USER" \
            "DB_PASSWORD" "$DB_PASSWORD"
        print_success "安装 consumer/etc/consumer.yaml"
    fi
}

# 打印完成信息
print_finish() {
    print_complete
    
    echo "已安装:"
    echo "  • IDRM SDD Template v${VERSION}"
    
    if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
        for service in "${SELECTED_SERVICES[@]}"; do
            echo "  • Go-Zero $(echo $service | tr '[:lower:]' '[:upper:]') 服务结构"
        done
    fi
    
    echo ""
    echo "项目结构:"
    echo "  ${PROJECT_NAME}/"
    echo "  ├── .specify/           # SDD 模板和配置"
    
    if [ -d ".cursor" ]; then
        echo "  ├── .cursor/            # Cursor 命令"
    fi
    if [ -d ".claude" ]; then
        echo "  ├── .claude/            # Claude 命令"
    fi
    
    for service in "${SELECTED_SERVICES[@]}"; do
        echo "  ├── ${service}/                # $(echo $service | tr '[:lower:]' '[:upper:]') 服务"
    done
    
    if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
        echo "  ├── model/              # Model 层"
        echo "  ├── migrations/         # DDL 迁移"
        echo "  ├── deploy/             # 部署配置"
        echo "  ├── Makefile            # 常用命令"
        echo "  └── go.mod"
    fi
    
    echo ""
    echo "下一步:"
    if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
        echo "  1. 运行 'go mod tidy' 安装依赖"
        echo "  2. 使用 '/speckit.start \"功能描述\"' 开始开发"
    else
        echo "  1. 使用 '/speckit.start \"功能描述\"' 开始开发"
    fi
    echo ""
    
    if [ ${#SELECTED_SERVICES[@]} -gt 0 ]; then
        echo "常用命令:"
        echo "  make api         # 生成 API 代码"
        echo "  make swagger     # 生成 Swagger 文档"
        echo "  make gen         # 一键生成 API + Swagger"
        echo "  make run         # 运行服务"
        echo ""
    fi
}

# ============================================================================
# 主函数
# ============================================================================

main() {
    print_banner "$VERSION"
    
    # 设置路径 (自动检测本地/远程模式)
    setup_paths
    
    # Step 1: 检测 Spec Kit
    print_step "1/5" "检测 Spec Kit 环境..."
    if ! check_speckit; then
        exit 1
    fi
    
    # 检测并设置 AI 工具类型
    local has_cursor=false
    local has_claude=false
    
    if [ -d ".cursor/commands" ] || [ -d ".cursor" ]; then
        has_cursor=true
        print_success "发现 Cursor 环境 (.cursor/)"
    fi
    if [ -d ".claude/commands" ] || [ -d ".claude" ]; then
        has_claude=true
        print_success "发现 Claude 环境 (.claude/)"
    fi
    
    # 设置 DETECTED_AI_TOOL
    if [ "$has_cursor" = true ] && [ "$has_claude" = true ]; then
        DETECTED_AI_TOOL="both"
        print_info "将安装 Cursor + Claude 工具文件"
    elif [ "$has_cursor" = true ]; then
        DETECTED_AI_TOOL="cursor"
        print_info "将仅安装 Cursor 工具文件"
    elif [ "$has_claude" = true ]; then
        DETECTED_AI_TOOL="claude"
        print_info "将仅安装 Claude 工具文件"
    else
        print_warning "未检测到 AI 工具环境"
    fi
    
    # Step 2: 选择服务类型
    select_services
    
    # Step 3: 收集项目信息
    collect_project_info
    
    # Step 4: 确认配置
    confirm_config
    
    # Step 5: 执行安装
    print_step "5/5" "开始安装..."
    
    install_templates
    install_ai_commands
    init_go_zero_services
    
    # 创建版本文件
    local services_json=""
    for i in "${!SELECTED_SERVICES[@]}"; do
        if [ $i -gt 0 ]; then services_json+=","; fi
        services_json+="\"${SELECTED_SERVICES[$i]}\""
    done
    
    create_version_file "$VERSION" "$services_json" "$PROJECT_NAME" "$GO_MODULE" "$DB_HOST" "$DB_PORT" "$DB_NAME"
    
    # 打印完成信息
    print_finish
}

# 执行主函数
main "$@"

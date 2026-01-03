#!/bin/bash
# IDRM SDD Templates - Main Install Script
# Version: 0.1.0
# Repository: github.com/jinguoxing/idrm-sdd-templates

set -e

VERSION="0.3.0"

# 获取脚本所在目录
if [ -n "$BASH_SOURCE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # 远程执行时，下载到临时目录
    SCRIPT_DIR=""
fi

# 检测是否为远程执行
IS_REMOTE=false
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    IS_REMOTE=true
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    echo "正在下载 IDRM SDD Templates..."
    git clone --depth 1 https://github.com/jinguoxing/idrm-sdd-templates.git "$TEMP_DIR" 2>/dev/null || {
        echo "错误: 无法下载模板仓库"
        echo "请检查网络连接或手动克隆: git clone https://github.com/jinguoxing/idrm-sdd-templates.git"
        exit 1
    }
    SCRIPT_DIR="$TEMP_DIR/scripts"
fi

# 加载公共函数
source "${SCRIPT_DIR}/lib/common.sh"

# 模板目录
if [ "$IS_REMOTE" = true ]; then
    TEMPLATE_DIR="${TEMP_DIR}/templates"
    MEMORY_DIR="${TEMP_DIR}/memory"
    GO_ZERO_DIR="${TEMP_DIR}/go-zero"
else
    TEMPLATE_DIR="${SCRIPT_DIR}/../templates"
    MEMORY_DIR="${SCRIPT_DIR}/../memory"
    GO_ZERO_DIR="${SCRIPT_DIR}/../go-zero"
fi

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
    
    read -p "请输入选项 [1,2,3,4/0]: " input
    
    if [ "$input" = "0" ]; then
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
    
    # 复制模板文件
    for file in spec-template.md plan-template.md tasks-template.md checklist-template.md agent-file-template.md; do
        if [ -f "${TEMPLATE_DIR}/${file}" ]; then
            cp "${TEMPLATE_DIR}/${file}" ".specify/templates/${file}"
            print_success "替换 .specify/templates/${file}"
        fi
    done
    
    # 复制额外模板
    for file in api-template.api schema-template.sql; do
        if [ -f "${TEMPLATE_DIR}/${file}" ]; then
            cp "${TEMPLATE_DIR}/${file}" ".specify/templates/${file}"
            print_success "新增 .specify/templates/${file}"
        fi
    done
    
    # 复制 constitution
    if [ -f "${MEMORY_DIR}/constitution.md" ]; then
        cp "${MEMORY_DIR}/constitution.md" ".specify/memory/constitution.md"
        print_success "替换 .specify/memory/constitution.md"
    fi
    
    # 复制 workflows (场景化工作流)
    if [ -d "${SCRIPT_DIR}/../.specify/workflows" ]; then
        mkdir -p ".specify/workflows"
        cp -r "${SCRIPT_DIR}/../.specify/workflows/"* ".specify/workflows/"
        print_success "创建 .specify/workflows/ (场景化工作流)"
    fi
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
        print_success "创建 Makefile"
    fi
    
    # 复制部署文件
    init_deploy_files "$access_secret"
    
    # 复制并处理 go.mod
    if [ -f "${GO_ZERO_DIR}/go.mod.tpl" ]; then
        cp "${GO_ZERO_DIR}/go.mod.tpl" "go.mod"
        replace_template_vars "go.mod" \
            "GO_MODULE" "$GO_MODULE"
        print_success "创建 go.mod"
    fi
    
    # 复制并处理 .cursorrules (Cursor AI 规则)
    if [ -f "${GO_ZERO_DIR}/.cursorrules.tpl" ]; then
        cp "${GO_ZERO_DIR}/.cursorrules.tpl" ".cursorrules"
        replace_template_vars ".cursorrules" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "GO_MODULE" "$GO_MODULE"
        print_success "创建 .cursorrules"
    fi
    
    # 复制并处理 CLAUDE.md (Claude Code 配置)
    if [ -f "${GO_ZERO_DIR}/CLAUDE.md.tpl" ]; then
        cp "${GO_ZERO_DIR}/CLAUDE.md.tpl" "CLAUDE.md"
        replace_template_vars "CLAUDE.md" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "GO_MODULE" "$GO_MODULE"
        print_success "创建 CLAUDE.md"
    fi
    
    # 复制 Cursor 命令
    if [ -d "${GO_ZERO_DIR}/.cursor/commands" ]; then
        mkdir -p ".cursor/commands"
        cp -r "${GO_ZERO_DIR}/.cursor/commands/"* ".cursor/commands/"
        print_success "创建 .cursor/commands/ (智能场景命令)"
    fi
    
    # 复制 Claude 命令
    if [ -d "${GO_ZERO_DIR}/.claude/commands" ]; then
        mkdir -p ".claude/commands"
        cp -r "${GO_ZERO_DIR}/.claude/commands/"* ".claude/commands/"
        print_success "创建 .claude/commands/ (智能场景命令)"
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

# 初始化部署文件
init_deploy_files() {
    local access_secret=$1
    
    echo ""
    echo "  [部署文件]"
    
    # 创建部署目录
    mkdir -p deploy/docker deploy/k8s
    
    # 复制 Dockerfile
    if [ -f "${GO_ZERO_DIR}/deploy/docker/Dockerfile.tpl" ]; then
        cp "${GO_ZERO_DIR}/deploy/docker/Dockerfile.tpl" "deploy/docker/Dockerfile"
        print_success "创建 deploy/docker/Dockerfile"
    fi
    
    # 复制 docker-compose.yaml
    if [ -f "${GO_ZERO_DIR}/deploy/docker/docker-compose.yaml.tpl" ]; then
        cp "${GO_ZERO_DIR}/deploy/docker/docker-compose.yaml.tpl" "deploy/docker/docker-compose.yaml"
        replace_template_vars "deploy/docker/docker-compose.yaml" \
            "PROJECT_NAME" "$PROJECT_NAME" \
            "DB_NAME" "$DB_NAME" \
            "DB_PASSWORD" "$DB_PASSWORD"
        print_success "创建 deploy/docker/docker-compose.yaml"
    fi
    
    # 复制 K8s 文件
    for k8s_file in deployment.yaml service.yaml configmap.yaml; do
        if [ -f "${GO_ZERO_DIR}/deploy/k8s/${k8s_file}.tpl" ]; then
            cp "${GO_ZERO_DIR}/deploy/k8s/${k8s_file}.tpl" "deploy/k8s/${k8s_file}"
            replace_template_vars "deploy/k8s/${k8s_file}" \
                "PROJECT_NAME" "$PROJECT_NAME" \
                "DOCKER_REGISTRY" "$DOCKER_REGISTRY" \
                "DB_HOST" "$DB_HOST" \
                "DB_PORT" "$DB_PORT" \
                "DB_NAME" "$DB_NAME" \
                "DB_USER" "$DB_USER" \
                "DB_PASSWORD" "$DB_PASSWORD" \
                "ACCESS_SECRET" "$access_secret"
            print_success "创建 deploy/k8s/${k8s_file}"
        fi
    done
}

# 初始化 API 服务
init_api_service() {
    local access_secret=$1
    
    mkdir -p api/doc api/etc api/internal/svc
    
    # 复制 api.api
    if [ -f "${GO_ZERO_DIR}/api/doc/api.api.tpl" ]; then
        cp "${GO_ZERO_DIR}/api/doc/api.api.tpl" "api/doc/api.api"
        replace_template_vars "api/doc/api.api" \
            "PROJECT_NAME" "$PROJECT_NAME"
        print_success "创建 api/doc/api.api"
    fi
    
    # 复制 base.api
    if [ -f "${GO_ZERO_DIR}/api/doc/base.api" ]; then
        cp "${GO_ZERO_DIR}/api/doc/base.api" "api/doc/base.api"
        print_success "创建 api/doc/base.api"
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
        print_success "创建 api/etc/api.yaml"
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
        print_success "创建 rpc/etc/rpc.yaml"
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
        print_success "创建 job/etc/job.yaml"
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
        print_success "创建 consumer/etc/consumer.yaml"
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
        echo "  ├── .cursor/            # Cursor 命令 (官方)"
    fi
    if [ -d ".claude" ]; then
        echo "  ├── .claude/            # Claude 命令 (官方)"
    fi
    
    for service in "${SELECTED_SERVICES[@]}"; do
        echo "  ├── ${service}/                # $(echo $service | tr '[:lower:]' '[:upper:]') 服务"
    done
    
    echo "  ├── model/              # Model 层"
    echo "  ├── migrations/         # DDL 迁移"
    echo "  ├── Makefile            # 常用命令"
    echo "  └── go.mod"
    
    echo ""
    echo "下一步:"
    echo "  1. 运行 'go mod tidy' 安装依赖"
    echo "  2. 使用 '/speckit.specify \"功能描述\"' 开始开发"
    echo ""
    echo "常用命令:"
    echo "  make api         # 生成 API 代码"
    echo "  make swagger     # 生成 Swagger 文档"
    echo "  make gen         # 一键生成 API + Swagger"
    echo "  make run         # 运行服务"
    echo ""
}

# 主函数
main() {
    print_banner "$VERSION"
    
    # Step 1: 检测 Spec Kit
    print_step "1/5" "检测 Spec Kit 环境..."
    if ! check_speckit; then
        exit 1
    fi
    
    if [ -d ".cursor/commands" ]; then
        print_success "发现 .cursor/commands/ 目录"
    fi
    if [ -d ".claude/commands" ]; then
        print_success "发现 .claude/commands/ 目录"
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

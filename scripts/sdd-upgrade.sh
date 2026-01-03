#!/bin/bash
# IDRM SDD Templates - Upgrade Script
# Version: 0.1.0
# Repository: github.com/jinguoxing/idrm-sdd-templates

set -e

VERSION="0.1.0"

# 获取脚本所在目录
if [ -n "$BASH_SOURCE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""
fi

# 检测是否为远程执行
IS_REMOTE=false
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    IS_REMOTE=true
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    echo "正在检查更新..."
    git clone --depth 1 https://github.com/jinguoxing/idrm-sdd-templates.git "$TEMP_DIR" 2>/dev/null || {
        echo "错误: 无法连接到更新服务器"
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
    REMOTE_VERSION=$(cat "${TEMP_DIR}/VERSION" 2>/dev/null || echo "unknown")
else
    TEMPLATE_DIR="${SCRIPT_DIR}/../templates"
    MEMORY_DIR="${SCRIPT_DIR}/../memory"
    GO_ZERO_DIR="${SCRIPT_DIR}/../go-zero"
    REMOTE_VERSION=$(cat "${SCRIPT_DIR}/../VERSION" 2>/dev/null || echo "unknown")
fi

# 解析参数
CHECK_ONLY=false
for arg in "$@"; do
    case $arg in
        --check)
            CHECK_ONLY=true
            ;;
    esac
done

# 获取本地版本
get_local_version() {
    if [ -f ".sdd-version" ]; then
        # 使用 grep 和 sed 解析 JSON (避免依赖 jq)
        grep '"version"' .sdd-version | sed 's/.*: *"\([^"]*\)".*/\1/'
    else
        echo "unknown"
    fi
}

# 显示变更日志
show_changelog() {
    local from_version=$1
    local to_version=$2
    
    if [ -f "${TEMP_DIR}/CHANGELOG.md" ] || [ -f "${SCRIPT_DIR}/../CHANGELOG.md" ]; then
        echo ""
        print_info "变更日志 (v${from_version} → v${to_version}):"
        echo "-------------------------------------------"
        
        local changelog_file
        if [ "$IS_REMOTE" = true ]; then
            changelog_file="${TEMP_DIR}/CHANGELOG.md"
        else
            changelog_file="${SCRIPT_DIR}/../CHANGELOG.md"
        fi
        
        # 只显示最新版本的变更 (使用 sed 删除最后一行，兼容 macOS)
        sed -n "/## \[${to_version}\]/,/## \[/p" "$changelog_file" | sed '$d'
        echo "-------------------------------------------"
    fi
}

# 备份当前模板
backup_templates() {
    local backup_dir=".specify/templates.backup.$(date +%Y%m%d%H%M%S)"
    
    if [ -d ".specify/templates" ]; then
        cp -r ".specify/templates" "$backup_dir"
        print_success "已备份模板到 $backup_dir"
    fi
}

# 升级模板
upgrade_templates() {
    print_info "正在升级模板..."
    
    # 确保目录存在
    mkdir -p .specify/templates
    mkdir -p .specify/memory
    
    # 复制模板文件
    for file in spec-template.md plan-template.md tasks-template.md checklist-template.md agent-file-template.md api-template.api schema-template.sql; do
        if [ -f "${TEMPLATE_DIR}/${file}" ]; then
            cp "${TEMPLATE_DIR}/${file}" ".specify/templates/${file}"
            print_success "更新 .specify/templates/${file}"
        fi
    done
    
    # 复制 constitution
    if [ -f "${MEMORY_DIR}/constitution.md" ]; then
        cp "${MEMORY_DIR}/constitution.md" ".specify/memory/constitution.md"
        print_success "更新 .specify/memory/constitution.md"
    fi
    
    # 从 .sdd-version 读取项目配置
    local project_name=""
    local go_module=""
    if [ -f ".sdd-version" ]; then
        project_name=$(grep '"project_name"' .sdd-version | sed 's/.*: *"\([^"]*\)".*/\1/')
        go_module=$(grep '"go_module"' .sdd-version | sed 's/.*: *"\([^"]*\)".*/\1/')
    fi
    
    # 更新 .cursorrules (Cursor AI 规则)
    if [ -f "${GO_ZERO_DIR}/.cursorrules.tpl" ] && [ -n "$project_name" ]; then
        cp "${GO_ZERO_DIR}/.cursorrules.tpl" ".cursorrules"
        sed -i.bak "s/{{PROJECT_NAME}}/${project_name}/g" ".cursorrules"
        sed -i.bak "s|{{GO_MODULE}}|${go_module}|g" ".cursorrules"
        rm -f ".cursorrules.bak"
        print_success "更新 .cursorrules"
    fi
    
    # 更新 CLAUDE.md (Claude Code 配置)
    if [ -f "${GO_ZERO_DIR}/CLAUDE.md.tpl" ] && [ -n "$project_name" ]; then
        cp "${GO_ZERO_DIR}/CLAUDE.md.tpl" "CLAUDE.md"
        sed -i.bak "s/{{PROJECT_NAME}}/${project_name}/g" "CLAUDE.md"
        sed -i.bak "s|{{GO_MODULE}}|${go_module}|g" "CLAUDE.md"
        rm -f "CLAUDE.md.bak"
        print_success "更新 CLAUDE.md"
    fi
}

# 更新版本文件
update_version_file() {
    local new_version=$1
    
    if [ -f ".sdd-version" ]; then
        # 更新版本号和时间
        local temp_file=".sdd-version.tmp"
        sed "s/\"version\": *\"[^\"]*\"/\"version\": \"${new_version}\"/" .sdd-version > "$temp_file"
        sed -i.bak "s/\"installed_at\": *\"[^\"]*\"/\"installed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"/" "$temp_file"
        rm -f "${temp_file}.bak"
        mv "$temp_file" .sdd-version
        print_success "更新 .sdd-version"
    fi
}

# 主函数
main() {
    echo ""
    print_info "IDRM SDD Template 升级检查"
    echo ""
    
    # 获取版本信息
    local local_version=$(get_local_version)
    
    if [ "$local_version" = "unknown" ]; then
        print_error "未发现 .sdd-version 文件"
        print_info "请先运行安装脚本: curl -sSL .../sdd-install.sh | bash"
        exit 1
    fi
    
    print_info "当前版本: v${local_version}"
    print_info "最新版本: v${REMOTE_VERSION}"
    
    # 比较版本 (暂时禁用 set -e 以获取返回值)
    set +e
    compare_versions "$local_version" "$REMOTE_VERSION"
    local result=$?
    set -e
    
    case $result in
        0)
            echo ""
            print_success "已是最新版本，无需升级"
            exit 0
            ;;
        1)
            echo ""
            print_warning "本地版本高于远程版本，可能是开发版本"
            exit 0
            ;;
        2)
            echo ""
            print_info "发现新版本可用!"
            ;;
    esac
    
    # 如果只是检查
    if [ "$CHECK_ONLY" = true ]; then
        show_changelog "$local_version" "$REMOTE_VERSION"
        echo ""
        print_info "运行以下命令进行升级:"
        echo "  curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh | bash"
        exit 0
    fi
    
    # 显示变更日志
    show_changelog "$local_version" "$REMOTE_VERSION"
    
    # 确认升级
    echo ""
    if ! confirm "是否升级到 v${REMOTE_VERSION}?"; then
        print_warning "升级已取消"
        exit 0
    fi
    
    # 执行升级
    echo ""
    backup_templates
    upgrade_templates
    update_version_file "$REMOTE_VERSION"
    
    echo ""
    print_success "升级完成! v${local_version} → v${REMOTE_VERSION}"
    echo ""
}

# 执行主函数
main "$@"

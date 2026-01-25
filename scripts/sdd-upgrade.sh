#!/bin/bash
# IDRM SDD Templates - Upgrade Script (Self-contained)
# Version: 0.2.0
# Repository: github.com/jinguoxing/idrm-sdd-templates

set -e

VERSION="0.8.3"

# ============================================
# 公共函数 (内联)
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# 确认操作
confirm() {
    local prompt=$1
    local default=${2:-Y}
    
    if [ "$default" = "Y" ]; then
        read -p "$prompt [Y/n]: " answer
        case $answer in
            [Nn]* ) return 1;;
            * ) return 0;;
        esac
    else
        read -p "$prompt [y/N]: " answer
        case $answer in
            [Yy]* ) return 0;;
            * ) return 1;;
        esac
    fi
}

# 比较版本号 (返回: 0=相等, 1=大于, 2=小于)
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    if [ "$v1" = "$v2" ]; then
        return 0
    fi
    
    local v1_major=$(echo "$v1" | cut -d. -f1)
    local v1_minor=$(echo "$v1" | cut -d. -f2)
    local v1_patch=$(echo "$v1" | cut -d. -f3)
    
    local v2_major=$(echo "$v2" | cut -d. -f1)
    local v2_minor=$(echo "$v2" | cut -d. -f2)
    local v2_patch=$(echo "$v2" | cut -d. -f3)
    
    v1_major=${v1_major:-0}
    v1_minor=${v1_minor:-0}
    v1_patch=${v1_patch:-0}
    v2_major=${v2_major:-0}
    v2_minor=${v2_minor:-0}
    v2_patch=${v2_patch:-0}
    
    if [ "$v1_major" -gt "$v2_major" ]; then return 1; fi
    if [ "$v1_major" -lt "$v2_major" ]; then return 2; fi
    if [ "$v1_minor" -gt "$v2_minor" ]; then return 1; fi
    if [ "$v1_minor" -lt "$v2_minor" ]; then return 2; fi
    if [ "$v1_patch" -gt "$v2_patch" ]; then return 1; fi
    if [ "$v1_patch" -lt "$v2_patch" ]; then return 2; fi
    
    return 0
}

# ============================================
# 升级脚本逻辑
# ============================================

# 下载模板到临时目录
download_templates() {
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    print_info "正在检查更新..."
    
    if ! git clone --depth 1 https://github.com/jinguoxing/idrm-sdd-templates.git "$TEMP_DIR" 2>/dev/null; then
        print_error "无法连接到更新服务器"
        exit 1
    fi
    
    TEMPLATE_DIR="${TEMP_DIR}/templates"
    MEMORY_DIR="${TEMP_DIR}/memory"
    GO_ZERO_DIR="${TEMP_DIR}/go-zero"
    REMOTE_VERSION=$(cat "${TEMP_DIR}/VERSION" 2>/dev/null || echo "unknown")
}

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
        grep '"version"' .sdd-version | sed 's/.*: *"\([^"]*\)".*/\1/'
    else
        echo "unknown"
    fi
}

# 显示变更日志
show_changelog() {
    local from_version=$1
    local to_version=$2
    
    if [ -f "${TEMP_DIR}/CHANGELOG.md" ]; then
        echo ""
        print_info "变更日志 (v${from_version} → v${to_version}):"
        echo "-------------------------------------------"
        sed -n "/## \[${to_version}\]/,/## \[/p" "${TEMP_DIR}/CHANGELOG.md" | sed '$d'
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
    
    # 更新 .cursorrules
    if [ -f "${GO_ZERO_DIR}/.cursorrules.tpl" ] && [ -n "$project_name" ]; then
        cp "${GO_ZERO_DIR}/.cursorrules.tpl" ".cursorrules"
        sed -i.bak "s/{{PROJECT_NAME}}/${project_name}/g" ".cursorrules"
        sed -i.bak "s|{{GO_MODULE}}|${go_module}|g" ".cursorrules"
        rm -f ".cursorrules.bak"
        print_success "更新 .cursorrules"
    fi
    
    # 更新 CLAUDE.md
    if [ -f "${GO_ZERO_DIR}/CLAUDE.md.tpl" ] && [ -n "$project_name" ]; then
        cp "${GO_ZERO_DIR}/CLAUDE.md.tpl" "CLAUDE.md"
        sed -i.bak "s/{{PROJECT_NAME}}/${project_name}/g" "CLAUDE.md"
        sed -i.bak "s|{{GO_MODULE}}|${go_module}|g" "CLAUDE.md"
        rm -f "CLAUDE.md.bak"
        print_success "更新 CLAUDE.md"
    fi
    
    # 更新 workflows
    local workflows_dir="${TEMP_DIR}/.specify/workflows"
    if [ -d "$workflows_dir" ]; then
        mkdir -p ".specify/workflows"
        cp -r "$workflows_dir/"* ".specify/workflows/"
        print_success "更新 .specify/workflows/ (场景化工作流)"
    fi
    
    # 更新 Cursor 命令
    if [ -d "${GO_ZERO_DIR}/.cursor/commands" ]; then
        mkdir -p ".cursor/commands"
        cp -r "${GO_ZERO_DIR}/.cursor/commands/"* ".cursor/commands/"
        print_success "更新 .cursor/commands/"
    fi
    
    # 更新 Claude 命令
    if [ -d "${GO_ZERO_DIR}/.claude/commands" ]; then
        mkdir -p ".claude/commands"
        cp -r "${GO_ZERO_DIR}/.claude/commands/"* ".claude/commands/"
        print_success "更新 .claude/commands/"
    fi
}

# 更新版本文件
update_version_file() {
    local new_version=$1
    
    if [ -f ".sdd-version" ]; then
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
    
    # 下载模板
    download_templates
    
    # 获取版本信息
    local local_version=$(get_local_version)
    
    if [ "$local_version" = "unknown" ]; then
        print_error "未发现 .sdd-version 文件"
        print_info "请先运行安装脚本: curl -sSL .../sdd-install.sh | bash"
        exit 1
    fi
    
    print_info "当前版本: v${local_version}"
    print_info "最新版本: v${REMOTE_VERSION}"
    
    # 比较版本
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
        echo "  curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh -o /tmp/sdd-upgrade.sh"
        echo "  bash /tmp/sdd-upgrade.sh"
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

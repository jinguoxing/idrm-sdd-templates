#!/bin/bash
# IDRM SDD Templates - Common Functions
# Version: 0.2.0

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

# 读取用户输入（带默认值）
read_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\"${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# 读取密码输入
read_password() {
    local prompt=$1
    local var_name=$2
    
    read -sp "$prompt: " input
    echo ""
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

# 检查 Spec Kit 是否已初始化
check_speckit() {
    if [ -d ".specify" ]; then
        print_success "发现 .specify/ 目录"
        return 0
    else
        print_error "未发现 .specify/ 目录"
        print_info "请先运行: npx @anthropic/speckit init --agent cursor"
        print_info "或: npx @anthropic/speckit init --agent claude"
        return 1
    fi
}

# 获取远程版本
get_remote_version() {
    local version_url="https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/VERSION"
    curl -sSL "$version_url" 2>/dev/null || echo "unknown"
}

# 比较版本号 (返回: 0=相等, 1=大于, 2=小于)
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    if [ "$v1" = "$v2" ]; then
        return 0
    fi
    
    # 使用 cut 分割版本号，兼容 bash 和 zsh
    local v1_major=$(echo "$v1" | cut -d. -f1)
    local v1_minor=$(echo "$v1" | cut -d. -f2)
    local v1_patch=$(echo "$v1" | cut -d. -f3)
    
    local v2_major=$(echo "$v2" | cut -d. -f1)
    local v2_minor=$(echo "$v2" | cut -d. -f2)
    local v2_patch=$(echo "$v2" | cut -d. -f3)
    
    # 设置默认值
    v1_major=${v1_major:-0}
    v1_minor=${v1_minor:-0}
    v1_patch=${v1_patch:-0}
    v2_major=${v2_major:-0}
    v2_minor=${v2_minor:-0}
    v2_patch=${v2_patch:-0}
    
    # 比较主版本
    if [ "$v1_major" -gt "$v2_major" ]; then return 1; fi
    if [ "$v1_major" -lt "$v2_major" ]; then return 2; fi
    
    # 比较次版本
    if [ "$v1_minor" -gt "$v2_minor" ]; then return 1; fi
    if [ "$v1_minor" -lt "$v2_minor" ]; then return 2; fi
    
    # 比较补丁版本
    if [ "$v1_patch" -gt "$v2_patch" ]; then return 1; fi
    if [ "$v1_patch" -lt "$v2_patch" ]; then return 2; fi
    
    return 0
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
    
    cat > .sdd-version << EOF
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

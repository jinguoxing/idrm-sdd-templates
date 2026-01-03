# 快速开始

> **5 分钟上手 IDRM SDD Templates**

---

## 前置条件

确保已安装以下工具：

```bash
# 检查 Go
go version  # >= 1.21

# 检查 goctl
goctl --version  # Go-Zero CLI

# 检查 uv (Python 包管理器)
uv --version
```

---

## 安装步骤

### Step 1: 安装 Spec Kit CLI

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

### Step 2: 创建新项目

```bash
mkdir my-project && cd my-project
git init
```

### Step 3: 初始化 Spec Kit

```bash
# 使用 Cursor
specify init . --ai cursor-agent --force

# 或使用 Claude
specify init . --ai claude --force
```

### Step 4: 安装 IDRM 模板

```bash
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
```

按提示选择：
- 服务类型 (API/RPC/Job/Consumer)
- 项目名称
- Go Module 路径
- 数据库配置

---

## 开始开发

安装完成后，在 AI 工具中使用 Spec Kit 命令：

```bash
# 1. 定义需求
/speckit.specify "实现用户登录功能，支持手机号+密码登录"

# 2. 创建技术计划
/speckit.plan

# 3. 拆分任务
/speckit.tasks

# 4. 开始实现
/speckit.implement
```

---

## 常用命令

```bash
make api         # 生成 API 代码
make swagger     # 生成 Swagger 文档
make run         # 运行服务
make docker-build # 构建 Docker 镜像
```

---

## 下一步

- [完整安装说明](installation.md)
- [SDD 工作流程详解](workflow.md)
- [模板使用指南](templates-guide.md)

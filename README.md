# IDRM SDD Templates

> **Spec-Driven Development Templates for Go-Zero Projects**

[![Version](https://img.shields.io/badge/version-0.7.3-blue.svg)](https://github.com/jinguoxing/idrm-sdd-templates)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 📖 简介

IDRM SDD Templates 是一套基于 [Spec Kit](https://github.com/anthropics/speckit) 的定制化模板，专为 **Go-Zero 微服务项目** 设计。

### 特性

- 🎯 **EARS 格式需求规格** - 清晰、可测试的需求表达
- 🏗️ **Go-Zero 分层架构** - Handler → Logic → Model
- 🔄 **双 ORM 支持** - GORM + SQLx 灵活切换
- 📦 **多服务类型** - API / RPC / Job / Consumer
- 🤖 **AI 工具集成** - 支持 Cursor 和 Claude Code
- 📋 **质量门禁** - 内置检查清单和宪法约束
- 🎭 **场景化工作流** - 4 种场景智能匹配 (新功能/小改动/扩展/重构)
- 📝 **Delta 格式** - 变更追踪 (ADDED/MODIFIED/REMOVED)

---

## 🚀 快速开始

### 前置条件

- [Go](https://golang.org/) >= 1.24
- [goctl](https://go-zero.dev/docs/goctl/goctl) (Go-Zero CLI)
- [uv](https://github.com/astral-sh/uv) (Python 包管理器)

### 安装步骤

```bash
# Step 1: 安装 Spec Kit CLI
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Step 2: 使用 Spec Kit 官方初始化 (选择 Cursor 或 Claude)
specify init . --ai cursor-agent --force
# 或
specify init . --ai claude --force

# Step 3: 安装 IDRM SDD Template
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
```

### 交互式安装

如需选择服务类型和配置数据库，需要**先下载脚本再运行**：

```bash
# 下载脚本后交互运行
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh -o /tmp/sdd-install.sh
bash /tmp/sdd-install.sh
```

安装脚本会引导你完成以下配置：

1. **选择服务类型** - API / RPC / Job / Consumer (可多选)
2. **配置项目信息** - 项目名称、Go Module 路径
3. **配置数据库** - MySQL 连接信息
4. **确认并安装**

### 非交互式安装 (CI/CD)

通过管道执行时自动进入非交互模式：

```bash
# 仅安装模板，使用默认配置
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
```

---

## 📁 安装后目录结构

```
my-project/
├── .specify/                    # SDD 配置
│   ├── templates/               # IDRM 定制模板
│   │   ├── spec-template.md     # 需求规格模板 (EARS)
│   │   ├── plan-template.md     # 技术计划模板
│   │   ├── tasks-template.md    # 任务模板
│   │   ├── api-template.api     # Go-Zero API 模板
│   │   └── schema-template.sql  # DDL 模板
│   ├── workflows/               # 场景化工作流 [NEW]
│   │   ├── README.md            # 场景决策树
│   │   ├── scenario-1-new.md    # 新功能 (5阶段)
│   │   ├── scenario-2-update.md # 小改动 (4步骤)
│   │   ├── scenario-3-extend.md # 扩展 (Delta格式)
│   │   └── scenario-4-refactor.md # 重构
│   └── memory/
│       └── constitution.md      # IDRM 项目宪法
│
├── .cursor/commands/            # Cursor 命令
│   ├── speckit.start.md         # 智能场景启动 [NEW]
│   └── speckit.*.md             # 官方命令
├── .claude/commands/            # Claude 命令
│   ├── speckit.start.md         # 智能场景启动 [NEW]
│   └── speckit.*.md             # 官方命令
├── api/                         # API 服务
│   ├── doc/
│   │   ├── api.api              # API 入口
│   │   └── base.api             # 基础类型
│   └── etc/
│       └── api.yaml             # 配置文件
├── rpc/                         # RPC 服务 (可选)
├── job/                         # Job 服务 (可选)
├── consumer/                    # Consumer 服务 (可选)
├── model/                       # Model 层
├── migrations/                  # DDL 迁移
├── Makefile                     # 常用命令
└── go.mod
```

---

## 🔧 常用命令

```bash
# 生成 API 代码
make api

# 生成 Swagger 文档
make swagger

# 一键生成 API + Swagger
make gen

# 运行服务
make run

# 代码检查
make lint

# 运行测试
make test
```

---

## 📝 开发流程

### 场景化智能命令 (v0.4.0+)

使用 `/speckit.start` 命令，AI 自动判断并匹配合适的开发场景：

```bash
# Cursor 或 Claude Code 中输入:
/speckit.start 实现用户认证功能      # → 场景一: 新功能
/speckit.start 修复登录超时问题      # → 场景二: 小改动
/speckit.start 添加密码重置功能      # → 场景三: 扩展
/speckit.start 将JWT改为OAuth2      # → 场景四: 重构
```

### 4 种开发场景

| 场景 | 适用条件 | 工作流 |
|------|----------|--------|
| 🆕 新功能 | specs/{feature}/ 不存在 | 5阶段完整流程 |
| 🔧 小改动 | 已有spec, <50行 | 4步快速流程 |
| ➕ 扩展 | 添加子功能 | 增量+Delta格式 |
| 🔄 重构 | 破坏性变更 | 6步迁移流程 |

### 传统命令 (仍可用)

```bash
/speckit.specify   # 定义需求
/speckit.plan      # 创建技术计划
/speckit.tasks     # 生成任务列表
/speckit.implement # 开始实现
```

---

## 🔄 升级

```bash
# 检查更新
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh | bash -s -- --check

# 执行升级
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh | bash
```

---

## 📚 文档

- [场景工作流](.specify/workflows/README.md) - 4 种开发场景决策树
- [项目宪法](memory/constitution.md) - IDRM 项目核心约束
- [模板说明](templates/README.md) - 各模板使用指南
- [Go-Zero 指南](go-zero/README.md) - Go-Zero 开发指南

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 📄 License

[MIT License](LICENSE)

---

## 🔗 相关链接

- [GitHub Spec Kit](https://github.com/github/spec-kit) - 官方 Spec Kit
- [Go-Zero](https://go-zero.dev/) - Go-Zero 框架
- [IDRM 项目](https://github.com/jinguoxing) - IDRM 系列项目

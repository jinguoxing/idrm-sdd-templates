# 安装说明

> **IDRM SDD Templates 完整安装指南**

---

## 系统要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| Go | >= 1.24 | Go 编程语言 |
| goctl | >= 1.6 | Go-Zero CLI 工具 |
| uv | >= 0.1 | Python 包管理器 |
| Git | >= 2.0 | 版本控制 |

### 可选依赖

| 依赖 | 版本 | 说明 |
|------|------|------|
| Docker | >= 20.0 | 容器化部署 |
| kubectl | >= 1.25 | Kubernetes CLI |
| MySQL | >= 8.0 | 数据库 |

---

## 安装 Spec Kit CLI

### 方式 1: 持久安装 (推荐)

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

验证安装：
```bash
specify --version
```

### 方式 2: 一次性运行

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init .
```

### 升级 Spec Kit

```bash
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git
```

---

## 安装 IDRM SDD Templates

### 方式 1: 远程安装 (推荐)

```bash
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
```

### 方式 2: 指定版本安装

```bash
# 安装 v0.2.0
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/v0.2.0/scripts/sdd-install.sh | bash
```

### 方式 3: 本地安装

```bash
git clone https://github.com/jinguoxing/idrm-sdd-templates.git /tmp/idrm-sdd
/tmp/idrm-sdd/scripts/sdd-install.sh
```

---

## 交互式配置说明

安装脚本会引导你完成以下配置：

### 1. 服务类型选择

```
[1] API      - HTTP API 服务 (go-zero api)
[2] RPC      - gRPC 微服务 (go-zero zrpc)
[3] Job      - 定时任务服务
[4] Consumer - 消息队列消费者 (Kafka/Redis)
[0] 跳过     - 仅安装模板，不初始化服务
```

可多选，用逗号分隔，如 `1,2` 表示同时创建 API 和 RPC 服务。

### 2. 项目信息

| 配置项 | 说明 | 示例 |
|--------|------|------|
| 项目名称 | 项目名 | `my-project` |
| Go Module | Go 模块路径 | `github.com/company/my-project` |

### 3. 数据库配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| MySQL 主机 | `localhost` | 数据库地址 |
| MySQL 端口 | `3306` | 数据库端口 |
| MySQL 用户名 | `root` | 数据库用户 |
| MySQL 密码 | - | 数据库密码 |
| MySQL 数据库 | `idrm` | 数据库名称 |

---

## 安装后目录结构

```
my-project/
├── .specify/                 # SDD 配置
│   ├── templates/            # IDRM 模板
│   ├── memory/               # 项目宪法
│   └── scripts/bash/         # 官方脚本
├── .cursor/commands/         # Cursor 命令 (官方)
├── api/                      # API 服务
│   ├── doc/
│   │   ├── api.api           # API 入口
│   │   ├── base.api          # 基础类型
│   │   └── swagger.json      # Swagger 文档
│   └── etc/
│       └── api.yaml          # 配置文件
├── deploy/                   # 部署文件
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── docker-compose.yaml
│   └── k8s/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
├── model/                    # Model 层
├── migrations/               # DDL 迁移
├── Makefile                  # 常用命令
├── go.mod                    # Go 模块
└── .sdd-version              # 版本记录
```

---

## 升级 IDRM 模板

### 检查更新

```bash
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh | bash -- --check
```

### 执行升级

```bash
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh | bash
```

---

## 常见问题

### 1. specify 命令找不到

确保 uv 工具目录在 PATH 中：
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 2. 安装脚本下载失败

检查网络连接，或使用本地安装方式。

### 3. goctl 未安装

```bash
go install github.com/zeromicro/go-zero/tools/goctl@latest
```

---

## 下一步

- [SDD 工作流程详解](workflow.md)
- [模板使用指南](templates-guide.md)
- [部署指南](deployment.md)

# Go-Zero 项目模板

> **Go-Zero 微服务项目结构和模板说明**

---

## 目录结构

```
go-zero/
├── Makefile.tpl                # Makefile 模板
├── go.mod.tpl                  # go.mod 模板
│
├── api/                        # API 服务模板
│   ├── doc/
│   │   ├── api.api.tpl         # API 入口文件
│   │   └── base.api            # 基础类型定义
│   └── etc/
│       └── api.yaml.tpl        # API 配置
│
├── rpc/                        # RPC 服务模板
│   └── etc/
│       └── rpc.yaml.tpl        # RPC 配置
│
├── job/                        # Job 服务模板
│   └── etc/
│       └── job.yaml.tpl        # Job 配置
│
├── consumer/                   # Consumer 服务模板
│   └── etc/
│       └── consumer.yaml.tpl   # Consumer 配置
│
└── deploy/                     # 部署模板
    ├── docker/
    │   ├── Dockerfile.tpl      # Docker 镜像构建
    │   └── docker-compose.yaml.tpl
    └── k8s/
        ├── deployment.yaml.tpl
        ├── service.yaml.tpl
        └── configmap.yaml.tpl
```

---

## 服务类型说明

| 类型 | 说明 | 用途 |
|------|------|------|
| API | HTTP API 服务 | 对外提供 RESTful 接口 |
| RPC | gRPC 微服务 | 内部服务间通信 |
| Job | 定时任务 | 后台定时执行任务 |
| Consumer | 消息消费者 | 消费 Kafka/Redis 消息 |

---

## 分层架构

```
┌────────────────────────────────────────────┐
│  Handler 层 (api/internal/handler/)        │
│  - 参数绑定与校验                           │
│  - 调用 Logic 层                           │
│  - 响应格式化                               │
├────────────────────────────────────────────┤
│  Logic 层 (api/internal/logic/)            │
│  - 业务逻辑实现                             │
│  - 事务管理                                 │
│  - 调用 Model 层                           │
├────────────────────────────────────────────┤
│  Model 层 (model/)                         │
│  - GORM: 复杂查询、事务                     │
│  - SQLx: 简单 CRUD、高性能查询              │
└────────────────────────────────────────────┘
```

---

## 配置文件说明

### api.yaml

```yaml
Name: project-api          # 服务名称
Host: 0.0.0.0              # 监听地址
Port: 8888                 # 监听端口

Telemetry:                 # 可观测性配置
  ServiceName: project-api
  Log:
    Level: info
    Mode: file
    Path: logs

DB:                        # 数据库配置
  Default:
    Host: localhost
    Port: 3306
    Database: my_db
    Username: root
    Password: password

Auth:                      # 认证配置
  AccessSecret: xxx
  AccessExpire: 7200
```

### rpc.yaml

```yaml
Name: project-rpc
Host: 0.0.0.0
Port: 9999

Etcd:                      # 服务注册
  Hosts:
    - 127.0.0.1:2379
  Key: project.rpc
```

---

## 模板变量

安装脚本会自动替换以下变量：

| 变量 | 说明 | 示例 |
|------|------|------|
| `{{PROJECT_NAME}}` | 项目名称 | `my-project` |
| `{{GO_MODULE}}` | Go 模块路径 | `github.com/xxx/my-project` |
| `{{DOCKER_REGISTRY}}` | Docker 仓库 | `docker.io` |
| `{{DB_HOST}}` | 数据库主机 | `localhost` |
| `{{DB_PORT}}` | 数据库端口 | `3306` |
| `{{DB_NAME}}` | 数据库名 | `idrm` |
| `{{DB_USER}}` | 数据库用户 | `root` |
| `{{DB_PASSWORD}}` | 数据库密码 | `password` |
| `{{ACCESS_SECRET}}` | JWT 密钥 | `自动生成` |

---

## 生成后的项目结构

```
my-project/
├── api/
│   ├── api.go                  # 入口文件
│   ├── doc/
│   │   ├── api.api             # API 定义入口
│   │   ├── base.api            # 基础类型
│   │   └── swagger.json        # Swagger 文档
│   ├── etc/
│   │   └── api.yaml            # 配置文件
│   └── internal/
│       ├── handler/            # Handler 层
│       ├── logic/              # Logic 层
│       ├── svc/                # 服务上下文
│       └── types/              # 类型定义
│
├── rpc/                        # RPC 服务 (可选)
│   ├── proto/
│   ├── etc/
│   └── internal/
│
├── model/                      # Model 层
│   ├── gorm/                   # GORM 模型
│   └── sqlx/                   # SQLx 模型
│
├── deploy/                     # 部署文件
│   ├── docker/
│   └── k8s/
│
├── migrations/                 # DDL 迁移
├── Makefile                    # 常用命令
└── go.mod
```

---

## 常用命令

```bash
# 生成 API 代码
make api

# 生成 Swagger 文档
make swagger

# 一键生成
make gen

# 运行服务
make run

# 构建
make build

# Docker 构建
make docker-build

# K8s 部署
make k8s-deploy
```

---

## 开发流程

1. **定义 API**: 在 `api/doc/` 编写 `.api` 文件
2. **生成代码**: `make api`
3. **编写 DDL**: 在 `migrations/` 编写 SQL
4. **生成 Model**: 使用 goctl 或手写
5. **实现 Logic**: 在 `api/internal/logic/` 编写业务逻辑
6. **测试**: `make test`
7. **部署**: `make docker-build && make k8s-deploy`

---

## 下一步

- [部署指南](deploy/README.md)
- [SDD 工作流程](../docs/workflow.md)

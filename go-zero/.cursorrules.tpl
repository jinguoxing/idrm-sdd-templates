# IDRM Go-Zero 项目 AI 规则

## 项目信息

- **项目名称**: {{PROJECT_NAME}}
- **Go Module**: {{GO_MODULE}}
- **技术栈**: Go 1.24+ | Go-Zero v1.9+ | MySQL 8.0 | GORM + SQLx

---

## 架构规范

### 分层架构 (严格遵守)

```
Handler 层 (api/internal/handler/)
├── 职责: 参数绑定、校验、调用 Logic、响应格式化
├── 禁止: 包含业务逻辑、直接操作数据库
└── 规范: 使用 validator 进行参数校验

Logic 层 (api/internal/logic/)
├── 职责: 业务逻辑、事务管理、调用 Model
├── 禁止: 直接操作 HTTP Request/Response
└── 规范: 一个方法一个事务边界

Model 层 (model/)
├── GORM: 复杂查询、关联查询、事务操作
├── SQLx: 简单 CRUD、高性能查询
└── 禁止: 包含业务逻辑
```

### 目录结构

```
{{PROJECT_NAME}}/
├── api/                      # API 服务
│   ├── doc/                  # API 定义 (.api 文件)
│   ├── etc/                  # 配置文件
│   └── internal/
│       ├── handler/          # Handler 层
│       ├── logic/            # Logic 层
│       ├── svc/              # ServiceContext
│       └── types/            # 类型定义 (goctl 生成)
├── model/                    # Model 层
│   ├── gorm/                 # GORM 模型
│   └── sqlx/                 # SQLx 模型
├── migrations/               # DDL 迁移文件
├── specs/                    # SDD 规格文档
└── deploy/                   # 部署文件
```

---

## SDD 工作流程

遵循 Spec-Driven Development 5 阶段工作流:

1. **Phase 0: Context** - 读取 .specify/memory/constitution.md 理解项目规范
2. **Phase 1: Specify** - 使用 /speckit.specify 定义需求 (EARS 格式)
3. **Phase 2: Design** - 使用 /speckit.plan 创建技术方案
4. **Phase 3: Tasks** - 使用 /speckit.tasks 拆分任务 (<50行/任务)
5. **Phase 4: Implement** - 使用 /speckit.implement 编码实现

**每个阶段结束后必须等待用户确认后再继续!**

---

## 编码规范

### 命名约定

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | 小写下划线 | `user_handler.go` |
| 包名 | 小写无下划线 | `handler`, `logic` |
| 结构体 | 大驼峰 | `UserInfo` |
| 方法 | 大驼峰 | `GetUserById` |
| 常量 | 全大写下划线 | `MAX_RETRY_COUNT` |
| 变量 | 小驼峰 | `userId` |

### 注释规范

```go
// UserHandler 用户相关接口处理器
// 负责处理用户登录、注册、信息查询等操作
type UserHandler struct {
    svc *svc.ServiceContext
}

// Login 用户登录
// @param req 登录请求，包含手机号和密码
// @return 登录响应，包含 token 和用户信息
func (h *UserHandler) Login(ctx context.Context, req *types.LoginReq) (*types.LoginResp, error) {
    // 实现逻辑...
}
```

### 错误处理

```go
// 使用 errors.Wrapf 包装错误
if err != nil {
    return nil, errors.Wrapf(err, "failed to get user by id: %d", userId)
}

// 业务错误使用自定义错误码
if user == nil {
    return nil, xerr.NewCodeError(xerr.UserNotFound, "用户不存在")
}
```

---

## API 设计规范

### .api 文件规范

```api
syntax = "v1"

info (
    title:   "用户模块"
    desc:    "用户登录、注册、信息管理"
    version: "v1"
)

// 请求结构体使用 Req 后缀
type LoginReq {
    Phone    string `json:"phone" validate:"required,len=11"`
    Password string `json:"password" validate:"required,min=8"`
}

// 响应结构体使用 Resp 后缀
type LoginResp {
    Token    string   `json:"token"`
    UserInfo UserInfo `json:"user_info"`
}

@server (
    prefix: /api/v1
    group:  user
)
service api {
    @doc "用户登录"
    @handler Login
    post /user/login (LoginReq) returns (LoginResp)
}
```

### RESTful 规范

| 方法 | 用途 | 示例 |
|------|------|------|
| GET | 查询 | `GET /api/v1/users/:id` |
| POST | 创建 | `POST /api/v1/users` |
| PUT | 更新 | `PUT /api/v1/users/:id` |
| DELETE | 删除 | `DELETE /api/v1/users/:id` |

---

## 数据库规范

### DDL 模板

```sql
CREATE TABLE IF NOT EXISTS `table_name` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
    -- 业务字段
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    -- 索引
    UNIQUE KEY `uk_xxx` (`xxx`),
    KEY `idx_xxx` (`xxx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='表注释';
```

### ORM 选择

- **GORM**: 复杂查询、关联查询、事务操作
- **SQLx**: 简单 CRUD、高性能查询、批量操作

---

## 常用命令

```bash
# API 代码生成
make api                    # 生成 API 代码
make swagger                # 生成 Swagger 文档
make gen                    # 一键生成 API + Swagger

# 开发
make run                    # 运行服务
make test                   # 运行测试
make lint                   # 代码检查

# 部署
make docker-build           # 构建 Docker 镜像
make k8s-deploy             # 部署到 K8s
```

---

## 重要约束

### 必须遵守

1. **分层原则**: Handler 不包含业务逻辑，Logic 不操作 HTTP
2. **参数校验**: 使用 validator 标签，在 Handler 层校验
3. **错误处理**: 使用 errors.Wrapf 包装，提供上下文信息
4. **事务边界**: 在 Logic 层管理，一个业务操作一个事务
5. **日志规范**: 使用 logx，包含 traceId、关键参数

### 禁止事项

1. ❌ 在 Handler 层直接操作数据库
2. ❌ 在 Model 层包含业务逻辑
3. ❌ 硬编码配置值 (使用配置文件)
4. ❌ 忽略错误返回值
5. ❌ 使用 fmt.Println 替代 logx

---

## 参考文档

- [Go-Zero 官方文档](https://go-zero.dev/)
- [GORM 官方文档](https://gorm.io/)
- [Spec Kit 文档](https://github.com/github/spec-kit)
- [项目宪法](.specify/memory/constitution.md)

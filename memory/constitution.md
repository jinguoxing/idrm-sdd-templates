# 项目宪章 (Project Constitution)

> **版本**：v2.0  
> **更新日期**：2025-12-31

---

## 📖 项目定义

本项目基于 Go-Zero 微服务架构构建，采用 AI 辅助的规范驱动开发模式。

| 项目 | 值 |
|------|-----|
| 架构 | Go-Zero 微服务 + 双 ORM |
| 语言 | Go 1.21+ |
| 框架 | Go-Zero v1.9+ |
| 数据库 | MySQL 8.0 |
| 缓存 | Redis 7.0 |
| 消息队列 | Kafka 3.0 |

---

## 🚫 强制约束

### ❌ 严禁

| 规则 | 说明 |
|------|------|
| 跳过工作流阶段 | 必须按 5 阶段顺序执行 |
| Handler 写业务逻辑 | Handler 只负责参数解析和响应格式化 |
| Logic 直接访问数据库 | 必须通过 Model 层 |
| 忽略错误返回 | 所有 error 必须处理 |
| 函数超过 50 行 | 保持函数小而专注 |
| 硬编码配置 | 使用环境变量或配置文件 |
| 跳过接口直接用实现 | 依赖抽象而非具体 |

### ✅ 必须

| 规则 | 说明 |
|------|------|
| 先读规范再编码 | 阅读 constitution.md 和相关模板 |
| 遵循分层架构 | Handler → Logic → Model |
| 使用 Model 接口 | 支持 GORM 和 SQLx 双 ORM |
| 中文注释 | 所有公开接口必须有中文注释 |
| 错误包装 | 使用 `fmt.Errorf("context: %w", err)` |
| 测试覆盖 | 核心逻辑 ≥80% |

---

## 🔄 5 阶段工作流

**每个阶段完成后必须等待用户确认，禁止自动进入下一阶段。**

```
Phase 0: Context    → 理解规范，准备环境
   ⚠️ STOP - 等待用户确认
Phase 1: Specify    → 定义业务需求 (EARS 格式)
   ⚠️ STOP - 等待用户确认
Phase 2: Design     → 创建技术方案
   ⚠️ STOP - 等待用户确认
Phase 3: Tasks      → 拆分任务 (<50行)
   ⚠️ STOP - 等待用户确认
Phase 4: Implement  → 编码、测试、验证
```

### 阶段产出

| 阶段 | 产出文件 | 模板 |
|------|----------|------|
| 0: Context | 理解总结 | - |
| 1: Specify | `specs/{feature}/spec.md` | `.specify/templates/spec-template.md` |
| 2: Design | `specs/{feature}/plan.md` | `.specify/templates/plan-template.md` |
| 3: Tasks | `specs/{feature}/tasks.md` | `.specify/templates/tasks-template.md` |
| 4: Implement | 可运行代码 + 测试 | - |

### EARS 格式 (Phase 1)

```
WHEN [条件/事件]
THE SYSTEM SHALL [期望行为]
```

---

## 🏗️ 分层架构

```
HTTP Request → Handler → Logic → Model → Database
```

### 层级职责

| 层级 | 目录 | 职责 | 最大行数 |
|------|------|------|----------|
| Handler | `api/internal/handler/` | 解析参数、格式化响应 | 30 |
| Logic | `api/internal/logic/` | 业务逻辑实现 | 50 |
| Model | `model/` | 数据访问 | 50 |

### 层级规则

**Handler 层**：
- ✅ 解析 HTTP 请求
- ✅ 调用 Logic 层
- ✅ 返回统一响应
- ❌ 不含业务逻辑
- ❌ 不直接访问数据库

**Logic 层**：
- ✅ 实现业务规则
- ✅ 调用 Model 层
- ✅ 数据转换
- ❌ 不含 HTTP 相关代码
- ❌ 不直接访问数据库

**Model 层**：
- ✅ 定义数据访问接口
- ✅ 实现 CRUD 操作
- ✅ 事务管理
- ❌ 不含业务逻辑

---

## 📁 Model 层结构

### 目录组织

```
model/{module}/{table}/
├── interface.go    # Model 接口定义
├── types.go        # 数据结构
├── vars.go         # 常量和错误定义
├── factory.go      # ORM 工厂函数
├── gorm_dao.go     # GORM 实现
└── sqlx_model.go   # SQLx 实现
```

### 接口定义

```go
type Model interface {
    Insert(ctx context.Context, data *T) (*T, error)
    FindOne(ctx context.Context, id int64) (*T, error)
    Update(ctx context.Context, data *T) error
    Delete(ctx context.Context, id int64) error
    WithTx(tx interface{}) Model
    Trans(ctx context.Context, fn func(ctx context.Context, model Model) error) error
}
```

### 双 ORM 选择

| ORM | 适用场景 |
|-----|----------|
| **GORM** | 复杂查询、关联加载、事务管理 |
| **SQLx** | 简单查询、性能敏感、批量操作 |

---

## 🔢 错误码范围

| 范围 | 类型 |
|------|------|
| 10000-19999 | 系统错误 |
| 20000-29999 | 业务错误 |
| 30000-39999 | 验证错误 |
| 40000-49999 | 权限错误 |

---

## 📝 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件 | 小写下划线 | `category_logic.go` |
| 包名 | 小写无下划线 | `category` |
| 类型 | PascalCase | `CategoryModel` |
| 函数 | camelCase/PascalCase | `createCategory` |
| Handler | `{action}{resource}handler.go` | `createcategoryhandler.go` |
| Logic | `{action}{resource}logic.go` | `createcategorylogic.go` |

---

## 🌐 API 规范

### RESTful 端点

```
GET    /api/v1/resources       # 列表
GET    /api/v1/resources/:id   # 详情
POST   /api/v1/resources       # 创建
PUT    /api/v1/resources/:id   # 更新
DELETE /api/v1/resources/:id   # 删除
```

### 响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

### HTTP 状态码

| 状态码 | 含义 |
|--------|------|
| 200 | 成功 |
| 201 | 创建成功 |
| 400 | 请求错误 |
| 401 | 未授权 |
| 404 | 未找到 |
| 500 | 服务器错误 |

---

## ✅ 质量检查清单

```bash
go build ./...              # 编译检查
go test -cover ./...        # 测试检查 (>80%)
golangci-lint run           # 代码检查
```

| 检查项 | 标准 |
|--------|------|
| 编译 | 无错误 |
| 测试 | 覆盖率 ≥80% |
| Lint | 无错误 |
| 函数 | ≤50 行 |
| 注释 | 公开接口必须有 |

---

**版本**: v2.0  
**更新日期**: 2025-12-31

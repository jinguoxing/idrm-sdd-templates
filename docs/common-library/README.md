# idrm-go-base 通用库

> **仓库**: https://github.com/jinguoxing/idrm-go-base  
> **版本**: v0.1.0+

---

## 模块

| 模块 | 说明 | 文档 |
|------|------|------|
| [errorx](errorx.md) | 错误码和业务错误 | → |
| [response](response.md) | 统一响应格式 | → |
| [middleware](middleware.md) | API 中间件 | → |
| [validator](validator.md) | 参数校验 | → |
| [telemetry](telemetry.md) | 日志/追踪/审计 | → |

---

## 使用规则

### 必须使用

以下场景 **必须** 使用通用库：

| 场景 | 使用模块 | 禁止行为 |
|------|----------|----------|
| 错误处理 | `errorx` | ❌ 自定义 error struct |
| HTTP 响应 | `response` | ❌ 自定义响应格式 |
| API 中间件 | `middleware` | ❌ 重复实现认证/日志 |
| 参数校验 | `validator` | ❌ 手写校验逻辑 |
| 日志追踪 | `telemetry` | ❌ 直接使用 fmt/log |

### 引入其他库

如需使用通用库以外的第三方库：

1. **先确认** 通用库是否已提供相同功能
2. **必须提出** 并说明原因，等待确认
3. **记录** 在 plan.md 的依赖章节

---

## 安装

```bash
go get github.com/jinguoxing/idrm-go-base@latest
```

---

## 快速使用

```go
import (
    "github.com/jinguoxing/idrm-go-base/errorx"
    "github.com/jinguoxing/idrm-go-base/response"
    "github.com/jinguoxing/idrm-go-base/middleware"
    "github.com/jinguoxing/idrm-go-base/validator"
    "github.com/jinguoxing/idrm-go-base/telemetry"
)
```

---

## 错误码规范

### 预定义范围

| 范围 | 类型 |
|------|------|
| 10000-19999 | 系统错误 |
| 20000-29999 | 参数错误 |
| 30000-39999 | 业务错误 |
| 40000-49999 | 认证错误 |

### 自定义规则

按功能模块分配范围 (每模块 100 个)：
- 用户模块: 30100-30199
- 订单模块: 30200-30299
- ...

详见 [errorx.md](errorx.md)

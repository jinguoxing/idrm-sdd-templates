# middleware - API 中间件

> **Import**: `github.com/jinguoxing/idrm-go-base/middleware`

---

## 中间件列表

| 中间件 | 功能 |
|--------|------|
| `AuthMiddleware` | JWT 认证 |
| `CorsMiddleware` | CORS 跨域 |
| `LoggerMiddleware` | 请求日志 |
| `RecoveryMiddleware` | Panic 恢复 |
| `RequestIdMiddleware` | 请求 ID |
| `TraceMiddleware` | 链路追踪 |

---

## 使用方式

### 全局配置

```go
import "github.com/jinguoxing/idrm-go-base/middleware"

func main() {
    server := rest.MustNewServer(c.RestConf,
        rest.WithMiddlewares(
            middleware.RecoveryMiddleware(),
            middleware.RequestIdMiddleware(),
            middleware.LoggerMiddleware(),
            middleware.CorsMiddleware(),
        ),
    )
    defer server.Stop()
}
```

### 路由级配置

```go
server.AddRoutes(
    rest.WithMiddlewares(
        []rest.Middleware{middleware.AuthMiddleware(c.Auth.AccessSecret)},
        routes...,
    ),
)
```

---

## 各中间件详解

### AuthMiddleware - JWT 认证

```go
middleware.AuthMiddleware(accessSecret string)
```

功能：
- 解析 Authorization: Bearer {token}
- 验证 token 有效性
- 将用户信息注入 context

### CorsMiddleware - 跨域

```go
middleware.CorsMiddleware()
```

默认配置：
- 允许所有来源
- 允许常用 HTTP 方法
- 允许常用请求头

### LoggerMiddleware - 请求日志

```go
middleware.LoggerMiddleware()
```

记录内容：
- 请求方法、路径
- 响应状态码
- 处理耗时

### RecoveryMiddleware - Panic 恢复

```go
middleware.RecoveryMiddleware()
```

功能：
- 捕获 panic
- 记录错误日志
- 返回 500 响应

### RequestIdMiddleware - 请求 ID

```go
middleware.RequestIdMiddleware()
```

功能：
- 生成唯一请求 ID
- 注入请求头和 context
- 用于日志追踪

### TraceMiddleware - 链路追踪

```go
middleware.TraceMiddleware()
```

功能：
- OpenTelemetry 集成
- 创建 span
- 传播 trace context

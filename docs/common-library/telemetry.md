# telemetry - 遥测

> **Import**: `github.com/jinguoxing/idrm-go-base/telemetry`

---

## 子模块

| 子模块 | 说明 |
|--------|------|
| `telemetry/log` | 统一日志 |
| `telemetry/trace` | 链路追踪 |
| `telemetry/audit` | 审计日志 |

---

## 初始化

```go
import "github.com/jinguoxing/idrm-go-base/telemetry"

func main() {
    cfg := telemetry.Config{
        ServiceName: "user-api",
        Environment: "production",
        Log: telemetry.LogConfig{
            Level: "info",
        },
        Trace: telemetry.TraceConfig{
            Enabled:  true,
            Endpoint: "localhost:4317",
        },
    }
    
    if err := telemetry.Init(cfg); err != nil {
        log.Fatal(err)
    }
    defer telemetry.Shutdown()
}
```

---

## 日志 (telemetry/log)

### 使用

```go
import "github.com/jinguoxing/idrm-go-base/telemetry/log"

log.Info("user login", log.Field("userId", userId))
log.Error("login failed", log.Field("error", err))
```

### 日志级别

- Debug
- Info
- Warn
- Error

---

## 链路追踪 (telemetry/trace)

### 创建 Span

```go
import "github.com/jinguoxing/idrm-go-base/telemetry/trace"

func (l *LoginLogic) Login(req *types.LoginReq) (*types.LoginResp, error) {
    ctx, span := trace.Start(l.ctx, "Login")
    defer span.End()
    
    span.SetAttribute("phone", req.Phone)
    
    // 业务逻辑...
}
```

---

## 审计日志 (telemetry/audit)

### 记录审计日志

```go
import "github.com/jinguoxing/idrm-go-base/telemetry/audit"

audit.Log(ctx, audit.Event{
    Action:   "user.login",
    UserId:   userId,
    Resource: "user",
    Result:   "success",
    Details:  map[string]interface{}{"ip": clientIP},
})
```

### 审计事件类型

| 类型 | 说明 |
|------|------|
| user.login | 用户登录 |
| user.logout | 用户登出 |
| user.register | 用户注册 |
| data.create | 数据创建 |
| data.update | 数据更新 |
| data.delete | 数据删除 |

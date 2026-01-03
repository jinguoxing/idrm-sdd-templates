# errorx - 错误处理

> **Import**: `github.com/jinguoxing/idrm-go-base/errorx`

---

## 错误码范围

| 范围 | 类型 | 预定义常量 |
|------|------|-----------|
| 10000-19999 | 系统错误 | ErrCodeSystem, ErrCodeDatabase, ErrCodeRedis... |
| 20000-29999 | 参数错误 | ErrCodeParam, ErrCodeParamMissing... |
| 30000-39999 | 业务错误 | ErrCodeBusiness, ErrCodeNotFound... |
| 40000-49999 | 认证错误 | ErrCodeAuth, ErrCodeTokenInvalid... |

---

## API

### CodeError 结构

```go
type CodeError struct {
    Code int    `json:"code"`
    Msg  string `json:"msg"`
}
```

### 创建错误

```go
// 使用预定义错误码
err := errorx.NewWithCode(errorx.ErrCodeNotFound)

// 自定义消息
err := errorx.New(errorx.ErrCodeBusiness, "用户不存在")

// 自定义业务错误
err := errorx.NewWithMsg(30101, "用户已被禁用")
```

---

## 自定义错误码规范

### 分配规则

按功能模块分配 100 个错误码：

| 功能 | 范围 |
|------|------|
| 用户模块 | 30100-30199 |
| 订单模块 | 30200-30299 |
| 商品模块 | 30300-30399 |
| ... | ... |

### 定义位置

在项目中创建 `internal/errorx/codes.go`:

```go
package errorx

const (
    // 用户模块 30100-30199
    ErrCodeUserNotFound     = 30101  // 用户不存在
    ErrCodeUserDisabled     = 30102  // 用户已禁用
    ErrCodePhoneRegistered  = 30103  // 手机号已注册
)

var errMsgMap = map[int]string{
    ErrCodeUserNotFound:    "用户不存在",
    ErrCodeUserDisabled:    "用户已禁用",
    ErrCodePhoneRegistered: "手机号已注册",
}
```

---

## 使用示例

```go
func (l *LoginLogic) Login(req *types.LoginReq) (*types.LoginResp, error) {
    user, err := l.svcCtx.UserModel.FindByPhone(l.ctx, req.Phone)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, errorx.NewWithCode(errorx.ErrCodeNotFound)
        }
        return nil, errorx.NewWithCode(errorx.ErrCodeDatabase)
    }
    
    if user.Status == 0 {
        return nil, errorx.New(30102, "用户已禁用")
    }
    
    return &types.LoginResp{Token: token}, nil
}
```

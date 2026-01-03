# validator - 参数校验

> **Import**: `github.com/jinguoxing/idrm-go-base/validator`

---

## 特性

- 基于 go-playground/validator
- 中文错误消息
- 自定义校验规则 (手机号、身份证等)

---

## 初始化

在 `main.go` 或 API 入口初始化：

```go
import "github.com/jinguoxing/idrm-go-base/validator"

func main() {
    // 初始化校验器
    if err := validator.Init(); err != nil {
        log.Fatal(err)
    }
    
    // ...
}
```

---

## API

### 校验结构体

```go
err := validator.Validate(req)
if err != nil {
    return nil, errorx.New(errorx.ErrCodeParam, err.Error())
}
```

---

## 使用示例

### 定义请求结构

```go
type RegisterReq struct {
    Phone    string `json:"phone" validate:"required,phone"`
    Password string `json:"password" validate:"required,min=8,max=32"`
    Code     string `json:"code" validate:"required,len=6"`
}
```

### Logic 中校验

```go
func (l *RegisterLogic) Register(req *types.RegisterReq) (*types.RegisterResp, error) {
    // 参数校验
    if err := validator.Validate(req); err != nil {
        return nil, errorx.New(errorx.ErrCodeParam, err.Error())
    }
    
    // 业务逻辑...
}
```

---

## 内置规则

### 标准规则

| 规则 | 说明 | 示例 |
|------|------|------|
| required | 必填 | `validate:"required"` |
| min | 最小长度/值 | `validate:"min=8"` |
| max | 最大长度/值 | `validate:"max=32"` |
| len | 固定长度 | `validate:"len=6"` |
| email | 邮箱格式 | `validate:"email"` |

### 自定义规则

| 规则 | 说明 | 示例 |
|------|------|------|
| phone | 手机号 | `validate:"phone"` |
| idcard | 身份证号 | `validate:"idcard"` |

---

## 错误消息

校验失败返回中文错误消息：

```
手机号格式错误
密码长度不能少于8位
验证码不能为空
```

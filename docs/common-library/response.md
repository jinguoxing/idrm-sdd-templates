# response - 统一响应格式

> **Import**: `github.com/jinguoxing/idrm-go-base/response`

---

## 响应格式

```json
{
    "code": 0,
    "message": "success",
    "data": {}
}
```

---

## API

### 成功响应

```go
response.Success(data)
```

### 失败响应

```go
response.Error(code, message)
```

### HTTP 响应处理

```go
response.HttpResult(r, w, resp, err)
```

---

## 配置

在 `main.go` 中配置统一错误处理：

```go
import "github.com/jinguoxing/idrm-go-base/response"

func main() {
    // 配置错误处理器
    httpx.SetErrorHandler(response.ErrorHandler)
    
    // ...
}
```

---

## 使用示例

### Handler 中使用

```go
func GetUserHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        var req types.GetUserReq
        if err := httpx.Parse(r, &req); err != nil {
            response.HttpResult(r, w, nil, err)
            return
        }

        l := logic.NewGetUserLogic(r.Context(), svcCtx)
        resp, err := l.GetUser(&req)
        response.HttpResult(r, w, resp, err)
    }
}
```

### Logic 中返回

```go
func (l *GetUserLogic) GetUser(req *types.GetUserReq) (*types.GetUserResp, error) {
    user, err := l.svcCtx.UserModel.FindOne(l.ctx, req.Id)
    if err != nil {
        return nil, errorx.NewWithCode(errorx.ErrCodeNotFound)
    }
    
    // 直接返回，response 会自动包装
    return &types.GetUserResp{
        Id:   user.Id,
        Name: user.Name,
    }, nil
}
```

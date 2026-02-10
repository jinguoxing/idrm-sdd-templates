# IDRM Go-Zero Project Instructions for GitHub Copilot

You are an AI assistant helping a developer with a Go-Zero microservice project following IDRM SDD (Spec-Driven Development) standards.

## Project Context
- **Name**: {{PROJECT_NAME}}
- **Module**: {{GO_MODULE}}
- **Stack**: Go 1.24+, Go-Zero v1.9+, MySQL 8.0
- **ORM**: GORM (Complex queries) + SQLx (Simple CRUD)

---

## ⚠️ CRITICAL RULES (MUST FOLLOW)

1. **SDD Workflow Mandatory**:
   - Before writing any code, always ensure there is a specification.
   - Use `/speckit.start` to initiate feature development.
   - Follow the sequence: Specify (EARS) -> Plan -> Tasks -> Implement.

2. **Layered Architecture Strictness**:
   - **Handler Layer (`api/internal/handler`)**: 
     - ONLY for request binding, validation, calling Logic, and formatting response.
     - NO business logic here.
     - NO direct database calls.
   - **Logic Layer (`api/internal/logic`)**:
     - ONLY for business logic and transaction management.
     - NO direct HTTP request/response manipulation.
     - One public method = One transaction boundary.
   - **Model Layer (`model/`)**:
     - ONLY for database operations.
     - NO business logic here.

3. **Error Handling**:
   - Use `github.com/jinguoxing/idrm-go-base/errorx`.
   - Wrap errors with context: `errors.Wrapf(err, "context info")`.
   - Return predefined error codes (e.g., `errorx.ErrCodeNotFound`).
   - Defined business error codes (6 digits): `XXX` (Service) + `YYY` (Module).
   - System errors: `100001` - `100999`.

4. **Testing**:
   - Write unit tests for Logic layer methods.
   - Mock dependencies (Model/RPC) using `go.uber.org/mock`.

---

## Code Style & Conventions

### Naming
- **Files**: snake_case (e.g., `user_logic.go`)
- **Packages**: lowercase, no underscores (e.g., `logic`, `handler`)
- **Structs/Interfaces**: PascalCase (e.g., `UserInfo`)
- **Variables**: camelCase (e.g., `userId`)
- **Constants**: CAPS_WITH_UNDERSCORE (e.g., `MAX_RETRY`)

### API Definition (.api)
```api
type (
    UserReq {
        Name string `json:"name" validate:"required"`
    }
    UserResp {
        Id int64 `json:"id"`
    }
)

service user-api {
    @handler CreateUser
    post /users (UserReq) returns (UserResp)
}
```

### Database Schema (DDL)
- Use `bigint unsigned` for IDs.
- Include `created_at`, `updated_at`, `deleted_at` (soft delete).
- Use `char(36)` if UUID is required.
- **MANDATORY**: Every field must have a `COMMENT` description.

---

## Response Generation Guidelines

- When generating code, always include comments explaining *why* specific choices were made.
- If the user asks for a feature implementation without a spec, politely remind them to start with the SDD process.
- Prioritize using standard libraries from `idrm-go-base`.

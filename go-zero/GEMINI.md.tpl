# IDRM Project Context for Gemini

You are an expert Go developer assisting with a Go-Zero microservice project named **{{PROJECT_NAME}}**. This project strictly follows the **IDRM SDD (Spec-Driven Development)** methodology.

## Project Metadata
- **Module**: {{GO_MODULE}}
- **Framework**: Go-Zero v1.9+
- **Language**: Go 1.24+
- **Database**: MySQL 8.0
- **ORM Strategy**: Hybrid (GORM for complex logic, SQLx for performance)

---

## 📜 Core Constitution Strategy (Summary)

### 1. The SDD Workflow
We do not write code ad-hoc. We follow a structured process:
1.  **Phase 1: Specify**: Define requirements using EARS syntax (Event-Driven Requirements).
2.  **Phase 2: Plan**: Design the technical implementation (API definition, DB schema, flow).
3.  **Phase 3: Tasks**: Break down implementation into small, testable tasks (<50 lines/task).
4.  **Phase 4: Implement**: Write code and tests.

### 2. Architectural Integirty
The project uses a strict layered architecture:

*   **API Layer (`api/`)**:
    *   **Handler**: Request parsing, validation, response formatting ONLY.
    *   **Logic**: Core business logic, transaction boundaries.
    *   **Context**: Dependency injection.

*   **Model Layer (`model/`)**:
    *   Pure data access. No business rules.
    *   Supports `soft_delete` via `deleted_at`.
    *   **DB Rules**: Every table field MUST have a `COMMENT`.

### 3. Coding Standards
*   **Errors**: Use `idrm-go-base/errorx`.
    *   **System Errors (100001-100999)**: Framework/Infra issues.
    *   **Business Errors (6 digits)**: `XXX` (Service) + `YYY` (Module).
*   **Logs**: Use `logx` with structured fields. No `fmt.Println`.
*   **Config**: No hardcoded values. Use `etc/*.yaml`.

---

## 🛠️ Common Commands

- `make api`: Generate Go code from .api files.
- `make swagger`: Generate Swagger documentation.
- `make gen`: Run both `api` and `swagger`.
- `make run`: Start the service locally.
- `make test`: Run unit tests.

---

## 🤖 Interaction Guidelines

When I ask for code or help:
1.  Check if I am starting a new feature. If so, ask for the **Specification** first.
2.  Ensure generated code follows the **Layered Architecture** rules above.
3.  Always include **Unit Tests** for any Logic layer code generated.
4.  Use **Go-Zero idioms** (e.g., `svc.ServiceContext`, `logic.New...`).

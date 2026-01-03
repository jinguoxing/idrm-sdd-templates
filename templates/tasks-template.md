# {{feature_name}} Tasks

> **Branch**: `feature/{{feature_name}}`  
> **Spec Path**: `specs/{{feature_name}}/`  
> **Created**: {{date}}  
> **Input**: spec.md, plan.md

---

## Task Format

```
[ID] [P?] [Story] Description
```

| 标记 | 含义 |
|------|------|
| `T001` | 任务 ID |
| `[P]` | 可并行执行（不同文件，无依赖） |
| `[US1]` | 关联 User Story 1 |

---

## Task Overview

| ID | Task | Story | Status | Parallel | Est. Lines |
|----|------|-------|--------|----------|------------|
| T001 | 项目基础设置 | Setup | ⏸️ | - | - |
| T002 | API 文件定义 | US1 | ⏸️ | - | 30 |
| T003 | DDL 文件定义 | US1 | ⏸️ | [P] | 20 |
| T004 | goctl 生成代码 | US1 | ⏸️ | - | - |
| T005 | Model 层实现 | US1 | ⏸️ | - | 50 |
| T006 | Logic 层实现 | US1 | ⏸️ | - | 50 |
| T007 | 单元测试 | US1 | ⏸️ | - | 40 |

---

## Phase 1: Setup

**目的**: 项目初始化和基础配置

- [ ] T001 确认 Go-Zero 项目结构已就绪
- [ ] T002 [P] 确认 goctl 工具已安装

**Checkpoint**: ✅ 开发环境就绪

---

## Phase 2: Foundation (Go-Zero 基础)

**目的**: 必须完成后才能开始 User Story 实现

- [ ] T003 确认 base.api 已定义通用类型
- [ ] T004 确认 ServiceContext 已配置
- [ ] T005 [P] 确认数据库连接已配置

**Checkpoint**: ✅ 基础设施就绪，可开始 User Story 实现

---

## Phase 3: User Story 1 - [标题] (P1) 🎯 MVP

**目标**: [简述此 Story 交付什么]

**独立测试**: [如何验证此 Story 已完成]

### Step 1: 定义 API 文件

- [ ] T006 [US1] 创建 `api/doc/{module}/{feature}.api`
- [ ] T007 [US1] 定义 Request/Response 类型
- [ ] T008 [US1] 在 `api/doc/api.api` 入口文件中 import 新模块

### Step 2: 生成代码

- [ ] T009 [US1] 运行 `goctl api go` 生成 Handler/Types
  ```bash
  goctl api go -api api/doc/api.api -dir api/ --style=go_zero --type-group
  ```

- [ ] T010 [US1] 运行 `goctl api swagger` 生成 Swagger 文档
  ```bash
  make swagger
  # 或直接使用命令：
  goctl api swagger --api api/doc/api.api --dir api/swagger --filename api
  ```

### Step 3: 定义 DDL

- [ ] T010 [P] [US1] 创建 `migrations/{module}/{table}.sql`

### Step 4: 实现 Model 层

- [ ] T011 [US1] 创建 `model/{module}/{feature}/interface.go`
- [ ] T012 [P] [US1] 创建 `model/{module}/{feature}/types.go`
- [ ] T013 [P] [US1] 创建 `model/{module}/{feature}/vars.go`
- [ ] T014 [US1] 实现 `model/{module}/{feature}/gorm_dao.go`

### Step 5: 实现 Logic 层

- [ ] T015 [US1] 实现 `api/internal/logic/{module}/create_{feature}_logic.go`
- [ ] T016 [P] [US1] 实现 `api/internal/logic/{module}/get_{feature}_logic.go`
- [ ] T017 [P] [US1] 实现 `api/internal/logic/{module}/list_{feature}_logic.go`

### Step 6: 测试 (可选)

- [ ] T018 [US1] 单元测试 `model/{module}/{feature}/*_test.go`
- [ ] T019 [P] [US1] 单元测试 `api/internal/logic/{module}/*_test.go`

**Checkpoint**: ✅ User Story 1 可独立测试和验证

---

## Phase 4: User Story 2 - [标题] (P2)

<!-- 复杂功能添加更多 Story，简单功能省略 -->

**目标**: [简述此 Story 交付什么]

**独立测试**: [如何验证此 Story 已完成]

### Implementation

- [ ] T020 [US2] ...
- [ ] T021 [P] [US2] ...

**Checkpoint**: ✅ User Story 2 可独立测试和验证

---

## Phase N: Polish

**目的**: 收尾工作

- [ ] TXXX 代码清理和格式化
- [ ] TXXX 补充注释
- [ ] TXXX 运行 `golangci-lint run`
- [ ] TXXX 确认测试覆盖率 > 80%

---

## Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundation)
    ↓
Phase 3 (US1) → Phase 4 (US2) → ...  # 可并行或顺序
    ↓
Phase N (Polish)
```

### 并行执行说明

- `[P]` 标记的任务可与同 Phase 内其他 `[P]` 任务并行
- 不同 User Story 可并行（如有团队协作）
- 同一 User Story 内按 Step 顺序执行

---

## Notes

- 每个 Task 完成后提交代码
- 每个 Checkpoint 进行验证
- 遇到问题及时记录到 Open Questions

# SDD 工作流程详解

> **Spec-Driven Development 5 阶段工作流**

---

## 工作流程概览

```
┌─────────────────────────────────────────────────────────────┐
│                    SDD 5 阶段工作流                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 0: Context     ──► 理解规范，准备环境                  │
│           ⚠️ STOP - 等待用户确认                             │
│                                                             │
│  Phase 1: Specify     ──► 定义业务需求 (EARS 格式)            │
│           ⚠️ STOP - 等待用户确认                             │
│                                                             │
│  Phase 2: Design      ──► 创建技术方案                       │
│           ⚠️ STOP - 等待用户确认                             │
│                                                             │
│  Phase 3: Tasks       ──► 拆分任务 (<50行)                   │
│           ⚠️ STOP - 等待用户确认                             │
│                                                             │
│  Phase 4: Implement   ──► 编码、测试、验证                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 0: Context (上下文理解)

### 目的
确保 AI 理解项目规范和开发约束。

### 操作
1. AI 读取 `.specify/memory/constitution.md` (项目宪法)
2. 理解技术栈、架构模式、编码规范
3. 准备开发环境

### 输出
- 环境就绪确认

---

## Phase 1: Specify (需求规格)

### 命令
```bash
/speckit.specify "实现用户登录功能，支持手机号+密码登录"
```

### 目的
将自然语言需求转化为结构化规格说明。

### EARS 格式
IDRM 使用 EARS (Easy Approach to Requirements Syntax) 格式：

| 格式 | 说明 | 示例 |
|------|------|------|
| WHEN [trigger] | 触发条件 | WHEN 用户提交登录表单 |
| THE SYSTEM SHALL [action] | 系统行为 | THE SYSTEM SHALL 验证用户凭证 |

### 输出文件
`specs/<feature>/spec.md` 包含：
- **User Stories** - 用户故事 (P1/P2/P3)
- **Acceptance Criteria** - 验收标准 (EARS 格式)
- **Edge Cases** - 边界情况
- **Business Rules** - 业务规则
- **Data Considerations** - 数据考量

### 示例
```markdown
## User Stories

### Story 1: 用户登录 (P1)

AS a 注册用户
I WANT 使用手机号和密码登录
SO THAT 访问系统功能

**独立测试**: 登录成功后跳转到首页

## Acceptance Criteria (EARS)

### 正常流程

| ID | Scenario | Trigger | Expected Behavior |
|----|----------|---------|-------------------|
| AC-01 | 登录成功 | WHEN 用户提交正确凭证 | THE SYSTEM SHALL 返回 token 和用户信息 |
```

---

## Phase 2: Design (技术设计)

### 命令
```bash
/speckit.plan
```

### 目的
创建技术实现方案。

### 输出文件
`specs/<feature>/plan.md` 包含：
- **技术上下文** - 语言、框架、数据库
- **API 设计** - 接口定义
- **数据模型** - 表结构设计
- **分层架构** - Handler → Logic → Model

### Go-Zero 分层架构
```
┌──────────────────────────────────────────┐
│  Handler 层                              │
│  - 参数绑定与校验                         │
│  - 调用 Logic                            │
│  - 响应格式化                             │
├──────────────────────────────────────────┤
│  Logic 层                                │
│  - 业务逻辑                               │
│  - 事务管理                               │
│  - 调用 Model                            │
├──────────────────────────────────────────┤
│  Model 层                                │
│  - GORM 复杂查询                          │
│  - SQLx 简单 CRUD                        │
│  - 数据访问封装                           │
└──────────────────────────────────────────┘
```

---

## Phase 3: Tasks (任务拆分)

### 命令
```bash
/speckit.tasks
```

### 目的
将设计方案拆分为可执行的小任务。

### 任务规则
- 每个任务 < 50 行代码
- 任务必须可独立测试
- 遵循依赖顺序

### 输出文件
`specs/<feature>/tasks.md` 包含分阶段任务：

```markdown
## Phase 1: Setup (环境准备)
- [ ] TASK-001: 创建 API 定义文件

## Phase 2: Foundation (基础设施)
- [ ] TASK-002: 创建 DDL 并执行迁移
- [ ] TASK-003: 生成 Model 代码

## Phase 3: User Stories (功能实现)
- [ ] TASK-004: 实现登录 Handler
- [ ] TASK-005: 实现登录 Logic

## Phase 4: Polish (完善)
- [ ] TASK-006: 添加单元测试
```

---

## Phase 4: Implement (实现)

### 命令
```bash
/speckit.implement
```

### 目的
按任务顺序编码实现。

### 执行流程
1. 读取 `tasks.md`
2. 按顺序执行每个任务
3. 完成后标记 `[x]`
4. 运行测试验证

### Go-Zero 实现步骤
```bash
# 1. 定义 API
vim api/doc/user/login.api

# 2. 生成代码
make api

# 3. 编写 DDL
vim migrations/001_create_user.sql

# 4. 生成 Model
goctl model mysql ddl ...

# 5. 实现 Logic
vim api/internal/logic/user/loginlogic.go

# 6. 测试
make test
```

---

## 可选命令

### /speckit.clarify
在 Phase 2 之前使用，解决规格中的模糊点。

```bash
/speckit.clarify
```

### /speckit.analyze
在 Phase 4 之前使用，检查跨文档一致性。

```bash
/speckit.analyze
```

### /speckit.checklist
在 Phase 2 之后使用，生成质量检查清单。

```bash
/speckit.checklist
```

---

## 最佳实践

### 1. 每个阶段后等待确认
不要跳过 STOP 点，让用户审阅并确认。

### 2. 保持 Story 独立可测试
每个 User Story 应该可以独立交付和测试。

### 3. 任务粒度要小
任务越小，越容易验证和回滚。

### 4. 遵循分层原则
Handler 不包含业务逻辑，Logic 不直接操作 HTTP。

---

## 下一步

- [模板使用指南](templates-guide.md)
- [部署指南](deployment.md)

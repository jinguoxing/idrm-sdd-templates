# 模板使用指南

> **如何使用 IDRM SDD 模板编写高质量规格**

---

## 概述

IDRM SDD Templates 提供了一套标准化的模板，帮助你在 Spec-Driven Development 流程中编写清晰、可验证的规格文档。

---

## spec-template.md 使用指南

### 何时使用
使用 `/speckit.specify` 命令时自动生成。

### 填写要点

#### 1. User Stories

**格式**:
```markdown
AS a [角色]
I WANT [功能]
SO THAT [价值/目标]

**独立测试**: [如何验证此 Story 已完成]
```

**优先级说明**:
| 优先级 | 说明 |
|--------|------|
| P1 | 核心功能，必须实现 |
| P2 | 重要功能，建议实现 |
| P3 | 增强功能，可选实现 |

**示例**:
```markdown
### Story 1: 用户登录 (P1)

AS a 注册用户
I WANT 使用手机号和密码登录系统
SO THAT 访问个人数据和功能

**独立测试**: 使用正确的手机号和密码登录后，可以访问用户首页
```

#### 2. Acceptance Criteria (EARS)

EARS = Easy Approach to Requirements Syntax

**正常流程表格**:
```markdown
| ID | Scenario | Trigger | Expected Behavior |
|----|----------|---------|-------------------|
| AC-01 | 登录成功 | WHEN 用户提交正确凭证 | THE SYSTEM SHALL 返回 token 和用户信息 |
| AC-02 | 记住登录 | WHEN 用户勾选"记住我" | THE SYSTEM SHALL 延长 token 有效期至 7 天 |
```

**异常处理表格**:
```markdown
| ID | Scenario | Trigger | Expected Behavior |
|----|----------|---------|-------------------|
| AC-10 | 密码错误 | WHEN 密码不匹配 | THE SYSTEM SHALL 返回 401 错误 |
| AC-11 | 账户锁定 | WHEN 连续 5 次失败 | THE SYSTEM SHALL 锁定账户 30 分钟 |
```

#### 3. Edge Cases

```markdown
| ID | Case | Expected Behavior |
|----|------|-------------------|
| EC-01 | 并发登录同一账户 | 允许多设备登录，返回独立 token |
| EC-02 | token 过期后操作 | 返回 401，客户端刷新 token |
```

#### 4. Business Rules

```markdown
| ID | Rule | Description |
|----|------|-------------|
| BR-01 | 密码强度 | 至少 8 位，包含字母和数字 |
| BR-02 | 登录限制 | 同一 IP 每分钟最多 10 次 |
```

---

## plan-template.md 使用指南

### 何时使用
使用 `/speckit.plan` 命令时自动生成。

### 填写要点

#### 1. Technical Context

明确技术选型：
```markdown
| 项目 | 选择 |
|------|------|
| 语言 | Go 1.21+ |
| 框架 | Go-Zero v1.9+ |
| 数据库 | MySQL 8.0 |
| ORM | GORM + SQLx |
```

#### 2. API 设计

使用 `.api` 格式定义接口：
```api
type (
    LoginReq {
        Phone    string `json:"phone" validate:"required,len=11"`
        Password string `json:"password" validate:"required,min=8"`
    }
    
    LoginResp {
        Token    string `json:"token"`
        UserId   int64  `json:"user_id"`
        Nickname string `json:"nickname"`
    }
)

@server (
    prefix: /api/v1
    group:  user
)
service api {
    @doc "用户登录"
    @handler Login
    post /user/login (LoginReq) returns (LoginResp)
}
```

#### 3. 数据模型

使用 DDL 定义表结构：
```sql
CREATE TABLE IF NOT EXISTS `user` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `phone`       VARCHAR(20) NOT NULL COMMENT '手机号',
    `password`    VARCHAR(255) NOT NULL COMMENT '密码哈希',
    `nickname`    VARCHAR(50) DEFAULT '' COMMENT '昵称',
    `status`      TINYINT DEFAULT 1 COMMENT '状态: 1=正常 0=禁用',
    `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

---

## tasks-template.md 使用指南

### 何时使用
使用 `/speckit.tasks` 命令时自动生成。

### 任务拆分原则

1. **粒度原则**: 每个任务 < 50 行代码
2. **独立原则**: 每个任务可独立测试
3. **依赖原则**: 遵循依赖顺序执行

### 任务格式

```markdown
- [ ] TASK-001: 创建用户登录 API 定义
  - **目标**: 定义登录接口的请求和响应结构
  - **文件**: `api/doc/user/login.api`
  - **依赖**: 无
  - **验证**: API 文件语法正确，可被 goctl 解析
```

### Phase 划分

```markdown
## Phase 1: Setup (环境准备)
创建目录、配置文件等

## Phase 2: Foundation (基础设施)
DDL、Model 生成、基础组件

## Phase 3: User Stories (功能实现)
按 User Story 实现具体功能

## Phase 4: Polish (完善)
测试、文档、优化
```

---

## api-template.api 使用指南

### 文件组织

```
api/doc/
├── api.api         # 入口文件
├── base.api        # 基础类型
└── user/
    ├── login.api   # 登录相关
    └── profile.api # 个人信息相关
```

### 模块化原则

1. 入口文件 `api.api` 只做 import
2. 每个业务模块一个子目录
3. 基础类型放在 `base.api`

### 生成代码

```bash
make api
# 或
goctl api go -api api/doc/api.api -dir api/
```

---

## schema-template.sql 使用指南

### DDL 规范

```sql
-- 表名: 小写下划线
-- 字段: 小写下划线
-- 索引: uk_ (唯一), idx_ (普通)

CREATE TABLE IF NOT EXISTS `table_name` (
    -- 主键
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    
    -- 业务字段
    `field_name` TYPE CONSTRAINTS COMMENT '字段说明',
    
    -- 时间字段
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` DATETIME DEFAULT NULL,
    
    -- 索引
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_xxx` (`xxx`),
    KEY `idx_xxx` (`xxx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='表注释';
```

---

## 最佳实践

### 1. 保持简洁
- 一个 Story 一个核心功能
- 一个 AC 一个验证点

### 2. 可验证性
- 每个 AC 必须可测试
- 避免模糊描述

### 3. 一致性
- 用语统一
- 格式统一

### 4. 完整性
- 覆盖正常和异常流程
- 考虑边界情况

---

## 下一步

- [SDD 工作流程](workflow.md)
- [部署指南](deployment.md)

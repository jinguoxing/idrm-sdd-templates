# IDRM SDD Templates

> **Spec-Driven Development Templates for Go-Zero Projects**

[![Version](https://img.shields.io/badge/version-0.9.0-blue.svg)](https://github.com/jinguoxing/idrm-sdd-templates)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[中文](./README.md) | **English**

---

## 📖 Introduction

IDRM SDD Templates is a set of customized templates based on [Spec Kit](https://github.com/anthropics/speckit), designed specifically for **Go-Zero Microservice Projects**.

### Features

- 🎯 **EARS Format Specs** - Clear, testable requirement expressions
- 🏗️ **Go-Zero Layered Arch** - Handler → Logic → Model
- 🔄 **Dual ORM Support** - Flexible switching between GORM and SQLx
- 📦 **Multi-Service Types** - API / RPC / Job / Consumer
- 🤖 **Comprehensive AI Integration** - Supports Cursor, Claude Code, GitHub Copilot, Gemini
- 🔄 **Incremental Updates** - Safely add new services (e.g., adding RPC) to existing projects
- 🛡️ **Safe Upgrades** - Upgrade scripts automatically backup config files to protect custom prompts
- 📋 **Quality Gates** - Built-in checklists and constitutional constraints
- 🎭 **Scenario-based Workflows** - 4 intelligent scenarios (New Feature / Quick Fix / Extension / Refactor)
- 📝 **Delta Format** - Change tracking (ADDED/MODIFIED/REMOVED)

---

## 🚀 Quick Start

### Prerequisites

- [Go](https://golang.org/) >= 1.24
- [goctl](https://go-zero.dev/docs/goctl/goctl) (Go-Zero CLI)
- [uv](https://github.com/astral-sh/uv) (Python Package Manager)

### Installation

```bash
# Step 1: Install Spec Kit CLI
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

```bash
# Step 2: Initialize using Spec Kit (Choose Cursor or Claude)
specify init . --ai cursor-agent --force
```

Or

```bash
specify init . --ai claude --force
```

```bash
# Step 3: Install IDRM SDD Templates
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
```

### Interactive Installation

To select service types and configure the database, **download the script first**:

```bash
# Download script
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh -o /tmp/sdd-install.sh

# Run interactively
bash /tmp/sdd-install.sh
```

The installation script will guide you through:

1. **Select Service Types** - API / RPC / Job / Consumer (Multiple selection allowed)
2. **Configure Project Info** - Project Name, Go Module Path
3. **Configure Database** - MySQL connection info
4. **Confirm and Install**

### Non-Interactive Installation (CI/CD)

Running via pipe automatically triggers non-interactive mode:

```bash
# Install templates only, using default configuration
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-install.sh | bash
```

> 💡 **Tip**: If running the install script in an initialized project, it will detect and prompt for **Incremental Installation**, allowing you to safely add new services (like Job/Consumer) without overwriting existing code.

---

## 📁 Directory Structure

```
my-project/
├── .specify/                    # SDD Config
│   ├── templates/               # IDRM Custom Templates
│   │   ├── spec-template.md     # Requirement Spec Template (EARS)
│   │   ├── plan-template.md     # Technical Plan Template
│   │   ├── tasks-template.md    # Task Template
│   │   ├── api-template.api     # Go-Zero API Template
│   │   └── schema-template.sql  # DDL Template
│   ├── workflows/               # Scenario Workflows [NEW]
│   │   ├── README.md            # Scenario Decision Tree
│   │   ├── scenario-1-new.md    # New Feature (5 Phases)
│   │   ├── scenario-2-update.md # Quick Fix (4 Steps)
│   │   ├── scenario-3-extend.md # Extension (Delta Format)
│   │   └── scenario-4-refactor.md # Refactor
│   └── memory/
│       └── constitution.md      # IDRM Project Constitution
│
├── .cursor/commands/            # Cursor Commands
│   ├── speckit.start.md         # Intelligent Scenario Start [NEW]
│   └── speckit.*.md             # Official Commands
├── .claude/commands/            # Claude Commands
│   ├── speckit.start.md         # Intelligent Scenario Start [NEW]
│   └── speckit.*.md             # Official Commands
├── .github/copilot-instructions.md # Copilot Instructions [NEW]
├── GEMINI.md                    # Gemini Context [NEW]
├── api/                         # API Service
│   ├── doc/
│   │   ├── api.api              # API Entry
│   │   └── base.api             # Base Types
│   └── etc/
│       └── api.yaml             # Config File
├── rpc/                         # RPC Service (Optional)
├── job/                         # Job Service (Optional)
├── consumer/                    # Consumer Service (Optional)
├── model/                       # Model Layer
├── migrations/                  # DDL Migrations
├── Makefile                     # Common Commands
└── go.mod
```

---

## 🔧 Common Commands

```bash
# Generate API Code
make api

# Generate Swagger Docs
make swagger

# One-click Generate API + Swagger
make gen

# Run Service
make run

# Code Linting
make lint

# Run Tests
make test

# Database Migration (golang-migrate)
make migrate-new MODULE=user NAME=init_table   # Create migration file
make migrate-up MODULE=user                    # Execute upgrade
make migrate-down MODULE=user                  # Execute rollback
make migrate-status MODULE=user                # Check status
```

---

## 📝 Development Workflow

### Scenario-based Intelligent Commands (v0.4.0+)

Use the `/speckit.start` command, and AI will automatically determine and match the appropriate development scenario:

```bash
# Input in Cursor or Claude Code:
/speckit.start Implement user auth feature      # → Scenario 1: New Feature
/speckit.start Fix login timeout issue          # → Scenario 2: Quick Fix
/speckit.start Add password reset function      # → Scenario 3: Extension
/speckit.start Change JWT to OAuth2             # → Scenario 4: Refactor
```

### 4 Development Scenarios

| Scenario | Condition | Workflow |
|----------|-----------|----------|
| 🆕 New Feature | specs/{feature}/ missing | 5-Phase Full Process |
| 🔧 Quick Fix | Existing spec, <50 lines | 4-Step Rapid Process |
| ➕ Extension | Adding sub-feature | Incremental + Delta Format |
| 🔄 Refactor | Breaking changes | 6-Step Migration Process |

### Traditional Commands (Still Available)

```bash
/speckit.specify   # Define Requirements
/speckit.plan      # Create Technical Plan
/speckit.tasks     # Generate Task List
/speckit.implement # Start Implementation
```

---

## 🔄 Upgrade

```bash
# Check for Updates
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh -o /tmp/sdd-upgrade.sh
bash /tmp/sdd-upgrade.sh --check

# Execute Upgrade (Auto-backups .cursorrules etc.)
curl -sSL https://raw.githubusercontent.com/jinguoxing/idrm-sdd-templates/main/scripts/sdd-upgrade.sh -o /tmp/sdd-upgrade.sh
bash /tmp/sdd-upgrade.sh
```

---

## 📚 Documentation

- [Scenario Workflows](.specify/workflows/README.md) - Decision Tree for 4 Developmental Scenarios
- [Project Constitution](memory/constitution.md) - IDRM Project Core Constraints
- [Template Guide](templates/README.md) - User Guide for Templates
- [Go-Zero Guide](go-zero/README.md) - Go-Zero Development Guide

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

[MIT License](LICENSE)

---

## 🔗 Related Links

- [GitHub Spec Kit](https://github.com/github/spec-kit) - Official Spec Kit
- [Go-Zero](https://go-zero.dev/) - Go-Zero Framework
- [IDRM Project](https://github.com/jinguoxing) - IDRM Series Projects

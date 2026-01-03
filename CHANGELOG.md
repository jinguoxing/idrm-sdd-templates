# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-01-03

### Added

- 新增 `.cursorrules` 模板 (Cursor AI 规则配置)
  - 项目架构规范
  - SDD 工作流程说明
  - 编码规范和约束
  - API/数据库设计规范
- 新增 `CLAUDE.md` 模板 (Claude Code 配置)
  - 项目概览和技术栈
  - 快速命令说明
  - 常见操作指南
- Go 版本升级到 1.24
- 完善 P1/P2 文档
  - `docs/quick-start.md` - 快速开始
  - `docs/installation.md` - 安装说明
  - `docs/workflow.md` - 工作流程
  - `docs/deployment.md` - 部署指南
  - `docs/templates-guide.md` - 模板使用指南
  - `templates/README.md` - 模板总览
  - `go-zero/README.md` - Go-Zero 项目说明

### Fixed

- 修复 `compare_versions` 函数 zsh 兼容性问题
- 修复升级脚本 `set -e` 导致过早退出的问题
- 修复 `head -n -1` 在 macOS 不兼容问题
- 修复文档中 `bash -- --check` 命令错误 (改为 `bash -s -- --check`)
- 修复 README.md 过时的安装命令

---

## [0.2.0] - 2026-01-03

### Fixed

- 修复 Swagger 文档输出路径从 `api/swagger` 改为 `api/doc`
- 修复 API 服务初始化不再创建多余的 `api/swagger` 目录

### Added

- 新增 Docker 部署支持
  - `deploy/docker/Dockerfile` - 多阶段构建镜像
  - `deploy/docker/docker-compose.yaml` - Docker Compose 配置
- 新增 Kubernetes 部署支持
  - `deploy/k8s/deployment.yaml` - K8s Deployment 配置
  - `deploy/k8s/service.yaml` - K8s Service 配置
  - `deploy/k8s/configmap.yaml` - K8s ConfigMap 配置
- Makefile 新增命令:
  - `make docker-build` - 构建 Docker 镜像
  - `make docker-run` - 运行 Docker 容器
  - `make docker-push` - 推送 Docker 镜像
  - `make k8s-deploy` - 部署到 Kubernetes
  - `make k8s-delete` - 删除 Kubernetes 部署
  - `make k8s-status` - 查看 Kubernetes 状态

---

## [0.1.0] - 2026-01-03

### Added

- 初始版本发布
- SDD 模板文件 (spec, plan, tasks, checklist, agent-file)
- Go-Zero API 模板 (api-template.api)
- DDL 模板 (schema-template.sql)
- IDRM 项目宪法 (constitution.md)
- Go-Zero 项目初始化模板
  - API 服务模板
  - RPC 服务模板
  - Job 服务模板
  - Consumer 服务模板
- 一键安装脚本 (sdd-install.sh)
- 升级脚本 (sdd-upgrade.sh)
- 版本管理机制 (.sdd-version)

### Features

- 支持 Cursor 和 Claude Code 两种 AI 工具
- 交互式安装流程
- 多服务类型选择 (API/RPC/Job/Consumer)
- 自动配置数据库连接
- Makefile 常用命令集成

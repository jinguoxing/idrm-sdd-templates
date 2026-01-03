# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

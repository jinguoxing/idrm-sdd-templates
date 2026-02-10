.PHONY: init api swagger swagger-yaml gen fmt lint test build run clean deps migrate-up migrate-down migrate-status migrate-version migrate-force migrate-create install-migrate-tool docker-build docker-run docker-stop docker-push k8s-deploy k8s-deploy-dev k8s-deploy-prod k8s-manifest k8s-delete k8s-status help

# 项目名称
PROJECT_NAME := {{PROJECT_NAME}}

# Docker 配置
DOCKER_REGISTRY := {{DOCKER_REGISTRY}}
DOCKER_IMAGE := $(DOCKER_REGISTRY)/$(PROJECT_NAME)
VERSION := $(shell cat VERSION 2>/dev/null || echo "0.1.0")

# Swagger 文档输出目录
SWAGGER_DIR := api/doc/swagger

# 数据库迁移（可通过环境变量覆盖）
DB_HOST ?= {{DB_HOST}}
DB_PORT ?= {{DB_PORT}}
DB_NAME ?= {{DB_NAME}}
DB_USER ?= {{DB_USER}}
DB_PASSWORD ?= {{DB_PASSWORD}}

# 迁移工具配置
MIGRATE := migrate
MIGRATIONS_DIR := migrations/versions
# 自动通过 migrations/versions 下的子目录识别模块
MODULES := $(shell ls $(MIGRATIONS_DIR) 2>/dev/null || echo "")
DB_URL := "mysql://$(DB_USER):$(DB_PASSWORD)@tcp($(DB_HOST):$(DB_PORT))/$(DB_NAME)?multiStatements=true"

# 初始化项目
init:
	@./scripts/init.sh

# 生成 API 代码
api:
	goctl api go -api api/doc/api.api -dir api/ --style=go_zero --type-group

# 生成 Swagger 文档 (JSON 格式)
swagger:
	goctl api swagger --api api/doc/api.api --dir $(SWAGGER_DIR) --filename swagger

# 生成 Swagger 文档 (YAML 格式)
swagger-yaml:
	goctl api swagger --api api/doc/api.api --dir $(SWAGGER_DIR) --filename swagger --yaml

# 一键生成 API 代码 + Swagger 文档
gen: api swagger
	@echo "API code and Swagger documentation generated successfully!"

# 格式化代码
fmt:
	gofmt -w .
	goimports -w .

# 代码检查
lint:
	golangci-lint run ./...

# 运行测试
test:
	go test -v -cover ./...

# 编译
build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/$(PROJECT_NAME) ./api/api.go

# 运行
run:
	go run api/api.go

# 清理
clean:
	rm -rf bin/
	go clean

# 安装依赖
deps:
	go mod tidy
	go mod download

# ============================================
# Database Migration Commands
# ============================================

# 执行所有模块的迁移
migrate-up:
	@if [ -z "$(DB_PASSWORD)" ]; then echo "❌ 请设置 DB_PASSWORD，例如: export DB_PASSWORD=xxx && make migrate-up"; exit 1; fi
	@echo "🔽 执行数据库迁移..."
	@if [ -z "$(MODULES)" ]; then \
		echo "⚠️  未发现任何模块迁移目录 (在 migrations/versions/ 下)"; \
	else \
		for module in $(MODULES); do \
			echo ""; \
			echo "📦 模块: $$module"; \
			echo "────────────────────────────────────"; \
			$(MIGRATE) -path $(MIGRATIONS_DIR)/$$module -database $(DB_URL) up || exit 1; \
			echo "✅ $$module 迁移成功"; \
		done; \
	fi
	@echo ""
	@echo "🎉 所有模块迁移检查完成！"

# 回滚所有模块的最后一次迁移
migrate-down:
	@if [ -z "$(DB_PASSWORD)" ]; then echo "❌ 请设置 DB_PASSWORD"; exit 1; fi
	@echo "🔽 回滚数据库迁移..."
	@if [ -z "$(MODULES)" ]; then \
		echo "⚠️  未发现任何模块迁移目录"; \
	else \
		for module in $(MODULES); do \
			echo ""; \
			echo "📦 模块: $$module"; \
			echo "────────────────────────────────────"; \
			$(MIGRATE) -path $(MIGRATIONS_DIR)/$$module -database $(DB_URL) down 1 || exit 1; \
			echo "✅ $$module 回滚成功"; \
		done; \
	fi
	@echo ""
	@echo "🎉 所有模块回滚检查完成！"

# 查看所有模块的迁移状态
migrate-status:
	@echo "📊 查看迁移状态..."
	@echo ""
	@if [ -z "$(MODULES)" ]; then \
		echo "⚠️  未发现任何模块迁移目录"; \
	else \
		for module in $(MODULES); do \
			echo "📦 模块: $$module"; \
			echo "────────────────────────────────────"; \
			$(MIGRATE) -path $(MIGRATIONS_DIR)/$$module -database $(DB_URL) version 2>&1 || echo "  ⚠️  未执行任何迁移"; \
			echo ""; \
		done; \
	fi

# 查看当前迁移版本（指定模块）
migrate-version:
	@if [ -z "$(MODULE)" ]; then \
		echo "❌ 错误: 请指定模块名 (make migrate-version MODULE=xxx)"; \
		exit 1; \
	fi
	@$(MIGRATE) -path $(MIGRATIONS_DIR)/$(MODULE) -database $(DB_URL) version

# 强制设置迁移版本（修复脏状态）
migrate-force:
	@if [ -z "$(DB_PASSWORD)" ]; then echo "❌ 请设置 DB_PASSWORD"; exit 1; fi
	@if [ -z "$(MODULE)" ]; then \
		echo "❌ 错误: 请指定模块名 (make migrate-force MODULE=xxx VERSION=n)"; \
		exit 1; \
	fi
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ 错误: 请指定 VERSION"; \
		exit 1; \
	fi
	@echo "⚠️  强制设置模块 $(MODULE) 迁移版本为 $(VERSION)..."
	@$(MIGRATE) -path $(MIGRATIONS_DIR)/$(MODULE) -database $(DB_URL) force $(VERSION)
	@echo "✅ 已设为版本 $(VERSION)"

# 创建新的迁移文件
migrate-create:
	@if [ -z "$(MODULE)" ]; then \
		echo "❌ 错误: 请指定模块名"; \
		echo "用法: make migrate-create MODULE=user NAME=add_field"; \
		exit 1; \
	fi
	@if [ -z "$(NAME)" ]; then \
		echo "❌ 错误: 请指定迁移名称"; \
		echo "用法: make migrate-create MODULE=user NAME=add_field"; \
		exit 1; \
	fi
	@echo "📝 创建新的迁移文件..."
	@mkdir -p $(MIGRATIONS_DIR)/$(MODULE)
	@$(MIGRATE) create -ext sql -dir $(MIGRATIONS_DIR)/$(MODULE) -seq $(NAME)
	@echo "✅ 迁移文件已创建在 $(MIGRATIONS_DIR)/$(MODULE)/"

# 安装 golang-migrate 工具
install-migrate-tool:
	@echo "📦 安装 golang-migrate 工具..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "使用 Homebrew 安装..."; \
		brew install golang-migrate; \
	else \
		echo "❌ 未找到 Homebrew"; \
		echo "请手动安装: https://github.com/golang-migrate/migrate"; \
		exit 1; \
	fi
	@echo "✅ 安装完成"
	@$(MIGRATE) -version

# ============================================
# Docker 命令
# ============================================

# 构建 Docker 镜像
docker-build:
	@./deploy/docker/build.sh $(VERSION)

# 运行 Docker 容器
docker-run:
	docker run -d --name $(PROJECT_NAME) -p 8888:8888 $(DOCKER_IMAGE):$(VERSION)

# 停止 Docker 容器
docker-stop:
	docker stop $(PROJECT_NAME) && docker rm $(PROJECT_NAME)

# 推送 Docker 镜像
docker-push:
	docker push $(DOCKER_IMAGE):$(VERSION)
	docker push $(DOCKER_IMAGE):latest

# ============================================
# Kubernetes 命令
# ============================================

# 部署环境
ENV ?= dev

# 部署到 K8s (默认 dev)
k8s-deploy:
	kubectl apply -k deploy/k8s/overlays/$(ENV)

# 部署到 K8s (Dev)
k8s-deploy-dev:
	kubectl apply -k deploy/k8s/overlays/dev

# 部署到 K8s (Prod)
k8s-deploy-prod:
	kubectl apply -k deploy/k8s/overlays/prod

# 查看 K8s 生成的 Manifest (Dry-run)
k8s-manifest:
	kubectl kustomize deploy/k8s/overlays/$(ENV)

# 删除 K8s 部署
k8s-delete:
	kubectl delete -k deploy/k8s/overlays/$(ENV)

# 查看 K8s 状态
k8s-status:
	kubectl get pods,svc,deploy,ing -l app=$(PROJECT_NAME)

# 帮助
help:
	@echo "Available commands:"
	@echo ""
	@echo "  Development:"
	@echo "    make init          - Initialize project"
	@echo "    make gen           - Generate API code + Swagger docs"
	@echo "    make fmt           - Format code"
	@echo "    make lint          - Run linter"
	@echo "    make test          - Run tests"
	@echo "    make run           - Run server"
	@echo "    make deps          - Install dependencies"
	@echo ""
	@echo "  Database Migrations:"
	@echo "    make migrate-up      - Run all pending migrations"
	@echo "    make migrate-down    - Rollback last migration"
	@echo "    make migrate-status  - Show migration status"
	@echo "    make migrate-create MODULE=<mod> NAME=<name> - Create migration"
	@echo "    make migrate-force MODULE=<mod> VERSION=<n>  - Force set version"
	@echo ""
	@echo "  Docker & K8s:"
	@echo "    make docker-build  - Build Docker image"
	@echo "    make docker-push   - Push Docker image"
	@echo "    make k8s-deploy    - Deploy to K8s"
	@echo "    make k8s-status    - Check K8s status"
	@echo ""

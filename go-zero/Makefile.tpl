.PHONY: init api swagger swagger-yaml gen lint test build clean

# 项目名称
PROJECT_NAME := {{PROJECT_NAME}}

# Swagger 文档输出目录
SWAGGER_DIR := api/swagger

# 初始化项目
init:
	@./scripts/init.sh

# 生成 API 代码
api:
	goctl api go -api api/doc/api.api -dir api/ --style=go_zero --type-group

# 生成 Swagger 文档 (JSON 格式)
swagger:
	@mkdir -p $(SWAGGER_DIR)
	goctl api swagger --api api/doc/api.api --dir $(SWAGGER_DIR) --filename api

# 生成 Swagger 文档 (YAML 格式)
swagger-yaml:
	@mkdir -p $(SWAGGER_DIR)
	goctl api swagger --api api/doc/api.api --dir $(SWAGGER_DIR) --filename api --yaml

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
	go build -o bin/$(PROJECT_NAME) ./api/api.go

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

# 帮助
help:
	@echo "Available commands:"
	@echo "  make init        - Initialize project"
	@echo "  make api         - Generate API code with goctl"
	@echo "  make swagger     - Generate Swagger JSON documentation"
	@echo "  make swagger-yaml - Generate Swagger YAML documentation"
	@echo "  make gen         - Generate API code + Swagger docs"
	@echo "  make fmt         - Format code"
	@echo "  make lint        - Run linter"
	@echo "  make test        - Run tests"
	@echo "  make build       - Build binary"
	@echo "  make run         - Run server"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make deps        - Install dependencies"

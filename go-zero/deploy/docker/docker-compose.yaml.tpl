version: '3.8'

services:
  api:
    build:
      context: ../..
      dockerfile: deploy/docker/Dockerfile
    container_name: {{PROJECT_NAME}}-api
    ports:
      - "${API_PORT:-8888}:8888"
    environment:
      - TZ=Asia/Shanghai
      - ENVIRONMENT=${ENVIRONMENT:-dev}
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - LOG_MODE=console
      # 数据库配置
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME={{DB_NAME}}
      - DB_USER=root
      - DB_PASSWORD=${DB_PASSWORD}
      # 认证配置
      - ACCESS_SECRET=${ACCESS_SECRET}
      - ACCESS_EXPIRE=${ACCESS_EXPIRE:-7200}
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    networks:
      - {{PROJECT_NAME}}-network
    depends_on:
      - mysql

  mysql:
    image: mysql:8.0
    container_name: {{PROJECT_NAME}}-mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
      - MYSQL_DATABASE={{DB_NAME}}
      - TZ=Asia/Shanghai
    volumes:
      - mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    restart: unless-stopped
    networks:
      - {{PROJECT_NAME}}-network

  # Redis (可选)
  redis:
    image: redis:7-alpine
    container_name: {{PROJECT_NAME}}-redis
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    restart: unless-stopped
    networks:
      - {{PROJECT_NAME}}-network
    profiles:
      - with-redis

networks:
  {{PROJECT_NAME}}-network:
    driver: bridge

volumes:
  mysql-data:
  redis-data:

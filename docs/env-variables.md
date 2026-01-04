# 环境变量配置指南

> **IDRM SDD Templates 环境变量参考**

---

## 配置原则

| 类型 | 存储位置 | 示例 |
|------|----------|------|
| **敏感信息** | 环境变量 / K8s Secret | 密码、密钥、Token |
| **运行时配置** | 环境变量 / K8s ConfigMap | Host、Port、环境标识 |
| **固定配置** | 配置文件 | 连接池参数、超时设置 |

---

## 环境变量列表

### 必填项 (敏感信息)

| 变量 | 说明 | 示例 |
|------|------|------|
| `DB_PASSWORD` | 数据库密码 | `your-db-password` |
| `ACCESS_SECRET` | JWT 签名密钥 | `your-jwt-secret` |

### 数据库配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DB_HOST` | `localhost` | 数据库主机 |
| `DB_PORT` | `3306` | 数据库端口 |
| `DB_NAME` | `idrm` | 数据库名 |
| `DB_USER` | `root` | 数据库用户 |
| `DB_MAX_IDLE_CONNS` | `10` | 最大空闲连接数 |
| `DB_MAX_OPEN_CONNS` | `100` | 最大连接数 |
| `DB_LOG_LEVEL` | `warn` | 数据库日志级别 |

### 服务配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `API_PORT` | `8888` | API 服务端口 |
| `RPC_PORT` | `9999` | RPC 服务端口 |
| `ENVIRONMENT` | `dev` | 运行环境 (dev/staging/production) |
| `SERVICE_VERSION` | `1.0.0` | 服务版本号 |

### 日志配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LOG_LEVEL` | `info` | 日志级别 (debug/info/warn/error) |
| `LOG_MODE` | `file` | 日志模式 (console/file) |

### 认证配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `ACCESS_SECRET` | - | JWT 签名密钥 (必填) |
| `ACCESS_EXPIRE` | `7200` | Token 过期时间 (秒) |

### 链路追踪

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TRACE_ENABLED` | `false` | 是否启用链路追踪 |
| `TRACE_ENDPOINT` | `localhost:4317` | OpenTelemetry 端点 |

### Redis 配置 (可选)

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `REDIS_HOST` | `localhost` | Redis 主机 |
| `REDIS_PORT` | `6379` | Redis 端口 |
| `REDIS_DB` | `0` | Redis 数据库 |
| `REDIS_PASSWORD` | - | Redis 密码 |

### 消息队列配置 (Consumer 服务)

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MQ_TYPE` | `kafka` | 消息队列类型 (kafka/redis) |
| `KAFKA_BROKERS` | `localhost:9092` | Kafka 集群地址 |
| `KAFKA_TOPIC` | `orders` | Kafka 主题 |
| `KAFKA_GROUP` | `consumer-group` | 消费者组 |

---

## 使用示例

### 本地开发 (Shell)

```bash
export DB_PASSWORD=root123
export ACCESS_SECRET=my-secret-key

make run
```

### Docker Compose

```bash
# 创建 .env 文件
cat > .env << EOF
DB_PASSWORD=root123
ACCESS_SECRET=my-secret-key
ENVIRONMENT=dev
EOF

# 启动服务
docker-compose up -d
```

### Kubernetes

```bash
# 创建 Secret
kubectl create secret generic my-project-secret \
  --from-literal=DB_PASSWORD=root123 \
  --from-literal=ACCESS_SECRET=my-secret-key

# 部署
kubectl apply -k deploy/k8s/overlays/dev
```

---

## 配置优先级

1. **环境变量** (最高优先级)
2. **配置文件**
3. **默认值**

Go-Zero 会自动读取 `${VAR:-default}` 格式的环境变量并替换。

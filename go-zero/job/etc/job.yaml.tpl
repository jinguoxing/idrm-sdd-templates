Name: {{PROJECT_NAME}}-job
Mode: ${LOG_MODE:-console}

# 日志配置
Log:
  ServiceName: {{PROJECT_NAME}}-job
  Mode: ${LOG_MODE:-console}
  Level: ${LOG_LEVEL:-info}

# 链路追踪
Telemetry:
  Name: {{PROJECT_NAME}}-job
  Endpoint: ${TRACE_ENDPOINT}
  Sampler: 1.0
  Batcher: jaeger

# 任务配置
Job:
  Name: ${JOB_NAME:-example-job}
  Timeout: ${JOB_TIMEOUT:-300}

# 数据库配置
DB:
  Default:
    Host: ${DB_HOST:-localhost}
    Port: ${DB_PORT:-3306}
    Database: ${DB_NAME:-idrm}
    Username: ${DB_USER:-root}
    Password: ${DB_PASSWORD}
    Charset: utf8mb4
    MaxIdleConns: ${DB_MAX_IDLE_CONNS:-10}
    MaxOpenConns: ${DB_MAX_OPEN_CONNS:-100}
    ConnMaxLifetime: 3600
    LogLevel: ${DB_LOG_LEVEL:-warn}
    SlowThreshold: 200

Name: {{PROJECT_NAME}}-job
Mode: console

# 日志配置
Log:
  ServiceName: {{PROJECT_NAME}}-job
  Mode: console
  Level: info

# 链路追踪
Telemetry:
  Name: {{PROJECT_NAME}}-job
  Endpoint: ""
  Sampler: 1.0
  Batcher: jaeger

# 任务配置
Job:
  Name: example-job
  Timeout: 300

# 数据库配置
DB:
  Default:
    Host: {{DB_HOST}}
    Port: {{DB_PORT}}
    Database: {{DB_NAME}}
    Username: {{DB_USER}}
    Password: {{DB_PASSWORD}}
    Charset: utf8mb4
    MaxIdleConns: 10
    MaxOpenConns: 100
    ConnMaxLifetime: 3600
    LogLevel: warn
    SlowThreshold: 200

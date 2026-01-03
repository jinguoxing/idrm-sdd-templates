Name: {{PROJECT_NAME}}-rpc
Host: 0.0.0.0
Port: 9999

# 日志配置
Log:
  ServiceName: {{PROJECT_NAME}}-rpc
  Mode: console
  Level: info

# 链路追踪
Telemetry:
  Name: {{PROJECT_NAME}}-rpc
  Endpoint: ""
  Sampler: 1.0
  Batcher: jaeger

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

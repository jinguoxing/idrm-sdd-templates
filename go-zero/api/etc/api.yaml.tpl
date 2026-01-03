Name: {{PROJECT_NAME}}-api
Host: 0.0.0.0
Port: 8888

# Telemetry 配置
Telemetry:
  ServiceName: {{PROJECT_NAME}}-api
  ServiceVersion: 1.0.0
  Environment: dev
  
  Log:
    Level: info
    Mode: file
    Path: logs
    KeepDays: 7
    RemoteEnabled: false
    RemoteUrl: http://log-collector:8080/api/logs
    RemoteBatch: 100
    RemoteTimeout: 5
    
  Trace:
    Enabled: false
    Endpoint: localhost:4317
    Sampler: 1.0
    Batcher: otlp
    
  Audit:
    Enabled: false
    Url: http://audit-service:8080/api/audit
    Buffer: 100

# 数据库配置
DB:
  Default:
    Host: {{DB_HOST}}
    Port: {{DB_PORT}}
    Database: {{DB_NAME}}
    Username: {{DB_USER}}
    Password: {{DB_PASSWORD}}
    Charset: utf8mb4
    # 连接池配置
    MaxIdleConns: 10
    MaxOpenConns: 100
    ConnMaxLifetime: 3600
    ConnMaxIdleTime: 600
    # 日志配置
    LogLevel: warn
    SlowThreshold: 200
    SkipDefaultTxn: true
    PrepareStmt: true
    SingularTable: true
    DisableForeignKey: true

# 认证配置
Auth:
  AccessSecret: {{ACCESS_SECRET}}
  AccessExpire: 7200

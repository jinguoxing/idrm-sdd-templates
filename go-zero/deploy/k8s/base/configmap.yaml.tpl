apiVersion: v1
kind: ConfigMap
metadata:
  name: {{PROJECT_NAME}}-config
  labels:
    app: {{PROJECT_NAME}}
data:
  api.yaml: |
    Name: {{PROJECT_NAME}}-api
    Host: 0.0.0.0
    Port: 8888

    Telemetry:
      ServiceName: {{PROJECT_NAME}}-api
      ServiceVersion: 1.0.0
      Environment: production
      
      Log:
        Level: info
        Mode: console
        KeepDays: 7

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

    Auth:
      AccessSecret: {{ACCESS_SECRET}}
      AccessExpire: 7200

apiVersion: v1
kind: Secret
metadata:
  name: {{PROJECT_NAME}}-secret
  labels:
    app: {{PROJECT_NAME}}
type: Opaque
stringData:
  # 数据库敏感信息
  DB_PASSWORD: "{{DB_PASSWORD}}"
  
  # 认证密钥
  ACCESS_SECRET: "{{ACCESS_SECRET}}"
  
  # Redis 密码 (如果使用)
  REDIS_PASSWORD: ""

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{PROJECT_NAME}}-config
  labels:
    app: {{PROJECT_NAME}}
data:
  # 非敏感环境变量配置
  ENVIRONMENT: "production"
  LOG_LEVEL: "info"
  LOG_MODE: "console"
  
  # 数据库配置 (非敏感)
  DB_HOST: "{{DB_HOST}}"
  DB_PORT: "{{DB_PORT}}"
  DB_NAME: "{{DB_NAME}}"
  DB_USER: "{{DB_USER}}"
  DB_MAX_IDLE_CONNS: "10"
  DB_MAX_OPEN_CONNS: "100"
  DB_LOG_LEVEL: "warn"
  
  # 服务端口
  API_PORT: "8888"
  RPC_PORT: "9999"
  
  # 认证配置 (非敏感)
  ACCESS_EXPIRE: "7200"

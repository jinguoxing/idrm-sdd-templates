Name: {{PROJECT_NAME}}-consumer
Mode: console

# 日志配置
Log:
  ServiceName: {{PROJECT_NAME}}-consumer
  Mode: console
  Level: info

# 链路追踪
Telemetry:
  Name: {{PROJECT_NAME}}-consumer
  Endpoint: ""
  Sampler: 1.0
  Batcher: jaeger

# 消息队列配置
MQ:
  # 类型：kafka, redis
  Type: kafka
  
  # Kafka 配置
  Kafka:
    Brokers:
      - ${KAFKA_BROKERS:localhost:9092}
    Topic: ${KAFKA_TOPIC:orders}
    Group: ${KAFKA_GROUP:consumer-group}

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

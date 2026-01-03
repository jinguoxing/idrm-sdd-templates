version: '3.8'

services:
  api:
    build:
      context: ../..
      dockerfile: deploy/docker/Dockerfile
    container_name: {{PROJECT_NAME}}-api
    ports:
      - "8888:8888"
    environment:
      - TZ=Asia/Shanghai
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
      - MYSQL_ROOT_PASSWORD={{DB_PASSWORD}}
      - MYSQL_DATABASE={{DB_NAME}}
      - TZ=Asia/Shanghai
    volumes:
      - mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    restart: unless-stopped
    networks:
      - {{PROJECT_NAME}}-network

networks:
  {{PROJECT_NAME}}-network:
    driver: bridge

volumes:
  mysql-data:

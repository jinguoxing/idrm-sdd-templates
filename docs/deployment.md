# 部署指南

> **Docker 和 Kubernetes 部署说明**

---

## 目录

- [Docker 部署](#docker-部署)
- [Kubernetes 部署](#kubernetes-部署)
- [环境变量配置](#环境变量配置)

---

## Docker 部署

### 文件结构

```
deploy/
├── docker/
│   ├── Dockerfile           # 多阶段构建
│   └── docker-compose.yaml  # 服务编排
└── k8s/                      # Kustomize 结构
    ├── base/                 # 基础配置
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   ├── secret.yaml
    │   ├── ingress.yaml
    │   ├── hpa.yaml
    │   ├── pdb.yaml
    │   └── kustomization.yaml
    └── overlays/             # 环境覆盖
        ├── dev/
        │   └── kustomization.yaml
        └── prod/
            └── kustomization.yaml
```

### 快速启动

```bash
# 构建镜像
make docker-build

# 运行容器
make docker-run
```

### Docker Compose 部署

```bash
cd deploy/docker

# 启动所有服务 (API + MySQL)
docker-compose up -d

# 查看日志
docker-compose logs -f api

# 停止服务
docker-compose down
```

### Dockerfile 说明

```dockerfile
# 构建阶段
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o server ./api/api.go

# 运行阶段
FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 8888
CMD ["./server"]
```

特点：
- 多阶段构建，最终镜像约 20MB
- Alpine 基础镜像
- 包含时区和 CA 证书

### 推送镜像

```bash
# 推送到 Docker Hub
make docker-push

# 推送到私有仓库
DOCKER_REGISTRY=my-registry.com make docker-push
```

---

## Kubernetes 部署

### 前置条件

- kubectl 已配置
- 集群中有足够资源
- 镜像已推送到可访问的仓库

### 快速部署

```bash
# 部署所有资源
make k8s-deploy

# 查看状态
make k8s-status

# 删除部署
make k8s-delete
```

### Kustomize 部署 (推荐)

```bash
# 部署开发环境
kubectl apply -k deploy/k8s/overlays/dev

# 部署生产环境
kubectl apply -k deploy/k8s/overlays/prod

# 预览生成的配置
kubectl kustomize deploy/k8s/overlays/dev
```

### 分步部署 (传统方式)

```bash
# 1. 创建 ConfigMap 和 Secret
kubectl apply -f deploy/k8s/base/configmap.yaml
kubectl apply -f deploy/k8s/base/secret.yaml

# 2. 创建 Deployment
kubectl apply -f deploy/k8s/base/deployment.yaml

# 3. 创建 Service 和 Ingress
kubectl apply -f deploy/k8s/base/service.yaml
kubectl apply -f deploy/k8s/base/ingress.yaml

# 4. (可选) 创建 HPA 和 PDB
kubectl apply -f deploy/k8s/base/hpa.yaml
kubectl apply -f deploy/k8s/base/pdb.yaml
```

### 资源配置说明

#### Deployment

```yaml
spec:
  replicas: 2                    # 副本数
  containers:
    - resources:
        requests:
          cpu: "100m"            # 请求 CPU
          memory: "128Mi"        # 请求内存
        limits:
          cpu: "500m"            # 限制 CPU
          memory: "512Mi"        # 限制内存
```

#### 健康检查

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8888
  initialDelaySeconds: 5
  periodSeconds: 10

livenessProbe:
  httpGet:
    path: /health
    port: 8888
  initialDelaySeconds: 15
  periodSeconds: 20
```

#### Service 类型

| 类型 | 端口 | 用途 |
|------|------|------|
| ClusterIP | 8888 | 集群内访问 |
| NodePort | 30888 | 节点端口访问 |

### HPA 自动扩缩容

```yaml
# deploy/k8s/base/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <project>-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <project>-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
```

### PDB 高可用保障

```yaml
# deploy/k8s/base/pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <project>-api-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: <project>-api
```

### 手动扩缩容

```bash
# 扩展到 3 副本
kubectl scale deployment <project>-api --replicas=3

# 查看 Pod
kubectl get pods -l app=<project>
```

---

## 环境变量配置

### 开发环境

通过 `api/etc/api.yaml` 直接配置。

### 生产环境

推荐使用环境变量覆盖：

| 变量 | 说明 | 示例 |
|------|------|------|
| `DB_HOST` | 数据库主机 | `mysql.prod.svc` |
| `DB_PORT` | 数据库端口 | `3306` |
| `DB_NAME` | 数据库名 | `idrm_prod` |
| `DB_USER` | 数据库用户 | `app_user` |
| `DB_PASSWORD` | 数据库密码 | `secret` |
| `ACCESS_SECRET` | JWT 密钥 | `random-secret-key` |

### K8s Secret 配置

```bash
# 创建 Secret
kubectl create secret generic db-secret \
  --from-literal=password=your-password

# 在 Deployment 中引用
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
```

---

## Makefile 命令速查

| 命令 | 说明 |
|------|------|
| `make docker-build` | 构建 Docker 镜像 |
| `make docker-run` | 运行 Docker 容器 |
| `make docker-stop` | 停止 Docker 容器 |
| `make docker-push` | 推送 Docker 镜像 |
| `make k8s-deploy` | 部署到 Kubernetes |
| `make k8s-delete` | 删除 Kubernetes 部署 |
| `make k8s-status` | 查看 Kubernetes 状态 |

---

## 故障排查

### Docker 容器无法启动

```bash
# 查看日志
docker logs <container-id>

# 进入容器调试
docker exec -it <container-id> sh
```

### K8s Pod 启动失败

```bash
# 查看 Pod 事件
kubectl describe pod <pod-name>

# 查看容器日志
kubectl logs <pod-name>
```

---

## 下一步

- [模板使用指南](templates-guide.md)
- [SDD 工作流程](workflow.md)

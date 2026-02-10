#!/bin/bash

# Docker 镜像构建脚本
# 用法: ./build.sh [tag] [service]
#   tag: 镜像标签 (默认: latest)
#   service: api, rpc, job, consumer, all (默认: all)

set -e

REGISTRY=${REGISTRY:-"{{DOCKER_REGISTRY}}"}
PROJECT=${PROJECT:-"{{PROJECT_NAME}}"}
TAG=${1:-"latest"}
SERVICE=${2:-"all"}

# 可用服务列表
AVAILABLE_SERVICES=("api" "rpc" "job" "consumer")

build_service() {
    local svc=$1
    local dockerfile="deploy/docker/Dockerfile.${svc}"
    
    if [ ! -f "$dockerfile" ]; then
        # 尝试查找 fallback 位置 (兼容旧结构)
        if [ -f "deploy/Dockerfile.${svc}" ]; then
            dockerfile="deploy/Dockerfile.${svc}"
        else
            # 静默跳过, 因为不是所有项目都有所有服务
            return
        fi
    fi
    
    local image="${REGISTRY}/${PROJECT}-${svc}:${TAG}"
    echo "🔨 构建 $image ..."
    docker build -f "$dockerfile" -t "$image" .
    echo "✅ 完成 $image"
    echo ""
}

echo "========================================"
echo "  Docker 镜像构建"
echo "========================================"
echo "Registry: $REGISTRY"
echo "Project:  $PROJECT"
echo "Tag:      $TAG"
echo "Service:  $SERVICE"
echo ""

if [ "$SERVICE" = "all" ]; then
    for svc in "${AVAILABLE_SERVICES[@]}"; do
        build_service "$svc"
    done
else
    build_service "$SERVICE"
fi

echo "========================================"
echo "  构建完成!"
echo "========================================"
echo ""
echo "推送镜像:"
if [ "$SERVICE" = "all" ]; then
    for svc in "${AVAILABLE_SERVICES[@]}"; do
        if [ -f "deploy/docker/Dockerfile.${svc}" ] || [ -f "deploy/Dockerfile.${svc}" ]; then
            echo "  docker push ${REGISTRY}/${PROJECT}-${svc}:${TAG}"
        fi
    done
else
    echo "  docker push ${REGISTRY}/${PROJECT}-${SERVICE}:${TAG}"
fi

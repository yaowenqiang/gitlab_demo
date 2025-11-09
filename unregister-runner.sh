#!/bin/bash

# GitLab Runner 注销脚本

echo "=== GitLab Runner 注销脚本 ==="

# 检查环境变量
if [ -z "$GITLAB_HOME" ]; then
    echo "错误: 请设置 GITLAB_HOME 环境变量"
    exit 1
fi

echo "注销所有 GitLab Runner..."

# 注销所有 Runner
docker exec gitlab-runner gitlab-runner unregister --all

echo "停止 GitLab Runner 容器..."
docker-compose stop gitlab-runner

echo "删除 GitLab Runner 容器..."
docker-compose rm -f gitlab-runner

echo "Runner 已成功注销"
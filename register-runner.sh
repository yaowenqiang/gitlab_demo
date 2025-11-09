#!/bin/bash

# GitLab Runner 注册脚本
# 使用前请确保 GitLab 实例已完全启动

echo "=== GitLab Runner 注册脚本 ==="

# 检查环境变量
if [ -z "$GITLAB_HOME" ]; then
    echo "错误: 请设置 GITLAB_HOME 环境变量"
    echo "例如: export GITLAB_HOME=/Users/yaojack/gitlab"
    exit 1
fi

# 创建 Runner 配置目录
RUNNER_CONFIG_DIR="$GITLAB_HOME/gitlab-runner/config"
mkdir -p "$RUNNER_CONFIG_DIR"

# GitLab 实例配置
GITLAB_URL="http://gitlab.example.com"
RUNNER_NAME="docker-runner"
RUNNER_TAGS="docker,linux,shared"
DEFAULT_DOCKER_IMAGE="docker:latest"

echo "GitLab URL: $GITLAB_URL"
echo "Runner 名称: $RUNNER_NAME"
echo "Runner 标签: $RUNNER_TAGS"
echo ""

# 提示用户输入注册令牌
echo "请按照以下步骤获取注册令牌："
echo "1. 访问 $GITLAB_URL"
echo "2. 以管理员身份登录"
echo "3. 进入 管理区域 → CI/CD → Runners"
echo "4. 复制右侧的注册令牌"
echo ""

read -p "请输入 GitLab Runner 注册令牌: " REGISTRATION_TOKEN

if [ -z "$REGISTRATION_TOKEN" ]; then
    echo "错误: 注册令牌不能为空"
    exit 1
fi

echo ""
echo "开始注册 GitLab Runner..."

# 等待 GitLab 完全启动
echo "等待 GitLab 完全启动..."
for i in {1..30}; do
    if curl -s -f "$GITLAB_URL/-/health" > /dev/null 2>&1; then
        echo "GitLab 已启动!"
        break
    fi
    echo "等待 GitLab 启动... ($i/30)"
    sleep 10
done

# 启动 GitLab Runner 容器
echo "启动 GitLab Runner 容器..."
docker-compose up -d gitlab-runner

# 等待 Runner 容器启动
sleep 5

# 注册 Runner
echo "注册 Runner..."
docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "$GITLAB_URL" \
    --registration-token "$REGISTRATION_TOKEN" \
    --executor "docker" \
    --docker-privileged \
    --docker-image "$DEFAULT_DOCKER_IMAGE" \
    --description "$RUNNER_NAME" \
    --tag-list "$RUNNER_TAGS" \
    --run-untagged="false" \
    --locked="false" \
    --access-level="not_protected"

echo ""
echo "=== 注册完成 ==="
echo "Runner 应该已在 GitLab 管理界面中显示"
echo "访问 $GITLAB_URL/admin/runners 查看状态"

# 显示 Runner 状态
echo ""
echo "=== Runner 状态 ==="
docker exec gitlab-runner gitlab-runner status

echo ""
echo "=== Runner 列表 ==="
docker exec gitlab-runner gitlab-runner list
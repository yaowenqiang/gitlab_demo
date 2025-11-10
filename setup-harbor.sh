#!/bin/bash

# Docker Registry 初始化脚本

echo "=== Docker Registry 私服初始化脚本 ==="

# 检查环境变量
if [ -z "$GITLAB_HOME" ]; then
    echo "错误: 请设置 GITLAB_HOME 环境变量"
    exit 1
fi

REGISTRY_PORT="5000"
REGISTRY_URL="localhost:$REGISTRY_PORT"
REGISTRY_UI_PORT="8080"
REGISTRY_UI_URL="http://localhost:$REGISTRY_UI_PORT"
REGISTRY_USER="gitlab"
REGISTRY_PASSWORD="registry123"

echo "Registry URL: $REGISTRY_URL"
echo "Web UI URL: $REGISTRY_UI_URL"
echo "用户账户: $REGISTRY_USER"
echo "默认密码: $REGISTRY_PASSWORD"

# 创建 Registry 配置目录
HARBOR_CONFIG_DIR="$GITLAB_HOME/harbor"
mkdir -p "$HARBOR_CONFIG_DIR"/{data,auth}

# 创建认证文件
echo "创建 Registry 认证..."
docker run --rm \
    -v "$HARBOR_CONFIG_DIR/auth:/auth" \
    httpd:2.4 \
    htpasswd -Bbn "$REGISTRY_USER" "$REGISTRY_PASSWORD" > "$HARBOR_CONFIG_DIR/auth/htpasswd"

# 启动 Registry
echo "启动 Registry 服务..."
docker-compose up -d harbor

# 等待 Registry 启动
echo "等待 Registry 服务启动..."
for i in {1..30}; do
    if curl -s -f "$REGISTRY_URL/v2/_catalog" > /dev/null 2>&1; then
        echo "Registry 服务已启动!"
        break
    fi
    echo "等待 Registry 启动... ($i/30)"
    sleep 2
done

# 测试 Registry 连接
echo "测试 Registry 连接..."
echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" -u "$REGISTRY_USER" --password-stdin

if [ $? -eq 0 ]; then
    echo "✅ Registry 认证成功!"
else
    echo "❌ Registry 认证失败"
    exit 1
fi

echo ""
echo "=== GitLab CI/CD 配置信息 ==="
echo "Registry URL: $REGISTRY_URL"
echo "Web UI URL: $REGISTRY_UI_URL"
echo "用户名: $REGISTRY_USER"
echo "密码: $REGISTRY_PASSWORD"
echo ""
echo "请在 GitLab 项目中添加以下 CI/CD 变量:"
echo "HARBOR_URL: $REGISTRY_URL"
echo "HARBOR_USERNAME: $REGISTRY_USER"
echo "HARBOR_PASSWORD: $REGISTRY_PASSWORD"

# 保存配置信息
cat > "$GITLAB_HOME/harbor/gitlab-ci-config.txt" << EOF
# Docker Registry GitLab CI/CD 配置
HARBOR_URL=$REGISTRY_URL
HARBOR_UI_URL=$REGISTRY_UI_URL
HARBOR_USERNAME=$REGISTRY_USER
HARBOR_PASSWORD=$REGISTRY_PASSWORD

# 完整镜像地址格式
# $REGISTRY_URL/your-app-name:tag

# Web 管理界面
# $REGISTRY_UI_URL
EOF

echo ""
echo "配置信息已保存到: $GITLAB_HOME/harbor/gitlab-ci-config.txt"

echo ""
echo "=== Registry 配置完成 ==="
echo "Registry 地址: $REGISTRY_URL"
echo "Web UI 地址: $REGISTRY_UI_URL"
echo "用户账户: $REGISTRY_USER"
echo "用户密码: $REGISTRY_PASSWORD"
echo ""
echo "可以使用以下命令测试:"
echo "docker pull hello-world"
echo "docker tag hello-world $REGISTRY_URL/hello-world:test"
echo "docker push $REGISTRY_URL/hello-world:test"
echo ""
echo "打开 Web 管理界面:"
echo "./harbor-manager.sh ui"
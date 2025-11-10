#!/bin/bash

# Docker Registry 管理脚本

REGISTRY_URL="localhost:5000"
REGISTRY_UI_URL="http://localhost:8080"
REGISTRY_USER="gitlab"
REGISTRY_PASSWORD="registry123"

case "$1" in
    "status")
        echo "=== Registry 服务状态 ==="
        docker-compose ps harbor
        ;;

    "logs")
        echo "=== Registry 日志 ==="
        docker-compose logs -f harbor
        ;;

    "login")
        echo "登录到 Registry..."
        echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" -u "$REGISTRY_USER" --password-stdin
        ;;

    "catalog")
        echo "=== Registry 镜像列表 ==="
        echo "可以使用以下命令查看本地已推送的镜像:"
        echo "docker images | grep '$REGISTRY_URL'"
        ;;

    "tags")
        if [ -z "$2" ]; then
            echo "用法: $0 tags <image_name>"
            exit 1
        fi
        echo "=== 镜像 '$2' 的标签列表 ==="
        echo "可以使用以下命令查看镜像标签:"
        echo "docker images '$REGISTRY_URL/$2'"
        ;;

    "stop")
        echo "停止 Registry..."
        docker-compose stop harbor
        ;;

    "start")
        echo "启动 Registry..."
        docker-compose start harbor
        ;;

    "restart")
        echo "重启 Registry..."
        docker-compose restart harbor
        ;;

    "info")
        echo "=== Registry 信息 ==="
        echo "Registry URL: $REGISTRY_URL"
        echo "Web UI URL: $REGISTRY_UI_URL"
        echo "用户名: $REGISTRY_USER"
        echo "密码: $REGISTRY_PASSWORD"
        echo ""
        echo "健康检查:"
        if docker ps | grep harbor > /dev/null 2>&1; then
            echo "✅ Registry 容器运行正常"
        else
            echo "❌ Registry 容器未运行"
        fi
        if docker ps | grep harbor-ui > /dev/null 2>&1; then
            echo "✅ Web UI 容器运行正常"
        else
            echo "❌ Web UI 容器未运行"
        fi
        ;;

    "test")
        echo "=== 测试 Registry 功能 ==="
        echo "拉取测试镜像..."
        docker pull hello-world:latest
        echo "标记镜像..."
        docker tag hello-world:latest "$REGISTRY_URL/hello-world:test-$(date +%s)"
        echo "推送镜像..."
        docker push "$REGISTRY_URL/hello-world:test-$(date +%s)"
        echo "✅ Registry 功能测试成功!"
        ;;

    "ui")
        echo "=== 打开 Web 管理界面 ==="
        echo "Web UI 地址: $REGISTRY_UI_URL"
        echo "如果浏览器没有自动打开，请手动访问上述地址"
        if command -v open > /dev/null 2>&1; then
            open "$REGISTRY_UI_URL"
        elif command -v xdg-open > /dev/null 2>&1; then
            xdg-open "$REGISTRY_UI_URL"
        else
            echo "请手动在浏览器中打开: $REGISTRY_UI_URL"
        fi
        ;;

    *)
        echo "Docker Registry 管理脚本"
        echo ""
        echo "用法: $0 {status|logs|login|catalog|tags|stop|start|restart|info|test|ui}"
        echo ""
        echo "命令说明:"
        echo "  status  - 查看 Registry 服务状态"
        echo "  logs    - 查看 Registry 日志"
        echo "  login   - 登录到 Registry"
        echo "  catalog - 列出所有镜像仓库"
        echo "  tags    - 列出指定镜像的标签 (需要提供镜像名)"
        echo "  stop    - 停止 Registry"
        echo "  start   - 启动 Registry"
        echo "  restart - 重启 Registry"
        echo "  info    - 显示 Registry 基本信息"
        echo "  test    - 测试 Registry 推送/拉取功能"
        echo "  ui      - 打开 Web 管理界面"
        echo ""
        echo "示例:"
        echo "  $0 status"
        echo "  $0 catalog"
        echo "  $0 test"
        echo "  $0 ui"
        echo "  $0 login"
        exit 1
        ;;
esac
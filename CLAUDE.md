# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 概述

此仓库包含一个使用 Docker Compose 运行的 GitLab 社区版实例。这不是一个开发代码库，而是运行 GitLab 服务的部署配置。

## 架构

- **GitLab CE 13.2.8**: 容器化的 GitLab 社区版实例
- **Docker Compose**: 使用 `docker-compose.yml` 的单服务部署
- **卷挂载**: 配置、日志和数据的持久化存储
- **端口映射**: HTTP (80), HTTPS (443), SSH (2223→22)

## 关键文件

- `docker-compose.yml`: GitLab 和 GitLab Runner 容器的主要服务配置
- `config/gitlab.rb`: GitLab Omnibus 配置文件（安装时生成）
- `gitlab-runner/config/`: GitLab Runner 配置文件目录
- `register-runner.sh`: GitLab Runner 注册脚本
- `unregister-runner.sh`: GitLab Runner 注销脚本
- `NOTES.md`: 包含 Git 克隆命令和 SSL 验证设置

## 常用命令

### 启动所有服务（包括 Runner）
```bash
docker-compose up -d
```

### 仅启动 GitLab
```bash
docker-compose up -d gitlab
```

### 停止所有服务
```bash
docker-compose down
```

### 查看日志
```bash
# 查看 GitLab 日志
docker-compose logs -f gitlab

# 查看 Runner 日志
docker-compose logs -f gitlab-runner
```

### 访问 GitLab 配置
```bash
docker exec -it gitlab /bin/bash
```

### 重新配置 GitLab
```bash
docker exec -it gitlab gitlab-ctl reconfigure
```

### GitLab Runner 管理
```bash
# 注册 Runner（使用提供的脚本）
./register-runner.sh

# 注销 Runner
./unregister-runner.sh

# 查看 Runner 状态
docker exec gitlab-runner gitlab-runner status

# 列出所有 Runner
docker exec gitlab-runner gitlab-runner list

# 手动注册 Runner
docker exec -it gitlab-runner gitlab-runner register
```

## 配置信息

- **外部 URL**: `https://gitlab.example.com`
- **主机名**: `gitlab.example.com`
- **数据目录**: `$GITLAB_HOME/data` (映射到 `/var/opt/gitlab`)
- **配置目录**: `$GITLAB_HOME/config` (映射到 `/etc/gitlab`)
- **日志目录**: `$GITLAB_HOME/logs` (映射到 `/var/log/gitlab`)

## GitLab Runner 配置

- **Runner 执行器**: Docker 执行器，支持容器化 CI/CD
- **Runner 标签**: `docker,linux,shared`
- **默认镜像**: `docker:latest`
- **配置目录**: `$GITLAB_HOME/gitlab-runner/config`
- **网络**: 与 GitLab 容器共享 `gitlab-network` 网络

### Runner 注册流程

1. 确保 GitLab 完全启动（约 5-10 分钟）
2. 运行 `./register-runner.sh` 脚本
3. 按提示输入从 GitLab 管理界面获取的注册令牌
4. 脚本会自动配置并注册 Runner

## 重要说明

- 运行 Docker Compose 前必须设置 `GITLAB_HOME` 环境变量
- 提供的笔记中禁用了 SSL 验证：`git config --global http.sslVerify false`
- 此设置使用特定版本 (13.2.8-ce.0) 的 GitLab 社区版
- 初始设置可能需要几分钟才能完成
- GitLab Runner 容器需要访问主机的 Docker socket (`/var/run/docker.sock`)
- Runner 和 GitLab 容器在同一个 Docker 网络中，可以使用容器名直接通信
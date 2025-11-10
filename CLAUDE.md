# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 概述

此仓库包含一个使用 Docker Compose 运行的 GitLab 社区版实例。这不是一个开发代码库，而是运行 GitLab 服务的部署配置。

## 架构

- **GitLab CE 13.2.8**: 容器化的 GitLab 社区版实例
- **Harbor v2.8.0**: 容器化的 Docker 镜像私服
- **GitLab Runner**: CI/CD 流水线执行器
- **Docker Compose**: 使用 `docker-compose.yml` 的多服务部署
- **卷挂载**: 配置、日志和数据的持久化存储
- **端口映射**:
  - GitLab HTTP (80), HTTPS (443), SSH (2223→22)
  - Harbor HTTP (8080), HTTPS (8443)

## 关键文件

- `docker-compose.yml`: GitLab、GitLab Runner 和 Harbor 容器的主要服务配置
- `config/gitlab.rb`: GitLab Omnibus 配置文件（安装时生成）
- `harbor/harbor.yml`: Harbor 私服配置文件
- `gitlab-runner/config/`: GitLab Runner 配置文件目录
- `register-runner.sh`: GitLab Runner 注册脚本
- `unregister-runner.sh`: GitLab Runner 注销脚本
- `setup-harbor.sh`: Harbor 私服初始化脚本
- `harbor-manager.sh`: Harbor 管理工具脚本
- `.gitlab-ci.yml.example`: GitLab CI/CD 流水线示例配置
- `Dockerfile.example`: Docker 镜像构建示例文件
- `NOTES.md`: 包含 Git 克隆命令和 SSL 验证设置

## 常用命令

### 启动所有服务
```bash
docker-compose up -d
```

### 启动特定服务
```bash
# 仅启动 GitLab
docker-compose up -d gitlab

# 仅启动 Harbor
docker-compose up -d harbor

# 仅启动 GitLab Runner
docker-compose up -d gitlab-runner
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

# 查看 Harbor 日志
docker-compose logs -f harbor
```

### Harbor 管理
```bash
# 初始化 Harbor（首次运行）
./setup-harbor.sh

# Harbor 管理工具
./harbor-manager.sh status
./harbor-manager.sh logs
./harbor-manager.sh projects
./harbor-manager.sh login

# 访问 Harbor 管理界面
# http://localhost:8080 (admin/Harbor12345)
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

## Harbor 私服配置

- **访问地址**: `http://localhost:8080`
- **管理员账户**: `admin`
- **管理员密码**: `Harbor12345`
- **数据目录**: `$GITLAB_HOME/harbor/data`
- **配置文件**: `harbor/harbor.yml`

### Harbor 初始化流程

1. 启动所有服务：`docker-compose up -d`
2. 运行初始化脚本：`./setup-harbor.sh`
3. 脚本会自动创建项目和机器人账户
4. 获取 CI/CD 配置信息并添加到 GitLab 项目

### GitLab CI/CD 集成

1. 在 GitLab 项目中添加 CI/CD 变量：
   - `HARBOR_URL`: Harbor 服务地址
   - `HARBOR_PROJECT`: Harbor 项目名称
   - `HARBOR_USERNAME`: 机器人用户名
   - `HARBOR_PASSWORD`: 机器人令牌

2. 将 `.gitlab-ci.yml.example` 复制为 `.gitlab-ci.yml`
3. 根据项目需求修改 CI/CD 配置
4. 创建 `Dockerfile`（参考 `Dockerfile.example`）

### 镜像地址格式

```
http://localhost:8080/gitlab-ci/your-app-name:tag
```

## 重要说明

- 运行 Docker Compose 前必须设置 `GITLAB_HOME` 环境变量
- 提供的笔记中禁用了 SSL 验证：`git config --global http.sslVerify false`
- 此设置使用特定版本 (13.2.8-ce.0) 的 GitLab 社区版
- 初始设置可能需要几分钟才能完成
- GitLab Runner 容器需要访问主机的 Docker socket (`/var/run/docker.sock`)
- 所有容器在同一个 Docker 网络中，可以使用容器名直接通信
- Harbor 默认端口为 8080，避免与 GitLab 的 80 端口冲突